import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class HomeSavingsCard extends StatelessWidget {
  const HomeSavingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFF104D70),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Build now, pay later',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get up to 50 lakhs credit, 45 days interest free.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 15 / 11,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/3d-hands-holding.png',
              width: 82,
              height: 82,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
