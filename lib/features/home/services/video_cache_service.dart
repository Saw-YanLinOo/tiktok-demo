import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level isolate entry-point
//
// Must be top-level (not a method) so Isolate.run() can spawn it cleanly.
// Uses only dart:io — zero Flutter plugin calls — safe in a background isolate.
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> _downloadToFile((String url, String filePath) args) async {
  final (url, filePath) = args;
  final file = File(filePath);

  // Disk cache hit — no re-download needed
  if (await file.exists()) return true;

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return false;

    // Collect chunks without copying until the final call
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }

    await file.writeAsBytes(builder.takeBytes(), flush: true);
    return true;
  } catch (_) {
    // Delete partial file so the next attempt starts clean
    if (await file.exists()) await file.delete();
    return false;
  } finally {
    client.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoCacheService
// ─────────────────────────────────────────────────────────────────────────────

/// Downloads video files to the device's temp directory using a background
/// [Isolate], so the main thread (and therefore the UI) is never blocked by
/// network I/O or byte-level file writes.
///
/// Layered cache:
///   1. Memory map  — instant (same session)
///   2. Disk file   — fast read (survives back-scrolls within the session)
///   3. Isolate download → disk → memory
///
/// Duplicate-request protection: concurrent calls for the same URL share
/// a single [Completer] so we never spawn two isolates for the same file.
class VideoCacheService {
  VideoCacheService._();

  static final Map<String, File> _memCache = {};
  static final Map<String, Completer<File?>> _inFlight = {};

  /// Returns a [File] for [url] ready to be passed to
  /// [CachedVideoPlayerPlusController.file()].
  /// Returns `null` if download fails — caller falls back to `.networkUrl()`.
  static Future<File?> fetch(String url) async {
    // 1. Memory hit
    if (_memCache.containsKey(url)) return _memCache[url];

    // 2. Already in-flight — join, don't duplicate
    if (_inFlight.containsKey(url)) return _inFlight[url]!.future;

    final completer = Completer<File?>();
    _inFlight[url] = completer;

    try {
      // Get temp path on main thread (path_provider needs platform channel)
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${url.hashCode}.mp4';

      // 3. Disk hit — file already there from a previous scroll
      final existing = File(filePath);
      if (await existing.exists()) {
        _memCache[url] = existing;
        completer.complete(existing);
        return existing;
      }

      // 4. Spawn background isolate — pure dart:io, no Flutter plugins
      final success = await Isolate.run(
        () => _downloadToFile((url, filePath)),
      );

      if (success) {
        final file = File(filePath);
        _memCache[url] = file;
        completer.complete(file);
        return file;
      }

      completer.complete(null);
      return null;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _inFlight.remove(url);
    }
  }

  /// Drop in-memory index on low-memory warning.
  /// Disk files are preserved and will be re-indexed on next [fetch].
  static void clearMemory() => _memCache.clear();
}
