import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

class ReviewSuccessScreen extends StatelessWidget {
  const ReviewSuccessScreen({
    super.key,
    required this.rfqNumber,
    required this.onBackHome,
    required this.onViewRfqs,
  });

  final String rfqNumber;
  final VoidCallback onBackHome;
  final VoidCallback onViewRfqs;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF169B58),
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'RFQ submitted for review',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thanks! Our team will get back to you shortly with the final quote.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (rfqNumber.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MagicQuoteColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Your RFQ number',
                  style: GoogleFonts.inter(
                      color: MagicQuoteColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  rfqNumber,
                  style: GoogleFonts.inter(
                      color: MagicQuoteColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        MagicQuoteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What happens next',
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow(
                  'The MOB team will review your details to find the best price'),
              _infoRow('Final quote will be shared via WhatsApp & email'),
              _infoRow('Accept quote and pay to place your order',
                  isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onBackHome,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: MagicQuoteColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Back to homepage',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: onViewRfqs,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MagicQuoteColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'View my RFQs',
              style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF169B58), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
