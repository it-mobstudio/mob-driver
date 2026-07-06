import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

Future<bool?> showAcceptQuoteSheet(
  BuildContext context, {
  required String quoteTitle,
  required int itemsCount,
  required num totalAmount,
  required String timeText,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) {
      return _AcceptQuoteSheet(
        quoteTitle: quoteTitle,
        itemsCount: itemsCount,
        totalAmount: totalAmount,
        timeText: timeText,
      );
    },
  );
}

class _AcceptQuoteSheet extends StatelessWidget {
  const _AcceptQuoteSheet({
    required this.quoteTitle,
    required this.itemsCount,
    required this.totalAmount,
    required this.timeText,
  });

  final String quoteTitle;
  final int itemsCount;
  final num totalAmount;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 504,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do you want to accept ${quoteTitle.toLowerCase()} for\n\u20B9 ${totalAmount.toStringAsFixed(0)}?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A243F),
                      height: 30 / 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once accepted all other quotes will be rejected.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0A243F),
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AcceptQuoteSummary(
                    quoteTitle: quoteTitle,
                    itemsCount: itemsCount,
                    totalAmount: totalAmount,
                    timeText: timeText,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 38,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0360E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 21 / 14,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F6F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF0A243F),
                    size: 20,
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

class _AcceptQuoteSummary extends StatelessWidget {
  const _AcceptQuoteSummary({
    required this.quoteTitle,
    required this.itemsCount,
    required this.totalAmount,
    required this.timeText,
  });

  final String quoteTitle;
  final int itemsCount;
  final num totalAmount;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quoteTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ),
              Text(
                timeText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6C7C8C),
                  height: 18 / 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _SummaryMetric(label: 'Items:', value: itemsCount.toString()),
              const SizedBox(width: 32),
              _SummaryMetric(
                label: 'Total:',
                value: '\u20B9 ${totalAmount.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6C7C8C),
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0A243F),
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}
