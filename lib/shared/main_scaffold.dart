// lib/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool showTopSearchBar;
  final bool showBackButton;
  final bool showLocationheader;

  final Color? headerBackgroundColor;
  final String searchHintText;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.showTopSearchBar = true,
    this.showBackButton = false,
    this.showLocationheader = true,
    this.headerBackgroundColor,
    this.searchHintText = 'Search "Fevicol"',
  });

  void _onTabSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(HomepageWidget.routePath);
        break;
      case 1:
        _showComingSoon(context, 'Categories');
        break;
      case 2:
        context.go(OrdersPage.routePath);
        break;
      case 3:
        _showComingSoon(context, 'Credit');
        break;
    }
  }

  void _showComingSoon(BuildContext context, String tabName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tabName is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: headerBackgroundColor != null
                ? BoxDecoration(color: headerBackgroundColor)
                : const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A243F),
                        Color(0xFF778CC6),
                      ],
                    ),
                  ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (showLocationheader) _locationHeader(),
                  if (showTopSearchBar) _topSearchBar(context),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _MainBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabSelected(context, index),
      ),
    );
  }

  Widget _locationHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF00E676), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Iris Society',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 18),
                  ],
                ),
                Text(
                  'D-102, Magarpatta, Hadapsar, Pune',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: const Icon(Icons.person, color: Color(0xFF0A243F)),
          ),
        ],
      ),
    );
  }

  Widget _topSearchBar(BuildContext context) {
    final isLightHeader = headerBackgroundColor != null;
    final backIconColor =
        isLightHeader ? const Color(0xFF0A243F) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_back, color: backIconColor, size: 24),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                onTap: () {
                  context.push('/search');
                },
                decoration: InputDecoration(
                  hintText: searchHintText,
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF767C8F), size: 20),
                  suffixIcon:
                      const Icon(Icons.mic, color: Color(0xFF767C8F), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFD0D4DC), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFD0D4DC), width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFD0D4DC), width: 0.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                ),
              ),
            ),
          ),
        ],
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
