import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Isolate entry-point: HTTP Range download (bytes=start–end)
//
// Must be top-level — Isolate.run() cannot capture closure state.
// Pure dart:io — no Flutter plugin calls — safe inside a background isolate.
// ─────────────────────────────────────────────────────────────────────────────
Future<bool> _downloadRange(
  (String url, String filePath, int start, int end) args,
) async {
  final (url, filePath, start, end) = args;
  final file = File(filePath);
  if (await file.exists()) return true; // disk hit

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers
      ..set(HttpHeaders.rangeHeader, 'bytes=$start-$end')
      ..set(HttpHeaders.connectionHeader, 'keep-alive');
    final response = await request.close();

    // 206 Partial Content (range respected) or 200 OK (server ignored range)
    if (response.statusCode != HttpStatus.partialContent &&
        response.statusCode != HttpStatus.ok) {
      return false;
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    await file.writeAsBytes(builder.takeBytes(), flush: true);
    return true;
  } catch (_) {
    if (await file.exists()) await file.delete(); // clean partial write
    return false;
  } finally {
    client.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoMetadata — result of Phase 1 (HEAD request)
// ─────────────────────────────────────────────────────────────────────────────
class VideoMetadata {
  const VideoMetadata({
    required this.url,
    required this.fileSize,
    required this.contentType,
  });

  /// Total file size in bytes (from Content-Length header).
  final int fileSize;

  /// MIME type string, e.g. "video/mp4" (from Content-Type header).
  final String contentType;

  /// Rough duration estimate based on a 1.5 Mbps mobile bitrate.
  /// Replaced by the real value once the player controller initialises.
  final String url;

  Duration get estimatedDuration =>
      Duration(seconds: (fileSize / (1.5 * 1024 * 1024 / 8)).round());

  @override
  String toString() =>
      'VideoMetadata(size: ${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB, '
      'type: $contentType, ~${estimatedDuration.inSeconds} s)';
}

// ─────────────────────────────────────────────────────────────────────────────
// VideoPreloadService
//
// Two-phase strategy — keeps storage light by never caching whole files:
//
//   Phase 1 – Metadata   HEAD request → file size, content-type, estimated
//                        duration. Warms DNS + TCP as a side-effect.
//                        Weight: ~0 bytes downloaded.
//
//   Phase 2 – First chunk  Range: bytes=0-{N} → first 3 MB ≈ 3-5 s of
//                        720p mobile video at 1.5 Mbps. Runs in a background
//                        Isolate so the main thread is never blocked.
//                        Works best with faststart (web-optimised) MP4s where
//                        the moov atom lives at the start of the file.
//                        Falls back to networkUrl streaming for other formats.
// ─────────────────────────────────────────────────────────────────────────────
class VideoPreloadService {
  VideoPreloadService._();

  /// Size of the initial range request.
  /// 3 MB ≈ first 3-5 s at 1.5 Mbps for a typical 720 p short video.
  static const int _firstChunkBytes = 3 * 1024 * 1024;

  // ── In-memory caches ──────────────────────────────────────────────────────
  static final Map<String, VideoMetadata> _metaCache = {};
  static final Map<String, File> _chunkCache = {};

  // ── In-flight dedup (Completer per URL) ───────────────────────────────────
  static final Map<String, Completer<VideoMetadata?>> _metaInflight = {};
  static final Map<String, Completer<File?>> _chunkInflight = {};

  // ── Phase 1 ───────────────────────────────────────────────────────────────

  /// Fires an HTTP HEAD request for [url].
  /// Returns [VideoMetadata] with file size and content-type.
  /// Returns `null` on network failure — callers should handle gracefully.
  static Future<VideoMetadata?> fetchMetadata(String url) async {
    if (_metaCache.containsKey(url)) return _metaCache[url];
    if (_metaInflight.containsKey(url)) return _metaInflight[url]!.future;

    final completer = Completer<VideoMetadata?>();
    _metaInflight[url] = completer;

    try {
      final client = HttpClient();
      try {
        final request = await client.headUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
        final response = await request.close();
        await response.drain<void>(); // HEAD has no body

        final length = response.contentLength;
        if (length <= 0) {
          completer.complete(null);
          return null;
        }

        final meta = VideoMetadata(
          url: url,
          fileSize: length,
          contentType:
              response.headers.value(HttpHeaders.contentTypeHeader) ??
              'video/mp4',
        );
        _metaCache[url] = meta;
        completer.complete(meta);
        return meta;
      } finally {
        client.close();
      }
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _metaInflight.remove(url);
    }
  }

  // ── Phase 2 ───────────────────────────────────────────────────────────────

  /// Downloads the first [_firstChunkBytes] bytes of [url] via an HTTP Range
  /// request running in a background [Isolate].
  ///
  /// Returns a [File] suitable for
  /// [CachedVideoPlayerPlusController.file()], or `null` on failure
  /// (caller should fall back to `.networkUrl()`).
  static Future<File?> fetchFirstChunk(String url) async {
    if (_chunkCache.containsKey(url)) return _chunkCache[url];
    if (_chunkInflight.containsKey(url)) return _chunkInflight[url]!.future;

    final completer = Completer<File?>();
    _chunkInflight[url] = completer;

    try {
      // path_provider must run on the main thread
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/${url.hashCode}_chunk.mp4';
      final existing = File(path);

      // Disk hit — chunk already downloaded in a previous session / scroll
      if (await existing.exists()) {
        _chunkCache[url] = existing;
        completer.complete(existing);
        return existing;
      }

      // Clamp the range end to the actual file size when metadata is known
      final meta = await fetchMetadata(url);
      final end = meta != null
          ? min(_firstChunkBytes, meta.fileSize) - 1
          : _firstChunkBytes - 1;

      // Background isolate — pure dart:io, no platform channels
      final ok =
          await Isolate.run(() => _downloadRange((url, path, 0, end)));

      if (ok) {
        final file = File(path);
        _chunkCache[url] = file;
        completer.complete(file);
        return file;
      }

      completer.complete(null);
      return null;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _chunkInflight.remove(url);
    }
  }

  // ── Housekeeping ──────────────────────────────────────────────────────────

  /// Drop in-memory indices on a low-memory warning.
  /// Disk chunk files are preserved and re-indexed on the next [fetchFirstChunk].
  static void clearMemory() {
    _metaCache.clear();
    _chunkCache.clear();
  }
}
