// lib/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../homepage/homepage_widget.dart';
import '../myaccount/my_account.dart';
import '../../cart/cart_page.dart';

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
        _showComingSoon(context, 'Projects');
        break;
      case 2:
        _showComingSoon(context, 'Mobstar');
        break;
      case 3:
        context.go(MyAccountWidget.routePath);
        break;
      case 4:
        context.go(CartPage.routePath);
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

// Inside your MainScaffold
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => _onTabSelected(context, index),
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF6C7C8C),
                BlendMode.srcIn,
              ),
              height: 24,
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/home.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF0A243F),
                BlendMode.srcIn,
              ),
              height: 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/projects.svg',
              // colorFilter: const ColorFilter.mode(
              //   Color(0xFF6C7C8C),
              //   BlendMode.srcIn,
              // ),
              height: 24,
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/projects.svg',
              // colorFilter: const ColorFilter.mode(
              //   Color(0xFF6C7C8C),
              //   BlendMode.srcIn,
              // ),
              height: 24,
            ),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/mobstar.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF6C7C8C),
                BlendMode.srcIn,
              ),
              height: 24,
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/mobstar.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF0A243F),
                BlendMode.srcIn,
              ),
              height: 24,
            ),
            label: 'Mobstar',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/profile.svg',
              // colorFilter: const ColorFilter.mode(
              //   Color(0xFF6C7C8C),
              //   BlendMode.srcIn,
              // ),
              height: 24,
            ),
            activeIcon: SvgPicture.asset(
              'assets/icons/profile.svg',
              // colorFilter: const ColorFilter.mode(
              //   Color(0xFF0A243F),
              //   BlendMode.srcIn,
              // ),
              height: 24,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                SvgPicture.asset(
                  'assets/icons/cart.svg',
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF6C7C8C),
                    BlendMode.srcIn,
                  ),
                  height: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '0',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            activeIcon: Stack(
              children: [
                SvgPicture.asset(
                  'assets/icons/cart.svg',
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0A243F),
                    BlendMode.srcIn,
                  ),
                  height: 24,
                ),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '0',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Cart',
          ),
        ],
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
