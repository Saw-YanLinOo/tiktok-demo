import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/theme/app_theme.dart';

// Tracks which tab is active
final currentTabProvider = StateProvider<int>((ref) => 0);

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
                currentTab: currentTab,
                onTap: () => ref.read(currentTabProvider.notifier).state = 0,
              ),
              _NavItem(
                icon: Icons.live_tv_outlined,
                label: 'Featured',
                index: 1,
                currentTab: currentTab,
                onTap: () => ref.read(currentTabProvider.notifier).state = 1,
              ),
              _CreateButton(),
              _NavItem(
                icon: Icons.chat_bubble,
                label: 'Messages',
                index: 3,
                currentTab: currentTab,
                badge: '3',
                onTap: () => ref.read(currentTabProvider.notifier).state = 3,
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Me',
                index: 4,
                currentTab: currentTab,
                onTap: () => ref.read(currentTabProvider.notifier).state = 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentTab,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final int index;
  final int currentTab;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isActive = currentTab == index;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? AppColors.white : AppColors.navInactive,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // pink side
            Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              transform: Matrix4.translationValues(4, 0, 0),
            ),
            // teal side
            Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accentTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              transform: Matrix4.translationValues(-4, 0, 0),
            ),
            // white center
            Container(
              width: 36,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
