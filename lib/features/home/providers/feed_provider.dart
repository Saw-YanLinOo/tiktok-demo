import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/video_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FeedNotifier — infinite-scroll paginated feed
//
// API contract (mock; replace the body of [_fetchPage] with a real HTTP call):
//   • Returns 5 items per page
//   • Each item includes id, url, size, duration
//   • Pages are 0-indexed
//   • Empty page → end of feed
//
// Merge strategy:
//   • No duplicates (id-based dedup)
//   • Smaller files sorted first within the merged list so the download queue
//     can serve faster-starting videos to the priority worker
// ─────────────────────────────────────────────────────────────────────────────
class FeedNotifier extends StateNotifier<List<VideoItem>> {
  FeedNotifier() : super([]) {
    fetchNextPage(); // bootstrap first page on construction
  }

  static const _pageSize = 5;

  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  bool get isLoading => _loading;
  bool get hasMore => _hasMore;

  /// Fetches every remaining page sequentially until the feed is complete.
  /// Used by the splash screen to get the full sorted list before deciding
  /// which 3 videos to pre-download.
  Future<void> fetchAllPages() async {
    while (_hasMore) {
      await fetchNextPage();
    }
  }

  /// Fetches the next page and merges it into [state].
  /// Safe to call multiple times — concurrent calls are no-ops.
  Future<void> fetchNextPage() async {
    if (_loading || !_hasMore) return;
    _loading = true;

    try {
      // ── Simulated async API call ──────────────────────────────────────────
      // In production: replace with Dio/http GET and parse JSON like
      //   [{"id":"v1","url":"...","size":4200000,"duration":14}, ...]
      await Future.delayed(const Duration(milliseconds: 80));
      final page = await _fetchPage(_page);
      // ─────────────────────────────────────────────────────────────────────

      if (page.isEmpty) {
        _hasMore = false;
        _log('End of feed at page $_page');
        return;
      }

      // Dedup by id
      final existingIds = state.map((v) => v.id).toSet();
      final fresh = page.where((v) => !existingIds.contains(v.id)).toList();

      if (fresh.isEmpty) {
        _hasMore = false;
        return;
      }

      // Merge + sort smaller files first (feeds the priority download queue)
      final merged = [...state, ...fresh]
        ..sort((a, b) => a.size.compareTo(b.size));

      state = merged;
      _page++;
      _log('Page $_page loaded — ${fresh.length} new, total=${state.length}');
    } finally {
      _loading = false;
    }
  }

  // ── Mock paginator (replace with real API) ─────────────────────────────────
  Future<List<VideoItem>> _fetchPage(int page) async {
    final all = VideoItem.mockList;
    final start = page * _pageSize;
    if (start >= all.length) return [];
    final end = (start + _pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[FeedNotifier] $msg');
  }
}

final feedProvider =
    StateNotifierProvider<FeedNotifier, List<VideoItem>>(
  (ref) => FeedNotifier(),
);

/// Tracks the currently visible page index.
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
