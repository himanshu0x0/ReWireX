import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rewirex/features/analytics/screens/insights_screen.dart';

import 'package:rewirex/features/dashboard/screens/dashboard_screen.dart';
import 'package:rewirex/features/analytics/screens/analytics_screen.dart';



class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  // ── Pages ─────────────────────────────────────────────────
  // Each screen has its own AppBar + Drawer (AppDrawer).
  // MainNavigationScreen provides ONLY the bottom nav bar.
  static const List<Widget> _pages = [
    DashboardScreen(),
    AnalyticsScreen(),
    InsightsScreen(),
  ];

  // ── Bottom nav items ──────────────────────────────────────
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon:        Icons.home_outlined,
      activeIcon:  Icons.home_rounded,
      label:       'Home',
    ),
    _NavItem(
      icon:        Icons.bar_chart_outlined,
      activeIcon:  Icons.bar_chart_rounded,
      label:       'Analytics',
    ),
    _NavItem(
      icon:        Icons.psychology_outlined,
      activeIcon:  Icons.psychology_rounded,
      label:       'Insights',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),

      // ── Body: each page manages its own AppBar + Drawer ───
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item      = _navItems[i];
              final isActive  = _currentIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Icon with active indicator ──────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isActive
                                ? const Color(0xFF6C63FF).withOpacity(0.15)
                                : Colors.transparent,
                          ),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            color: isActive
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.35),
                            size: isActive ? 24 : 22,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // ── Label ───────────────────────────
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.3),
                            fontSize: isActive ? 11 : 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Nav item data class ────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}