import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_cache_service.dart';
import 'feed_provider.dart';

/// TikTok-style ±2 preload window — 5 controllers max in memory at once:
///
///   N-2  cached on disk, controller alive  (instant back-scroll)
///   N-1  cached on disk, controller alive  (instant back-scroll)
///   N    PLAYING
///   N+1  fully initialized, paused         (zero-wait forward swipe)
///   N+2  downloading + initializing        (ready before user arrives)
///
/// Each controller is a [CachedVideoPlayerPlusController]:
///   • If [VideoCacheService] already has the file on disk → .file() — instant
///   • Otherwise → .networkUrl() fallback — streams while caching in background
///
/// The file download runs in a background [Isolate] (pure dart:io) so the
/// main thread is never blocked by network I/O or byte-level file writes.
class FeedControllerNotifier
    extends StateNotifier<Map<int, CachedVideoPlayerPlusController>> {
  FeedControllerNotifier(this._ref) : super({}) {
    // Eagerly warm up indices 0, 1, 2 before the user sees anything.
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
    final indices = [
      center - 2,
      center - 1,
      center,
      center + 1,
      center + 2,
    ].where((i) => i >= 0 && i < videos.length);

    // Initialise all slots concurrently — N+1 and N+2 warm up while user
    // is still watching N.
    await Future.wait(indices.map(_initController));
  }

  Future<void> _initController(int index) async {
    if (state.containsKey(index) || _loading.contains(index)) return;
    _loading.add(index);

    try {
      final url = _ref.read(feedProvider)[index].videoUrl;

      // VideoCacheService runs the download in a background Isolate.
      // If the file is already on disk the Isolate returns immediately.
      final cachedFile = await VideoCacheService.fetch(url);

      final controller = cachedFile != null
          // Cached file path → zero network latency on play
          ? CachedVideoPlayerPlusController.file(cachedFile)
          // Fallback: stream directly, package caches for next time
          : CachedVideoPlayerPlusController.networkUrl(Uri.parse(url));

      await controller.initialize();
      controller.setLooping(true);

      if (mounted) state = {...state, index: controller};
    } catch (_) {
      // Silent fail — VideoCard shows a plain black frame, no crash.
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
