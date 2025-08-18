// lib/rfq/rfq_success_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/RFQ/RfqFormPage.dart';
import '../RFQ/rfq.dart';

class RfqSuccessPage extends StatelessWidget {
  const RfqSuccessPage({super.key});

  static const String routeName = 'RfqSuccessPage';
  static const String routePath = '/rfq/success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Green header block + illustration
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF13B77C),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.receipt_long,
                        size: 96, color: Colors.white.withOpacity(0.9)),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => GoRouter.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Thanks for submitting the RFQ!',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Our support member will get in touch with you within 24 hours. For further assistance please call @ +91 1234 567 890 or Whatsapp @ +91 1234 567 891. You can also reach us through mail at ask@madoverbuildings.com',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF6C7C8C)),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      context.goNamed(RfqPage.routeName);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('RFQ details'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        GoRouter.of(context).go(RfqFormPage.routePath),
                    child: const Text('Create new RFQ'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
