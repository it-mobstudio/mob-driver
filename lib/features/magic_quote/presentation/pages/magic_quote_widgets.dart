import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';

abstract final class MagicQuoteColors {
  static const navy = AppColors.primaryText;
  static const blue = Color(0xFF0968E8);
  static const muted = Color(0xFF687482);
  static const border = Color(0xFFE3E8EF);
  static const bg = Color(0xFFF5F7FA);
}

/// White, rounded, lightly-shadowed card — the base container reused by
/// almost every Magic Quote section.
class MagicQuoteCard extends StatelessWidget {
  const MagicQuoteCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAF0F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MagicQuoteSectionTitle extends StatelessWidget {
  const MagicQuoteSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: MagicQuoteColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class MagicQuoteSummaryRow extends StatelessWidget {
  const MagicQuoteSummaryRow(
    this.label,
    this.value, {
    super.key,
    this.strong = false,
    this.valueColor,
  });

  final String label;
  final num value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: strong ? MagicQuoteColors.navy : MagicQuoteColors.muted,
                fontSize: strong ? 16 : 14,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatInr(value),
            style: GoogleFonts.inter(
              color: valueColor ?? MagicQuoteColors.navy,
              fontSize: strong ? 16 : 14,
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MagicQuoteEmptyMessage extends StatelessWidget {
  const MagicQuoteEmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF2FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: MagicQuoteColors.blue, size: 32),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: MagicQuoteColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
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

class MagicQuoteAiDisclaimerRow extends StatelessWidget {
  const MagicQuoteAiDisclaimerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFE9A23B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'This is AI generated and can have mistakes',
            style: GoogleFonts.inter(
              color: MagicQuoteColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class MagicQuoteUploadsSummaryRow extends StatelessWidget {
  const MagicQuoteUploadsSummaryRow({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MagicQuoteColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.attachment,
                color: MagicQuoteColors.navy, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your uploads',
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'View',
              style: GoogleFonts.inter(
                color: MagicQuoteColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: MagicQuoteColors.blue),
          ],
        ),
      ),
    );
  }
}

/// Quote header card: title + status pill, RFQ number, location, optional
/// "Your uploads" row, optional AI disclaimer. Shared by ResultsScreen and
/// UnreadScreen, mirroring the duplicated `quote-top` markup in the web's
/// ResultsScreen.jsx / UnreadScreen.jsx.
class MagicQuoteTopCard extends StatelessWidget {
  const MagicQuoteTopCard({
    super.key,
    required this.title,
    required this.status,
    required this.rfqNumber,
    required this.city,
    required this.pincode,
    this.showAiDisclaimer = true,
    this.hasUploadsContext = false,
    this.onShowUploads,
  });

  final String title;
  final String status;
  final String rfqNumber;
  final String city;
  final String pincode;
  final bool showAiDisclaimer;
  final bool hasUploadsContext;
  final VoidCallback? onShowUploads;

  @override
  Widget build(BuildContext context) {
    return MagicQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'Under review'
                      ? const Color(0xFFFFF4E4)
                      : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: status == 'Under review'
                        ? const Color(0xFF9B5C00)
                        : MagicQuoteColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (rfqNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              rfqNumber,
              style: GoogleFonts.inter(
                  color: MagicQuoteColors.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: MagicQuoteColors.muted, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  [city, pincode].where((part) => part.isNotEmpty).join(' - '),
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (hasUploadsContext && onShowUploads != null) ...[
            const SizedBox(height: 12),
            MagicQuoteUploadsSummaryRow(onTap: onShowUploads!),
          ],
          if (showAiDisclaimer) ...[
            const SizedBox(height: 12),
            const MagicQuoteAiDisclaimerRow(),
          ],
        ],
      ),
    );
  }
}
