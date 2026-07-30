import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_page.dart';

class HomeMagicQuoteCard extends StatelessWidget {
  const HomeMagicQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(MagicAiQuotePage.routePath),
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
                  colors: [Color(0xFF0B3D24), Color(0xFF123321)],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        'assets/images/Magicquoteappimage.webp',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    width: 175,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Magic AI quote',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFD84D),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 26 / 20,
                            ),
                          ),
                        ),
                        // const SizedBox(width: 2),
                        SvgPicture.asset(
                          'assets/images/magicquote-star.svg',
                          width: 18,
                          height: 18,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 44,
                    width: 190,
                    child: Text(
                      'in 60 secs',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFD84D),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 26 / 20,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 88,
                    width: 190,
                    child: Text(
                      'Share your requirement\n(Handwritten/ typed)',
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
                    child: InkWell(
                      onTap: () => context.push(MagicAiQuotePage.routePath),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Quote request (RFQ)',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0B3D24),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 18 / 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
