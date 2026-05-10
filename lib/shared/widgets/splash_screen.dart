import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/home/models/video_item.dart';
import '../../features/home/providers/feed_provider.dart';
import '../../features/home/services/video_download_service.dart';
import '../../features/chat/views/messages_page.dart';
import '../../features/home/views/home_page.dart';
import '../../features/live/views/featured_page.dart';
import '../../features/profile/views/profile_page.dart';
import 'bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
//
// Flow:
//   1. FeedNotifier fetches first page (auto-triggered on construction).
//   2. Splash watches feedProvider; once it has items it starts downloading
//      the 3 smallest videos fully (sorted by size).
//   3. Progress bar fills 0 → 1/3 → 2/3 → 3/3 as each download completes.
//   4. When all 3 are downloaded AND min display time has elapsed, the splash
//      fades out and MainShell appears.
//   5. Hard timeout: after 8 s the app proceeds regardless so it never hangs
//      on a slow connection (remaining downloads continue in background).
//
// After the splash, VideoDownloadService.getCached() returns the 3 downloaded
// files immediately, so FeedControllerNotifier uses fast-path file controllers
// for the first 3 videos — zero loading screen on the home feed.
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Timing ──────────────────────────────────────────────────────────────────
  static const _minDisplayMs = 1200;
  static const _maxDisplayMs = 8000;
  static const _totalDownloads = 3;

  // ── State ────────────────────────────────────────────────────────────────────
  bool _downloadsStarted = false;
  int _downloadedCount = 0; // 0..3
  bool _downloadsReady = false;
  bool _minElapsed = false;
  bool _dismissed = false;

  // ── Animation controllers ────────────────────────────────────────────────────
  late final AnimationController _iconCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final AnimationController _wordCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    value: 1.0,
  );

  late final Animation<double> _iconScale = CurvedAnimation(
    parent: _iconCtrl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _wordFade = CurvedAnimation(
    parent: _wordCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _wordSlide = Tween<Offset>(
    begin: const Offset(0, 0.35),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _startAnimations();
    _startMinTimer();
    _startMaxTimer();
  }

  void _startAnimations() {
    _iconCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _wordCtrl.forward();
    });
  }

  void _startMinTimer() {
    Future.delayed(const Duration(milliseconds: _minDisplayMs), () {
      if (!mounted) return;
      _minElapsed = true;
      _tryDismiss();
    });
  }

  void _startMaxTimer() {
    Future.delayed(const Duration(milliseconds: _maxDisplayMs), () {
      if (!mounted || _dismissed) return;
      _dismiss(); // proceed regardless — downloads continue in background
    });
  }

  // ── Download logic ────────────────────────────────────────────────────────────

  Future<void> _startDownloads(List<VideoItem> _) async {
    // Fetch ALL pages first so the complete sorted list is available.
    // feedProvider sorts by size on every merge, so after this call
    // feedProvider[0] is the absolute smallest video in the entire dataset.
    await ref.read(feedProvider.notifier).fetchAllPages();

    if (!mounted) return;

    // Take the 3 smallest videos from the fully-loaded, sorted feed.
    final allVideos = ref.read(feedProvider);
    final targets = allVideos.take(_totalDownloads).toList();

    // Download all 3 concurrently; update progress bar as each finishes.
    await Future.wait(
      targets.map((v) async {
        await VideoDownloadService.download(v.videoUrl);
        if (mounted) setState(() => _downloadedCount++);
      }),
    );

    if (!mounted) return;
    _downloadsReady = true;
    _tryDismiss();
  }

  void _tryDismiss() {
    if (_minElapsed && _downloadsReady && !_dismissed) _dismiss();
  }

  Future<void> _dismiss() async {
    if (_dismissed) return;
    _dismissed = true;
    await _fadeCtrl.reverse();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShell(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _wordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch feed — kick off downloads as soon as first page arrives.
    final feed = ref.watch(feedProvider);
    if (feed.isNotEmpty && !_downloadsStarted) {
      _downloadsStarted = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _startDownloads(feed));
    }

    final progress = _totalDownloads > 0
        ? _downloadedCount / _totalDownloads
        : 0.0;

    return FadeTransition(
      opacity: _fadeCtrl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── App icon ─────────────────────────────────────────────────
              ScaleTransition(
                scale: _iconScale,
                child: const _AppIcon(),
              ),

              const SizedBox(height: 20),

              // ── Wordmark ──────────────────────────────────────────────────
              SlideTransition(
                position: _wordSlide,
                child: FadeTransition(
                  opacity: _wordFade,
                  child: Text(
                    'TikDemo',
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Download progress bar ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── Status label ──────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _downloadsReady
                      ? 'Ready'
                      : feed.isEmpty
                          ? 'Loading feed…'
                          : 'Preparing videos… $_downloadedCount/$_totalDownloads',
                  key: ValueKey(_downloadedCount + (feed.isEmpty ? 100 : 0)),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Made with Flutter',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: Colors.white24,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppIcon — rounded square with coral→violet gradient
// ─────────────────────────────────────────────────────────────────────────────
class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B6B), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withAlpha(100),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            Text(
              'T',
              style: GoogleFonts.nunito(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MainShell
// ─────────────────────────────────────────────────────────────────────────────
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = [
    HomePage(),
    FeaturedPage(),
    SizedBox(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentTab,
        children: _pages,
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
