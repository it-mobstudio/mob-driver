import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.topPadding = 24,
    this.bottomPadding = 16,
  });

  final String title;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 24 / 17,
        ),
      ),
    );
  }
}
