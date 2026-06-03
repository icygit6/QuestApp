import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/quests/presentation/quest_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFor(location);
    final pendingCount = ref.watch(pendingQuestCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          border: Border(top: BorderSide(color: AppColors.borderColor)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: (index) => context.go(_routeFor(index)),
          items: [
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.sports_martial_arts_rounded,
                selected: selectedIndex == 0,
                badge: pendingCount,
              ),
              label: AppStrings.quests,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.explore_rounded,
                selected: selectedIndex == 1,
              ),
              label: AppStrings.explore,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.person_rounded,
                selected: selectedIndex == 2,
              ),
              label: AppStrings.profile,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.emoji_events_rounded,
                selected: selectedIndex == 3,
              ),
              label: AppStrings.rankings,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(
                icon: Icons.settings_rounded,
                selected: selectedIndex == 4,
              ),
              label: AppStrings.settings,
            ),
          ],
        ),
      ),
    );
  }

  int _indexFor(String location) {
    if (location.startsWith('/explore')) {
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    if (location.startsWith('/leaderboard')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  String _routeFor(int index) {
    return switch (index) {
      0 => '/quests',
      1 => '/explore',
      2 => '/profile',
      3 => '/leaderboard',
      _ => '/settings',
    };
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.selected, this.badge = 0});

  final IconData icon;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badge > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.hard,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
    return selected
        ? iconWidget.animate().scale(
            begin: const Offset(0.86, 0.86),
            end: const Offset(1.16, 1.16),
            duration: 180.ms,
          )
        : iconWidget;
  }
}
