import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/tab_header.dart';

class CreditPage extends StatelessWidget {
  static const String routeName = 'Credit';
  static const String routePath = '/credit';

  const CreditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TabHeader(showTopSearchBar: false, showLocationheader: false),
          Expanded(
            child: Center(
              child: Text(
                'Credit is coming soon',
                style: GoogleFonts.inter(
                  color: const Color(0xFF596378),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
