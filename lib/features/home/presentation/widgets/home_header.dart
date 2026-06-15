import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 14,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/thunder.svg',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '1-4 hrs delivery',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 28 / 19,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Home',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 14,
                        ),
                        Expanded(
                          child: Text(
                            ' - Magarpatta Inner Circle, Magarpatta',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 18 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.push(ReferralPage.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD0D4DC)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.card_giftcard_outlined,
                    size: 19,
                    color: Color(0xFF0A243F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push(MyAccountWidget.routePath),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFD0D4DC)),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/profile.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD0D4DC),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/Searchicon.svg',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search "Fevicol"',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF767C8F),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // const Icon(
                  //   Icons.mic_none,
                  //   color: Color(0xFF767C8F),
                  //   size: 20,
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
