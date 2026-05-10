import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Isolate entry-point — full-file HTTP download.
//
// Top-level function (not a closure) so Isolate.run() can transfer it.
// Uses ONLY dart:io — zero Flutter plugin calls — safe in a background isolate.
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> _downloadFull((String url, String filePath) args) async {
  final (url, filePath) = args;
  final file = File(filePath);
  if (await file.exists()) return true; // disk hit

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..idleTimeout = const Duration(seconds: 30);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
    final response =
        await request.close().timeout(const Duration(minutes: 3));

    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.partialContent) {
      return false;
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    await file.writeAsBytes(builder.takeBytes(), flush: true);
    return true;
  } catch (_) {
    if (await file.exists()) await file.delete();
    return false;
  } finally {
    client.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoDownloadService
//
// Downloads full video files into the temp directory via a background Isolate
// so the main thread is never blocked.
//
// Cache (max 10 entries, insertion-order LRU):
//   1. Memory map  — instant lookup within session
//   2. Disk file   — survives back-scrolls / session restarts
//   3. Isolate download → disk → memory
//
// Duplicate-request protection: concurrent calls for the same URL share
// a single Completer so only one Isolate is ever spawned per URL.
// ─────────────────────────────────────────────────────────────────────────────
class VideoDownloadService {
  VideoDownloadService._();

  /// Maximum number of video files kept in the LRU memory index.
  static const int maxCached = 10;

  // Insertion-ordered map — first key = oldest entry (evicted first).
  static final Map<String, File> _cache = {};
  static final Map<String, Completer<File?>> _inflight = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the cached [File] for [url] synchronously, or `null`.
  /// Safe to call from widget build or provider constructors.
  static File? getCached(String url) => _cache[url];

  /// Downloads the full video for [url] to the temp directory.
  ///
  /// Returns a [File] ready for
  /// `CachedVideoPlayerPlusController.file()`, or `null` on failure
  /// (caller should fall back to `.networkUrl()`).
  static Future<File?> download(String url) async {
    // Memory hit
    if (_cache.containsKey(url)) return _cache[url];

    // Dedup: join existing in-flight request instead of spawning a new one
    if (_inflight.containsKey(url)) return _inflight[url]!.future;

    final completer = Completer<File?>();
    _inflight[url] = completer;

    try {
      // path_provider must be called on the main thread
      final dir = await getTemporaryDirectory();
      final hash = md5.convert(utf8.encode(url)).toString();
      final path = '${dir.path}/$hash.mp4';

      // Disk hit (file from a previous session)
      if (await File(path).exists()) {
        final file = File(path);
        _addToCache(url, file);
        completer.complete(file);
        return file;
      }

      // Background isolate download — does not block the main thread
      final ok = await Isolate.run(() => _downloadFull((url, path)));

      if (ok) {
        final file = File(path);
        _addToCache(url, file);
        completer.complete(file);
        return file;
      }

      completer.complete(null);
      return null;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _inflight.remove(url);
    }
  }

  /// Drops the in-memory index.
  /// Disk files are preserved and will be re-indexed on the next [download].
  static void clear() {
    _cache.clear();
    _inflight.clear();
  }

  static int get cachedCount => _cache.length;

  // ── Private ────────────────────────────────────────────────────────────────

  static void _addToCache(String url, File file) {
    _cache.remove(url); // re-insert at tail (marks as most-recently-used)
    _cache[url] = file;
    // Evict oldest entries when over limit
    while (_cache.length > maxCached) {
      _cache.remove(_cache.keys.first);
    }
  }
}
