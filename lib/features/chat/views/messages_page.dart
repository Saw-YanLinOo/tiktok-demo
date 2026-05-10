import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

// ── Mock data ────────────────────────────────────────────────────────────────

class _Story {
  const _Story({
    required this.label,
    required this.initials,
    this.isMe = false,
    this.isLive = false,
    this.isFire = false,
    this.isOnline = false,
    this.gradientA = const Color(0xFFB06AB3),
    this.gradientB = const Color(0xFF4568DC),
  });
  final String label;
  final String initials;
  final bool isMe;
  final bool isLive;
  final bool isFire;
  final bool isOnline;
  final Color gradientA;
  final Color gradientB;
}

const _stories = [
  _Story(
    label: 'Your note',
    initials: 'Me',
    isMe: true,
    gradientA: Color(0xFFB06AB3),
    gradientB: Color(0xFF4568DC),
  ),
  _Story(
    label: '小鱼',
    initials: '小',
    isOnline: true,
    gradientA: Color(0xFF8E54E9),
    gradientB: Color(0xFF4776E6),
  ),
  _Story(
    label: 'Ava',
    initials: 'A',
    isFire: true,
    isOnline: true,
    gradientA: Color(0xFF56CCF2),
    gradientB: Color(0xFF2F80ED),
  ),
  _Story(
    label: 'Ramen',
    initials: 'R',
    isLive: true,
    gradientA: Color(0xFFEB5757),
    gradientB: Color(0xFFB06AB3),
  ),
  _Story(
    label: 'JJ',
    initials: 'J',
    isOnline: true,
    gradientA: Color(0xFF6A3093),
    gradientB: Color(0xFFA044FF),
  ),
];

class _ChatItem {
  const _ChatItem({
    required this.name,
    required this.initials,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isOnline = false,
    this.isFire = false,
    this.hasVideoIcon = false,
    this.gradientA = const Color(0xFF8E54E9),
    this.gradientB = const Color(0xFF4776E6),
  });
  final String name;
  final String initials;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final bool isFire;
  final bool hasVideoIcon;
  final Color gradientA;
  final Color gradientB;
}

const _chats = [
  _ChatItem(
    name: 'Mira 🎬',
    initials: 'M',
    lastMessage: '🔒 已锁定一条消息',
    time: 'now',
    unread: 1,
    isOnline: true,
    hasVideoIcon: true,
    gradientA: Color(0xFF56CCF2),
    gradientB: Color(0xFF4776E6),
  ),
  _ChatItem(
    name: '小鱼 Xiaoyu',
    initials: '小',
    lastMessage: '哈哈那个视频太可爱了 🌸',
    time: '2m',
    unread: 2,
    isOnline: true,
    gradientA: Color(0xFF8E54E9),
    gradientB: Color(0xFF4776E6),
  ),
  _ChatItem(
    name: 'Ava Li',
    initials: 'A',
    lastMessage: '你在拍新的吗',
    time: '14m',
    isFire: true,
    isOnline: true,
    gradientA: Color(0xFF56CCF2),
    gradientB: Color(0xFF2F80ED),
  ),
  _ChatItem(
    name: 'Ryan',
    initials: 'R',
    lastMessage: 'sent you a video',
    time: '1h',
    unread: 1,
    gradientA: Color(0xFF56CCF2),
    gradientB: Color(0xFF4568DC),
  ),
  _ChatItem(
    name: 'Ramen King',
    initials: 'R',
    lastMessage: 'recipe plz 🙏',
    time: '3h',
    hasVideoIcon: true,
    gradientA: Color(0xFFEB5757),
    gradientB: Color(0xFFB06AB3),
  ),
];

// ── Page ─────────────────────────────────────────────────────────────────────

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(height: top),
          _Header(tabCtrl: _tabCtrl),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _MessagesTab(),
                _PlaceholderTab(label: 'Notifications'),
                _PlaceholderTab(label: 'Leaderboard'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header with tabs ─────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.tabCtrl});
  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TabBar(
              controller: tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorColor: AppColors.white,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Messages'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '4',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(text: 'Notifications'),
                const Tab(text: 'Leaderboard'),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: AppColors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Messages tab content ─────────────────────────────────────────────────────

class _MessagesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 16),
        _StoriesRow(),
        const SizedBox(height: 4),
        _ActivityRow(),
        const Divider(color: Color(0xFF1A1A1A), height: 1),
        ..._chats.map((c) => _ChatRow(chat: c)),
      ],
    );
  }
}

// ── Stories row ──────────────────────────────────────────────────────────────

class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _stories.length,
        separatorBuilder: (context, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) => _StoryBubble(story: _stories[i]),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Ring (fire / live / plain)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: story.isFire
                      ? const SweepGradient(colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFF6B00),
                          Color(0xFFFF0000),
                          Color(0xFFFFD700),
                        ])
                      : story.isMe
                          ? null
                          : LinearGradient(
                              colors: [story.gradientA, story.gradientB],
                            ),
                  color: story.isMe ? const Color(0xFF1A1A1A) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [story.gradientA, story.gradientB],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: story.isMe
                            ? const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 22,
                              )
                            : Text(
                                story.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Fire emoji on top
              if (story.isFire)
                const Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                ),

              // LIVE badge
              if (story.isLive)
                Positioned(
                  bottom: 0,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Online dot
              if (story.isOnline && !story.isLive)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44CC44),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),

              // Me + button
              if (story.isMe)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            story.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: story.isMe
                  ? AppColors.textSecondary
                  : AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity row ─────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Xiaoyu liked your video and 3 more',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: 14,
          ),
        ],
      ),
    );
  }
}

// ── Chat row ─────────────────────────────────────────────────────────────────

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat});
  final _ChatItem chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF111111), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: chat.isFire
                      ? const SweepGradient(colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFF6B00),
                          Color(0xFFFF0000),
                          Color(0xFFFFD700),
                        ])
                      : null,
                ),
                child: chat.isFire
                    ? Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: _AvatarInner(chat: chat),
                          ),
                        ),
                      )
                    : _AvatarInner(chat: chat),
              ),

              // Fire emoji
              if (chat.isFire)
                const Positioned(
                  top: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('🔥', style: TextStyle(fontSize: 14)),
                  ),
                ),

              // Online dot
              if (chat.isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44CC44),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Name + message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chat.lastMessage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Time + badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat.time,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chat.hasVideoIcon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF333333),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: AppColors.accent,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '3',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (chat.hasVideoIcon && chat.unread > 0)
                    const SizedBox(width: 6),
                  if (chat.unread > 0)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${chat.unread}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarInner extends StatelessWidget {
  const _AvatarInner({required this.chat});
  final _ChatItem chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [chat.gradientA, chat.gradientB],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        chat.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Placeholder for other tabs ────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }
}
