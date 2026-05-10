import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

// ── Mock grid thumbnails (color placeholders) ─────────────────────────────────

const _gridColors = [
  Color(0xFF1A1A2E),
  Color(0xFF16213E),
  Color(0xFF0F3460),
  Color(0xFF533483),
  Color(0xFF2D132C),
  Color(0xFF1B262C),
  Color(0xFF0A3D62),
  Color(0xFF6A0572),
  Color(0xFF1C1C1C),
  Color(0xFF2C3E50),
  Color(0xFF243B55),
  Color(0xFF141E30),
];

const _gridLabels = [
  '2.1w', '8.4k', '14w', '3.2k',
  '6.7k', '21w', '900', '4.5k',
  '1.1w', '3.8k', '7.2k', '9.9k',
];

// ── Profile Page ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _ProfileSliverHeader(tabCtrl: _tabCtrl),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _PostsGrid(),
            _LikedGrid(),
            _PlaceholderTab(label: 'Reposts'),
          ],
        ),
      ),
    );
  }
}

// ── Sliver header (collapses on scroll) ──────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  const _ProfileSliverHeader({required this.tabCtrl});
  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SliverToBoxAdapter(
      child: Column(
        children: [
          SizedBox(height: top),
          _TopBar(),
          _AvatarSection(),
          _StatsRow(),
          _ActionButtons(),
          _BioSection(),
          _TabBar(tabCtrl: tabCtrl),
        ],
      ),
    );
  }
}

// ── Top bar: username + icons ─────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                '@yanyan_dev',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.add_box_outlined, color: AppColors.white, size: 24),
              const SizedBox(width: 16),
              const Icon(Icons.menu, color: AppColors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Avatar + name section ─────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFF7C3AED)],
            ),
            border: Border.all(color: const Color(0xFF222222), width: 3),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Y',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'YanYan Chan',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '@yanyan_dev',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: AppColors.textSecondary, size: 10),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(value: '412', label: 'Following'),
          _Divider(),
          _Stat(value: '28.4k', label: 'Followers'),
          _Divider(),
          _Stat(value: '1.2M', label: 'Likes'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFF333333),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _OutlineButton(label: 'Edit profile'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _OutlineButton(label: 'Promote post'),
          ),
          const SizedBox(width: 8),
          _IconButton(icon: Icons.person_add_outlined),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.white, size: 18),
    );
  }
}

// ── Bio ───────────────────────────────────────────────────────────────────────

class _BioSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Flutter dev | building cool things\n🎬 Short videos | tech & life',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.link, color: AppColors.textSecondary, size: 13),
              SizedBox(width: 4),
              Text(
                'flicko.dev',
                style: TextStyle(color: Color(0xFF69C9D0), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabCtrl});
  final TabController tabCtrl;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabCtrl,
      dividerColor: const Color(0xFF1A1A1A),
      indicatorColor: AppColors.white,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 1.5,
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.textSecondary,
      tabs: const [
        Tab(icon: Icon(Icons.grid_on, size: 22)),
        Tab(icon: Icon(Icons.favorite_border, size: 22)),
        Tab(icon: Icon(Icons.repeat, size: 22)),
      ],
    );
  }
}

// ── Posts grid ────────────────────────────────────────────────────────────────

class _PostsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _gridColors.length,
      itemBuilder: (_, i) => _GridTile(color: _gridColors[i], label: _gridLabels[i]),
    );
  }
}

class _LikedGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 6,
      itemBuilder: (_, i) => _GridTile(
        color: _gridColors[_gridColors.length - 1 - i],
        label: _gridLabels[i],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(color: color)),
        // Play icon
        const Center(
          child: Icon(Icons.play_arrow_rounded, color: Colors.white24, size: 32),
        ),
        // View count
        Positioned(
          left: 4,
          bottom: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, color: Colors.white, size: 12),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────

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
