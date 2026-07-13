import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    navBarVisible.addListener(_onVisibilityChange);
  }

  @override
  void dispose() {
    navBarVisible.removeListener(_onVisibilityChange);
    super.dispose();
  }

  void _onVisibilityChange() {
    if (mounted && navBarVisible.value != _visible) {
      setState(() => _visible = navBarVisible.value);
    }
  }

  void _onTap(int index) {
    if (index != widget.navigationShell.currentIndex) {
      AppHaptics.tabSelection();
      navBarVisible.value = true;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: _MainBottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
        ),
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

  static const _svgItems = [
    _NavItemData(
      label: 'Home',
      icon: 'assets/images/Homemenu.svg',
      selectedIcon: 'assets/images/Homeselect.svg',
    ),
    _NavItemData(
      label: 'Categories',
      icon: 'assets/images/Categories.svg',
      selectedIcon: 'assets/images/Categoriesselect.svg',
    ),
    _NavItemData(
      label: 'Orders',
      icon: 'assets/images/Orders.svg',
      selectedIcon: 'assets/images/Ordersselect.svg',
    ),
    _NavItemData(
      label: 'Credit',
      icon: 'assets/images/Credit.svg',
      selectedIcon: 'assets/images/Creditselect.svg',
    ),
  ];

  // Width of the trailing Rufus/menu button slot (56 icon + 16 right
  // padding) — subtracted from the row's width so the indicator bar is
  // centered against the 4 equally-Expanded tabs only, not that slot.
  static const _trailingSlotWidth = 72.0;
  static const _indicatorWidth = 64.0;

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
          height: kBottomNavBarHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabsWidth = constraints.maxWidth - _trailingSlotWidth;
              final tabWidth = tabsWidth / _svgItems.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: tabWidth * currentIndex +
                        (tabWidth - _indicatorWidth) / 2,
                    width: _indicatorWidth,
                    height: 4,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._svgItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = currentIndex == index;
                        return Expanded(
                          child: InkWell(
                            onTap: () => onTap(index),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 11),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                    child: SvgPicture.asset(
                                      isSelected
                                          ? item.selectedIcon
                                          : item.icon,
                                      key: ValueKey(isSelected),
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    style: GoogleFonts.inter(
                                      color: isSelected
                                          ? Colors.black
                                          : const Color(0xFF8D8F91),
                                      fontSize: 11,
                                      height: 16 / 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    child: Text(item.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 56,
                          child: InkWell(
                            onTap: () {
                              AppHaptics.tabSelection();
                              context.push(ReferralPage.routePath);
                            },
                            child: const Align(
                              alignment: Alignment.topCenter,
                              child: _LottieMenuIcon(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LottieMenuIcon extends StatelessWidget {
  const _LottieMenuIcon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: Lottie.asset(
            'assets/lottiejson/Menu-animation.json',
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String icon;
  final String selectedIcon;
}
