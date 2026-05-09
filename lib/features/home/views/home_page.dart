import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/bottom_nav.dart';
import '../providers/feed_provider.dart';
import '../providers/video_player_provider.dart';
import 'video_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentPageIndexProvider.notifier).state = index;
    ref.read(feedControllerProvider.notifier).onPageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(feedProvider);
    final currentIndex = ref.watch(currentPageIndexProvider);

    // ── Pause / resume when switching tabs ──────────────────────────────────
    // IndexedStack keeps HomePage mounted even when another tab is active,
    // so the video would keep playing. We listen to the active tab and
    // pause/resume the current video accordingly.
    ref.listen<int>(currentTabProvider, (prev, next) {
      final controllers = ref.read(feedControllerProvider);
      final activeIndex = ref.read(currentPageIndexProvider);
      final controller = controllers[activeIndex];
      if (controller == null || !controller.value.isInitialized) return;

      if (next != 0) {
        // Left Home tab → pause
        controller.pause();
      }
      // Returning to Home: leave video paused — user taps to resume.
    });
    // ────────────────────────────────────────────────────────────────────────

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      pageSnapping: true,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return VideoCard(
          key: ValueKey(videos[index].id),
          item: videos[index],
          index: index,
          isActive: index == currentIndex,
        );
      },
    );
  }
}
