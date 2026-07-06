import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class HomeWhyChooseCard extends StatelessWidget {
  const HomeWhyChooseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.00, 0.50),
            end: Alignment(1.00, 0.50),
            colors: [Color(0xFF000A18), Color(0xFF838C99)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 12,
              child: SizedBox(
                width: 40,
                height: 52,
                child: SvgPicture.asset(
                  'assets/images/Whymob.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 52,
              top: 16,
              child: SizedBox(
                width: 165,
                child: Text(
                  'Why choose mad over\nbuildings?',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 22 / 15,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 26,
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/images/Arrow.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
