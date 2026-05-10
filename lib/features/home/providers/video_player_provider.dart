import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_download_service.dart';
import 'feed_provider.dart';

/// ±2 sliding window controller manager.
///
/// For each slot:
///   • Fast-path — file already in [VideoDownloadService] cache (splash
///                 pre-downloaded it) → file controller, zero network traffic.
///   • Slow-path — not cached → networkUrl controller starts immediately so
///                 the video plays from the network right away, then swaps
///                 silently to the local file once the download completes.
///
/// Background downloads for N+1…N+3 are fire-and-forgotten so files are
/// ready before the user swipes to them.
class FeedControllerNotifier
    extends StateNotifier<Map<int, CachedVideoPlayerPlusController>> {
  FeedControllerNotifier(this._ref) : super({}) {
    _initWindow(0);
  }

  final Ref _ref;
  final Set<int> _initializing = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> onPageChanged(int index) async {
    _checkPagination(index);
    _disposeOutOfRange(index);
    _initWindow(index);
    _backgroundDownload(index);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Initialises the center slot first (visible video must be live first),
  /// then the surrounding ±2 slots concurrently.
  Future<void> _initWindow(int center) async {
    final videos = _ref.read(feedProvider);
    if (videos.isEmpty) return;

    await _initController(center);

    final surrounding = [center - 2, center - 1, center + 1, center + 2]
        .where((i) => i >= 0 && i < videos.length)
        .toList();
    await Future.wait(surrounding.map(_initController), eagerError: false);
  }

  Future<void> _initController(int index) async {
    if (state.containsKey(index) || _initializing.contains(index)) return;
    _initializing.add(index);

    try {
      final videos = _ref.read(feedProvider);
      if (index >= videos.length) return;
      final url = videos[index].videoUrl;

      // ── Fast-path: file already downloaded (splash pre-loaded it) ─────────
      final cached = VideoDownloadService.getCached(url);
      if (cached != null && await cached.exists()) {
        final ctrl = CachedVideoPlayerPlusController.file(cached);
        await ctrl.initialize();
        ctrl.setLooping(true);
        if (mounted) {
          state = {...state, index: ctrl};
        } else {
          ctrl.dispose();
        }
        return;
      }

      // ── Slow-path: stream from network, swap to file when ready ───────────
      final networkCtrl =
          CachedVideoPlayerPlusController.networkUrl(Uri.parse(url));
      await networkCtrl.initialize();
      networkCtrl.setLooping(true);

      if (!mounted) {
        networkCtrl.dispose();
        return;
      }
      state = {...state, index: networkCtrl};

      // Download full file in background (non-blocking), then swap.
      final file = await VideoDownloadService.download(url);
      if (file == null || !mounted || !state.containsKey(index)) return;

      final oldCtrl = state[index];
      final wasPlaying = oldCtrl?.value.isPlaying ?? false;

      final fileCtrl = CachedVideoPlayerPlusController.file(file);
      await fileCtrl.initialize();
      fileCtrl.setLooping(true);
      if (wasPlaying) fileCtrl.play();

      if (mounted && state.containsKey(index)) {
        final updated =
            Map<int, CachedVideoPlayerPlusController>.from(state);
        updated[index] = fileCtrl;
        state = updated;
        oldCtrl?.dispose();
      } else {
        fileCtrl.dispose();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[FeedController] Error idx=$index: $e');
    } finally {
      _initializing.remove(index);
    }
  }

  /// Fire-and-forget downloads for upcoming slots so files land before
  /// the user swipes to them.
  void _backgroundDownload(int center) {
    final videos = _ref.read(feedProvider);
    for (int delta = 1; delta <= 3; delta++) {
      final i = center + delta;
      if (i < videos.length) {
        VideoDownloadService.download(videos[i].videoUrl);
      }
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

  void _checkPagination(int index) {
    final videos = _ref.read(feedProvider);
    if (index >= videos.length - 3) {
      _ref.read(feedProvider.notifier).fetchNextPage();
    }
  }

  @override
  void dispose() {
    VideoDownloadService.clear();
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
