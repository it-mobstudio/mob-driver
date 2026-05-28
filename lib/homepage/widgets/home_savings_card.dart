import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class HomeSavingsCard extends StatelessWidget {
  const HomeSavingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 181,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment(0.50, 0.00),
                end: Alignment(1.07, 1.27),
                colors: [Color(0xFF043860), Color(0xFF0973C6)],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 160,
                  top: 33,
                  child: SizedBox(
                    width: 219.47,
                    height: 219.50,
                    child: SvgPicture.asset(
                      'assets/images/Dotsmobcredit.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Positioned(
                  right: 44,
                  top: 81,
                  child: Image.asset(
                    'assets/images/mobcreditbannerimage.png',
                    width: 75,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: SvgPicture.asset(
                    'assets/images/mobcreditlogo.svg',
                    width: 96,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 50,
                  width: 218,
                  child: Text(
                    'Build now, pay later',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      height: 31 / 21,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 85,
                  width: 218,
                  child: Text(
                    'Get upto 50k - 25 Lakhs. 90 days\nrepayment period',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 18 / 12,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 133,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Get started',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF053961),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
