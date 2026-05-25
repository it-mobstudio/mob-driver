import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/components/why_choose_mob.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class HomeRewardCard extends StatelessWidget {
  const HomeRewardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black54,
            useSafeArea: true,
            builder: (_) => const PromiseSheet(),
          ),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF232C64), Color(0xFF8373E4)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: SvgPicture.asset('assets/images/mobStar_Tick.svg'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Earn points on every order',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 22 / 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
