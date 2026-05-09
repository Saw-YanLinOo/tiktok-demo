import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/live_stream.dart';

class LiveDetailPage extends StatefulWidget {
  const LiveDetailPage({super.key, required this.stream});

  final LiveStream stream;

  @override
  State<LiveDetailPage> createState() => _LiveDetailPageState();
}

class _LiveDetailPageState extends State<LiveDetailPage> {
  int _pkSeconds = 100; // starts at 1:40
  late final Timer _pkTimer;

  static const _messages = [
    _Msg(avatar: 'M', name: 'Mika', text: '刚进直播间！'),
    _Msg(avatar: 'P', name: 'Pink Guy', text: '主播今晚状态好啊 ✨', level: 8),
    _Msg(avatar: 'R', name: 'Ramen King', text: 'joined the room', isJoin: true, badge: 'V7'),
    _Msg(avatar: 'A', name: 'Ava Li', text: 'sent Rose × 3', isGift: true, level: 4),
    _Msg(avatar: 'L', name: 'Luna', text: '好看好看！', level: 1),
  ];

  @override
  void initState() {
    super.initState();
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pkSeconds > 0) setState(() => _pkSeconds--);
    });
  }

  @override
  void dispose() {
    _pkTimer.cancel();
    super.dispose();
  }

  String get _pkTimeStr {
    final m = _pkSeconds ~/ 60;
    final s = _pkSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Split background (PK battle) ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9B1A4A), Color(0xFF4A0A22)],
                    ),
                  ),
                  child: const Center(
                    child: _CircleBlob(color: Color(0xFFD4527A), size: 200),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF0A3535), Color(0xFF000000)],
                    ),
                  ),
                  child: const Center(
                    child: _CircleBlob(color: Color(0xFF1A9090), size: 200),
                  ),
                ),
              ),
            ],
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          Positioned(
            top: top + 12,
            left: 12,
            right: 12,
            child: _TopBar(stream: widget.stream),
          ),

          // ── PK battle bar ─────────────────────────────────────────────────
          Positioned(
            top: top + 80,
            left: 0,
            right: 0,
            child: _PkBattleBar(timeStr: _pkTimeStr),
          ),

          // ── Right actions ─────────────────────────────────────────────────
          Positioned(
            right: 12,
            top: 0,
            bottom: 120,
            child: Align(
              alignment: Alignment.centerRight,
              child: _RightActions(),
            ),
          ),

          // ── Chat + input ──────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _ChatOverlay(messages: _messages),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Decorative blob
// ─────────────────────────────────────────────
class _CircleBlob extends StatelessWidget {
  const _CircleBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.stream});
  final LiveStream stream;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar + info
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF555555),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            stream.initials,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    stream.creator,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'V7',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${stream.viewerCount} watching',
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Follow button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '+ Follow',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Close button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PK battle scores + timer
// ─────────────────────────────────────────────
class _PkBattleBar extends StatelessWidget {
  const _PkBattleBar({required this.timeStr});
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Left score
              Expanded(
                child: Text(
                  '10',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              // PK timer pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PK  $timeStr',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                  ],
                ),
              ),

              // Right score
              Expanded(
                child: Text(
                  '2,411',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar (red accent line — shows who's winning)
        Container(
          height: 3,
          margin: EdgeInsets.zero,
          child: Row(
            children: [
              // Left side (losing — tiny)
              Container(width: 20, color: AppColors.accent),
              // Right side (winning)
              Expanded(child: Container(color: const Color(0xFF00BFA5))),
            ],
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(icon: Icons.ios_share_outlined, color: Colors.white),
        const SizedBox(height: 18),
        _ActionBtn(icon: Icons.emoji_events_outlined, color: const Color(0xFFFFD700)),
        const SizedBox(height: 18),
        _ActionBtn(icon: Icons.favorite, color: AppColors.accent),
        const SizedBox(height: 18),
        _ActionBtn(icon: Icons.shield_outlined, color: Colors.white),
        const SizedBox(height: 18),
        // Gift button — orange filled circle
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFFF7043),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─────────────────────────────────────────────
// Chat overlay + input bar
// ─────────────────────────────────────────────
class _Msg {
  const _Msg({
    required this.avatar,
    required this.name,
    required this.text,
    this.level,
    this.badge,
    this.isJoin = false,
    this.isGift = false,
  });

  final String avatar;
  final String name;
  final String text;
  final int? level;
  final String? badge;
  final bool isJoin;
  final bool isGift;
}

class _ChatOverlay extends StatelessWidget {
  const _ChatOverlay({required this.messages});
  final List<_Msg> messages;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Messages list
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 60, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: messages.map((m) => _MsgBubble(msg: m)).toList(),
          ),
        ),

        // Input bar
        Container(
          color: Colors.black.withValues(alpha: 0.6),
          padding: EdgeInsets.fromLTRB(12, 10, 12, bottom + 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'L',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Lv badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Lv 1',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Input field
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Say something...',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Emoji
              const Icon(Icons.sentiment_satisfied_alt_outlined,
                  color: Colors.white70, size: 26),
              const SizedBox(width: 8),
              // Gift
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7043),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MsgBubble extends StatelessWidget {
  const _MsgBubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    if (msg.isJoin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A017),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(msg.badge!,
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${msg.name} ${msg.text}',
                style: GoogleFonts.nunito(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.isGift) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF3D2A00).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF555555),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(msg.avatar,
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 7),
              if (msg.level != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('Lv ${msg.level}',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                '${msg.name} ${msg.text}',
                style: GoogleFonts.nunito(
                  color: const Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFF555555),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(msg.avatar,
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 7),
            if (msg.level != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(4)),
                child: Text('Lv ${msg.level}',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 5),
            ],
            RichText(
              text: TextSpan(
                style: GoogleFonts.nunito(fontSize: 12),
                children: [
                  TextSpan(
                    text: '${msg.name}  ',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: msg.text,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
