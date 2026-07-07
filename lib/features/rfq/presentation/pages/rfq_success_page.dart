import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'rfq.dart';

class RfqSuccessPage extends StatelessWidget {
  const RfqSuccessPage({super.key});

  static const String routeName = 'RfqSuccessPage';
  static const String routePath = '/rfq/success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Transform.translate(
                  offset: const Offset(0, -44),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/lottiejson/paymentsuccess.json',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quote requested',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Thanks! Our team will get back to you shortly with the final quote.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 14,
                          height: 21 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF0A243F)),
                onPressed: () => context.pop(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: OutlinedButton(
                  onPressed: () => context.goNamed(RfqPage.routeName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0865E8),
                    side: const BorderSide(color: Color(0xFF0865E8)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'View RFQ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
