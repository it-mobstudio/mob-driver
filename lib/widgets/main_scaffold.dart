// lib/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.showTopSearchBar = true,
    this.showBackButton = false,
    this.showLocationheader = true,
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A243F),
                  Color(0xFF778CC6),
                ],
              ),
            ),
            child: Column(
              children: [
                if (showLocationheader) _locationHeader(),
                if (showTopSearchBar) _topSearchBar(context),
              ],
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
      padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.green),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Iris Society",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                Text("D-102, Magarpatta, Hadapsar, Pune",
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _topSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: TextField(
              onTap: () {
                context.push('/search');
              },
              decoration: InputDecoration(
                hintText: "Search for product, category, brand...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.mic),
                filled: true,
                fillColor: const Color(0xFFF2F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
