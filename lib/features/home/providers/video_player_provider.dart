import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_download_service.dart';
import 'feed_provider.dart';

/// ±2 sliding window controller manager.
///
/// Controller lifecycle for each slot:
///
///   Fast-path — file already in [VideoDownloadService] cache
///     → file controller initialised immediately, zero network traffic,
///       zero loading screen.
///
///   Slow-path — file not yet cached
///     → [VideoDownloadService.download] runs (real-time % shown in
///       [_TikTokLoader] via [VideoDownloadService.progressOf])
///     → once the file lands, a file controller is initialised and shown.
///
/// No networkUrl controller is ever created. This avoids bandwidth
/// contention between the stream and the concurrent file download that
/// caused [networkCtrl.initialize()] to hang indefinitely.
///
/// Background downloads for N+1…N+3 are fire-and-forgotten so files
/// arrive before the user swipes to them.
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

  /// Initialises center slot first (visible video must be live before
  /// surrounding slots), then ±2 concurrently.
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

      // ── Fast-path: file already downloaded ──────────────────────────────
      final cached = VideoDownloadService.getCached(url);
      if (cached != null && await cached.exists()) {
        await _activateFile(index, cached);
        return;
      }

      // ── Slow-path: wait for full file download, then show video ─────────
      // Progress (0→1) is reflected in VideoDownloadService.progressOf(url)
      // and displayed live in _TikTokLoader.
      final file = await VideoDownloadService.download(url);
      if (file == null || !mounted) return;

      await _activateFile(index, file);
    } catch (e) {
      // ignore: avoid_print
      print('[FeedController] Error idx=$index: $e');
    } finally {
      _initializing.remove(index);
    }
  }

  /// Initialises a file-based controller for [index] and adds it to state.
  Future<void> _activateFile(int index, File file) async {
    final ctrl = CachedVideoPlayerPlusController.file(file);
    await ctrl.initialize();
    ctrl.setLooping(true);

    if (mounted && !state.containsKey(index)) {
      state = {...state, index: ctrl};
    } else {
      ctrl.dispose(); // slot was filled by another path while we waited
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
    final updated = Map<int, CachedVideoPlayerPlusController>.from(state);
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
