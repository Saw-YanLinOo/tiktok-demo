import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VideoDownloadService
//
// Downloads full video files to the temp directory using Dio so we can
// track real-time byte progress and expose it via ValueNotifier<double>.
//
// Cache (max 10 entries, insertion-order LRU):
//   1. Memory map  — instant lookup within session
//   2. Disk file   — survives back-scrolls / session restarts
//   3. Dio download → disk → memory  (progress 0.0 → 1.0)
//
// Duplicate-request protection: concurrent calls for the same URL share
// a single Completer so only one download ever runs per URL.
// ─────────────────────────────────────────────────────────────────────────────
class VideoDownloadService {
  VideoDownloadService._();

  /// Maximum number of video files kept in the LRU memory index.
  static const int maxCached = 10;

  // Insertion-ordered map — first key = oldest entry (evicted first).
  static final Map<String, File> _cache = {};
  static final Map<String, Completer<File?>> _inflight = {};

  // Per-URL download progress: 0.0 (not started) → 1.0 (complete).
  static final Map<String, ValueNotifier<double>> _progress = {};

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 3),
    ),
  );

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns (or creates) a [ValueNotifier<double>] for [url].
  /// The value goes from 0.0 to 1.0 as bytes arrive.
  /// Listen to this in the loading UI to show real-time progress.
  static ValueNotifier<double> progressOf(String url) =>
      _progress.putIfAbsent(url, () => ValueNotifier(0.0));

  /// Returns the cached [File] for [url] synchronously, or `null`.
  static File? getCached(String url) => _cache[url];

  /// Downloads the full video for [url] to the temp directory.
  ///
  /// Returns a [File] ready for
  /// `CachedVideoPlayerPlusController.file()`, or `null` on failure
  /// (caller should fall back to `.networkUrl()`).
  static Future<File?> download(String url) async {
    // Memory hit — already downloaded this session
    if (_cache.containsKey(url)) {
      progressOf(url).value = 1.0;
      return _cache[url];
    }

    // Dedup — join the existing in-flight request
    if (_inflight.containsKey(url)) return _inflight[url]!.future;

    final completer = Completer<File?>();
    _inflight[url] = completer;

    try {
      final dir = await getTemporaryDirectory();
      final hash = md5.convert(utf8.encode(url)).toString();
      final path = '${dir.path}/$hash.mp4';

      // Disk hit — file exists from a previous session
      if (await File(path).exists()) {
        final file = File(path);
        _addToCache(url, file);
        progressOf(url).value = 1.0;
        completer.complete(file);
        return file;
      }

      // Download with real-time progress updates
      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total > 0) progressOf(url).value = received / total;
        },
        options: Options(headers: {'Connection': 'keep-alive'}),
      );

      progressOf(url).value = 1.0;
      final file = File(path);
      _addToCache(url, file);
      completer.complete(file);
      return file;
    } on DioException {
      // Delete any partial file so the next attempt starts clean
      try {
        final dir = await getTemporaryDirectory();
        final hash = md5.convert(utf8.encode(url)).toString();
        final partial = File('${dir.path}/$hash.mp4');
        if (await partial.exists()) await partial.delete();
      } catch (_) {}
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
  /// Disk files are preserved and re-indexed on the next [download] call.
  /// Progress notifiers are left alive — widgets may still be listening.
  static void clear() {
    _cache.clear();
    _inflight.clear();
  }

  static int get cachedCount => _cache.length;

  // ── Private ────────────────────────────────────────────────────────────────

  static void _addToCache(String url, File file) {
    _cache.remove(url); // re-insert at tail = most-recently-used
    _cache[url] = file;
    while (_cache.length > maxCached) {
      _cache.remove(_cache.keys.first);
    }
  }
}
