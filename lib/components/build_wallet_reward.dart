import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class WalletRewardBanner extends StatelessWidget {
  const WalletRewardBanner({
    super.key,
    this.amount = 1000,
  });

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEA94).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/coin.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '\u20B9$amount',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 14 / 12,
                ),
                children: [
                  TextSpan(
                    text: ' will be added to mobwallet',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 14 / 12,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
