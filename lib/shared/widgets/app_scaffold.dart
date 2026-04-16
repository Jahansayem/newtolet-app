import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// Main scaffold that wraps the bottom navigation bar and content area for
/// the three primary tabs: Home, Member Hub, and My Center.
///
/// Works with GoRouter's [StatefulNavigationShell] to preserve tab state.
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTabTapped(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarSelected,
        unselectedItemColor: AppColors.navBarUnselected,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Member',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'My Center',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      // Navigate to the initial location of the branch when tapping the
      // currently active tab item (i.e., scroll to top / reset behaviour).
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
