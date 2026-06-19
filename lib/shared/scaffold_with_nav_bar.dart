// lib/shared/scaffold_with_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Built once by the `StatefulShellRoute`, so the bottom navigation bar
/// persists (no rebuild/flicker) while [navigationShell] swaps the
/// IndexedStack body between each tab's own preserved navigator/state.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    if (index != navigationShell.currentIndex) {
      AppHaptics.tabSelection();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: _MainBottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _MainBottomNavigationBar extends StatelessWidget {
  const _MainBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _BottomNavigationItemData(
      label: 'Home',
      icon: 'assets/images/Homemenu.svg',
      selectedIcon: 'assets/images/Homeselect.svg',
    ),
    _BottomNavigationItemData(
      label: 'Categories',
      icon: 'assets/images/Categories.svg',
      selectedIcon: 'assets/images/Categoriesselect.svg',
    ),
    _BottomNavigationItemData(
      label: 'Orders',
      icon: 'assets/images/Orders.svg',
      selectedIcon: 'assets/images/Ordersselect.svg',
    ),
    _BottomNavigationItemData(
      label: 'Credit',
      icon: 'assets/images/Credit.svg',
      selectedIcon: 'assets/images/Creditselect.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 34,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          isSelected ? item.selectedIcon : item.icon,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFF8D8F91),
                            fontSize: 11,
                            height: 16 / 11,
                            fontWeight: FontWeight.w600,
                          ),
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

class _BottomNavigationItemData {
  const _BottomNavigationItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String icon;
  final String selectedIcon;
}
