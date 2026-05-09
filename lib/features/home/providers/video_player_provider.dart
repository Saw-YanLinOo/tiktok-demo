import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_preload_service.dart';
import 'feed_provider.dart';

/// TikTok-style ±2 preload window — 5 controllers max in memory at once:
///
///   N-2  chunk cached, controller alive   (instant back-scroll)
///   N-1  chunk cached, controller alive   (instant back-scroll)
///   N    PLAYING
///   N+1  fully initialised, paused        (zero-wait forward swipe)
///   N+2  metadata + chunk downloading     (ready before user arrives)
///
/// Two-phase preload per slot:
///   Phase 1 – HEAD request  → file size, content-type (≈ 0 bytes, warms DNS)
///   Phase 2 – Range request → first 3 MB ≈ first 3-5 s of video
///
/// Only the first chunk is stored — never the full file — keeping disk light.
class FeedControllerNotifier
    extends StateNotifier<Map<int, CachedVideoPlayerPlusController>> {
  FeedControllerNotifier(this._ref) : super({}) {
    // Eagerly warm up indices 0, 1, 2 before the user sees the first frame.
    _initRange(0);
  }

  final Ref _ref;
  final Set<int> _loading = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> onPageChanged(int index) async {
    _disposeOutOfRange(index);
    await _initRange(index);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _initRange(int center) async {
    final videos = _ref.read(feedProvider);

    final window = [
      center - 2,
      center - 1,
      center,
      center + 1,
      center + 2,
    ].where((i) => i >= 0 && i < videos.length).toList();

    // Phase 1 — fire HEAD requests for every slot in the window concurrently.
    // These are essentially free (no body download) and warm DNS + TCP.
    for (final i in window) {
      unawaited(VideoPreloadService.fetchMetadata(videos[i].videoUrl));
    }

    // Phase 2 — fetch first chunk + initialise controllers concurrently.
    await Future.wait(window.map(_initController));
  }

  Future<void> _initController(int index) async {
    if (state.containsKey(index) || _loading.contains(index)) return;
    _loading.add(index);

    try {
      final url = _ref.read(feedProvider)[index].videoUrl;

      // Phase 2: download only the first 3 MB (≈ first 3-5 s) via Range request.
      // Runs in a background Isolate — main thread never blocked.
      // For faststart MP4s (moov atom at front) → immediately playable.
      // Returns null if the server doesn't support ranges or download fails.
      final chunkFile = await VideoPreloadService.fetchFirstChunk(url);

      final controller = chunkFile != null
          // Chunk on disk → zero network latency on first play
          ? CachedVideoPlayerPlusController.file(chunkFile)
          // Fallback → stream directly; package caches progressively
          : CachedVideoPlayerPlusController.networkUrl(Uri.parse(url));

      await controller.initialize();
      controller.setLooping(true);

      if (mounted) state = {...state, index: controller};
    } catch (_) {
      // Silent fail — VideoCard shows TikTok loader, no crash.
    } finally {
      _loading.remove(index);
    }
  }

  void _disposeOutOfRange(int center) {
    final toRemove =
        state.keys.where((i) => (i - center).abs() > 2).toList();
    if (toRemove.isEmpty) return;

    final updated =
        Map<int, CachedVideoPlayerPlusController>.from(state);
    for (final i in toRemove) {
      updated.remove(i)?.dispose();
    }
    state = updated;
  }

  @override
  void dispose() {
    for (final c in state.values) {
      c.dispose();
    }
    super.dispose();
  }
}

final feedControllerProvider = StateNotifierProvider<FeedControllerNotifier,
    Map<int, CachedVideoPlayerPlusController>>(
  (ref) => FeedControllerNotifier(ref),
);
