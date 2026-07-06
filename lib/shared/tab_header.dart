// lib/shared/tab_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:go_router/go_router.dart';

/// Gradient location + search header shared by the top-level tab pages
/// (Home, Categories, Orders, Credit). Extracted from the old `MainScaffold`
/// so the bottom navigation bar can be owned once by the router shell while
/// each tab keeps its own header.
class TabHeader extends StatelessWidget {
  final bool showTopSearchBar;
  final bool showBackButton;
  final bool showLocationheader;
  final Color? headerBackgroundColor;
  final String searchHintText;

  const TabHeader({
    super.key,
    this.showTopSearchBar = true,
    this.showBackButton = false,
    this.showLocationheader = true,
    this.headerBackgroundColor,
    this.searchHintText = 'Search "Fevicol"',
  });

  @override
  Widget build(BuildContext context) {
    if (!showLocationheader && !showTopSearchBar) {
      return const SizedBox.shrink();
    }
    return Container(
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
            child: SvgPicture.asset(
              'assets/images/profile.svg',
              width: 24,
              height: 24,
            ),
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
              onTap: () {
                AppHaptics.lightTap();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: AppBackIcon(color: backIconColor),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextField(
                onTap: () {
                  AppHaptics.lightTap();
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
