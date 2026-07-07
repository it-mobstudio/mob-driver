import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';

class HomeRewardCard extends StatelessWidget {
  const HomeRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: () => context.push(MobstarPage.routePath),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.00, 0.50),
              end: Alignment(1.00, 0.50),
              colors: [Color(0xFF232C64), Color(0xFF8373E4)],
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
                    'assets/images/mobstarcoin.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: 52,
                top: 17,
                child: SizedBox(
                  width: 80,
                  height: 14,
                  child: SvgPicture.asset(
                    'assets/images/mobstar logo.svg',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              Positioned(
                left: 52,
                top: 37,
                child: SizedBox(
                  width: 207,
                  child: Text(
                    'Earn points on every order',
                    maxLines: 1,
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
                    'assets/images/RoundArrow.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
