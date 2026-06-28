import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

/// "Uh oh, our AI hit a snag" screen, shown when the Magic Quote backend
/// couldn't auto-generate a quote and the request needs manual review.
/// Mirrors the web's MagicQuote/UnreadScreen.jsx.
class UnreadScreen extends StatelessWidget {
  const UnreadScreen({
    super.key,
    required this.quoteId,
    required this.rfqNumber,
    required this.city,
    required this.pincode,
    required this.hasUploadsContext,
    required this.onShowUploadsViewer,
    required this.onOpenWhatsApp,
  });

  final String quoteId;
  final String rfqNumber;
  final String city;
  final String pincode;
  final bool hasUploadsContext;
  final VoidCallback onShowUploadsViewer;
  final VoidCallback onOpenWhatsApp;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        MagicQuoteTopCard(
          title: quoteId.isEmpty ? 'Quote' : 'Quote $quoteId',
          status: 'Under review',
          rfqNumber: rfqNumber,
          city: city,
          pincode: pincode,
          hasUploadsContext: hasUploadsContext,
          onShowUploads: onShowUploadsViewer,
        ),
        const SizedBox(height: 14),
        MagicQuoteCard(child: _snagMessage()),
        const SizedBox(height: 14),
        _needHelpCard(),
      ],
    );
  }

  Widget _needHelpCard() {
    return MagicQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MagicQuoteSectionTitle('Need help?'),
          const SizedBox(height: 6),
          Text(
            "Chat with our team and we'll get your list reviewed quickly.",
            style: GoogleFonts.inter(
              color: MagicQuoteColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onOpenWhatsApp,
              icon: const Icon(Icons.chat_bubble, size: 18),
              label: Text(
                'Chat with us',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF1EAD66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snagMessage() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/magic-quote-unread-snag.svg',
          width: 192,
          height: 120,
        ),
        const SizedBox(height: 14),
        Text(
          'Uh oh, our AI hit a snag',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Don't worry, your request is sent. Our team will review "
          "your list manually and reach out shortly!",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.muted,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
