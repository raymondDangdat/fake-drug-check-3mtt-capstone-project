import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import '../widgets/responsive_layout.dart';
import 'about_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

/// Main navigation container shell for Mobile (bottom nav) and Web (top header).
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context) || ResponsiveLayout.isTablet(context);

    final pages = [
      HomeScreen(onNavigateTab: _onTabSelected),
      const HistoryScreen(),
      const AboutScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? AppHeader(
              activeIndex: _currentIndex,
              onIndexSelected: _onTabSelected,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'Verify',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  activeIcon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline_rounded),
                  activeIcon: Icon(Icons.info_rounded),
                  label: 'About & Guide',
                ),
              ],
            ),
    );
  }
}
