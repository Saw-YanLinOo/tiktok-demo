import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/video_item.dart';
import '../providers/video_player_provider.dart';
import '../services/video_download_service.dart';

class VideoCard extends ConsumerWidget {
  const VideoCard({
    super.key,
    required this.item,
    required this.index,
    required this.isActive,
  });

  final VideoItem item;
  final int index;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() → this card only rebuilds when ITS slot changes.
    final controller = ref.watch(
      feedControllerProvider.select((map) => map[index]),
    );

    final isReady = controller != null && controller.value.isInitialized;

    // Play / pause based on active slot.
    if (isReady) {
      if (isActive) {
        if (!controller.value.isPlaying) controller.play();
      } else {
        if (controller.value.isPlaying) controller.pause();
      }
    }

    // Always render the full overlay stack — top bar, actions, and info stay
    // visible during loading just like TikTok (no blank screen flash).
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background: video when ready, TikTok loader when buffering ──
        if (isReady)
          _VideoBackground(controller: controller)
        else
          _TikTokLoader(videoUrl: item.videoUrl),

        // ── Gradient overlays (always visible) ──
        const _Gradients(),

        // ── Top bar (always visible) ──
        const Positioned(
          top: 0, left: 0, right: 0,
          child: _TopBar(),
        ),

        // ── Right action column, vertically centered ──
        Positioned(
          right: 10, top: 80, bottom: 80,
          child: Center(child: _RightActions(item: item)),
        ),

        // ── Bottom creator info ──
        Positioned(
          left: 14, right: 70, bottom: 90,
          child: _BottomInfo(item: item),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Video background
// ─────────────────────────────────────────────
class _VideoBackground extends StatefulWidget {
  const _VideoBackground({required this.controller});
  final CachedVideoPlayerPlusController controller;

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  bool _isPaused = false;

  void _onTap() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      setState(() => _isPaused = true);
    } else {
      widget.controller.play();
      setState(() => _isPaused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video ──────────────────────────────────────────────────────────
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: widget.controller.value.aspectRatio * size.height,
                height: size.height,
                child: CachedVideoPlayerPlus(widget.controller),
              ),
            ),
          ),

          // ── Persistent pause icon (stays until user resumes) ───────────────
          if (_isPaused)
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),

        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Loading indicator with real-time download progress.
//
// • Dark gradient background
// • Circular progress ring:
//     - determinate (shows %) when download is in progress
//     - indeterminate (spinning) when waiting for network / initialising
// • Percentage label inside the ring when progress is known
// ─────────────────────────────────────────────
class _TikTokLoader extends StatelessWidget {
  const _TikTokLoader({required this.videoUrl});
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark gradient — feels like a video about to appear
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C1C1C), Color(0xFF000000)],
            ),
          ),
        ),

        // Circular progress with real download percentage
        Center(
          child: ValueListenableBuilder<double>(
            valueListenable: VideoDownloadService.progressOf(videoUrl),
            builder: (context, progress, child) {
              // Show determinate ring only when download is actively progressing
              final hasProgress = progress > 0.0 && progress < 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: hasProgress ? progress : null,
                      strokeWidth: 3,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                  if (hasProgress)
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Gradient overlays
// ─────────────────────────────────────────────
class _Gradients extends StatelessWidget {
  const _Gradients();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Top fade for top bar readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom fade for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Top bar: LIVE pill | Following | For You | Search
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topPadding + 6, left: 14, right: 14, bottom: 8),
      child: Row(
        children: [
          // LIVE pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: AppColors.liveBadge, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.liveBadge,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Following | For You tabs
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Following',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '|',
                    style: TextStyle(color: Color(0x44FFFFFF), fontSize: 20),
                  ),
                ),
                _ActiveTab(label: 'For You'),
              ],
            ),
          ),

          // Search icon
          const Icon(Icons.search, color: AppColors.white, size: 27),
        ],
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 2,
          width: 20,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Right action column
// ─────────────────────────────────────────────
class _RightActions extends StatelessWidget {
  const _RightActions({required this.item});
  final VideoItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + follow
        _Avatar(initials: item.initials),
        const SizedBox(height: 28),

        // Like
        _ActionButton(
          icon: Icons.favorite,
          label: '2.7w',
          iconColor: AppColors.white,
        ),
        const SizedBox(height: 24),

        // Comment
        _ActionButton(
          icon: Icons.chat_bubble,
          label: '337',
        ),
        const SizedBox(height: 24),

        // Bookmark
        _ActionButton(
          icon: Icons.bookmark,
          label: '129',
        ),
        const SizedBox(height: 24),

        // Share
        _ActionButton(
          icon: Icons.send,
          label: 'Share',
        ),
        const SizedBox(height: 24),

        // Music disc
        const _MusicDisc(),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF555555),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Positioned(
          bottom: -8,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MusicDisc extends StatefulWidget {
  const _MusicDisc();

  @override
  State<_MusicDisc> createState() => _MusicDiscState();
}

class _MusicDiscState extends State<_MusicDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4A4A4A), width: 3),
          gradient: const SweepGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF444444), Color(0xFF2A2A2A)],
          ),
        ),
        child: Center(
          child: Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Marquee text — translates by one unit width per cycle, loops seamlessly.
// Uses TextPainter to measure text width so the speed is consistent
// regardless of string length.
// ─────────────────────────────────────────────
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  // Measures a single unit (text + gap) so we know how far to translate.
  double _unitWidth(String unit) {
    final tp = TextPainter(
      text: TextSpan(text: unit, style: widget.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = '          '; // visual spacing between repetitions
    final unit = '${widget.text}$gap';
    final unitW = _unitWidth(unit);

    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          // Slides left by one full unit width per cycle → seamless loop
          // because the second copy is identical to the first.
          offset: Offset(-_ctrl.value * unitW, 0),
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(unit, style: widget.style, softWrap: false),
            Text(unit, style: widget.style, softWrap: false),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom info: username, caption, audio
// ─────────────────────────────────────────────
class _BottomInfo extends StatelessWidget {
  const _BottomInfo({required this.item});
  final VideoItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.creator,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          item.caption,
          style: const TextStyle(
            color: Color(0xE5FFFFFF),
            fontSize: 12,
            height: 1.45,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(Icons.music_note, color: Color(0xAAFFFFFF), size: 13),
            const SizedBox(width: 4),
            Expanded(
              child: _MarqueeText(
                text: item.audioLabel,
                style: const TextStyle(color: Color(0xAAFFFFFF), fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
