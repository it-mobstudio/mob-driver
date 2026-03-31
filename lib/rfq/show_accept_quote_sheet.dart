import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

Future<void> showAcceptQuoteSheet(
  BuildContext context, {
  required String quoteTitle,
  required int itemsCount,
  required num totalAmount,
  required String timeText,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 2)],
              ),
              child: Row(
                children: [
                  Text('Are you sure?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do you want to accept $quoteTitle for\n₹ ${totalAmount.toStringAsFixed(0)}?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once accepted all other quotes will be rejected.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6C7C8C),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quote summary card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6ECF2)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // top row
                        Row(
                          children: [
                            Text(quoteTitle,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(timeText,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6C7C8C))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Items: ',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF6C7C8C))),
                            Text('$itemsCount',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 16),
                            Text('Total: ',
                                style: GoogleFonts.inter(
                                    color: const Color(0xFF6C7C8C))),
                            Text('₹ ${totalAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120), // leaves space above CTA row
                ],
              ),
            ),

            // Bottom CTA row (fixed look)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 16, color: const Color(0xFF2563EB))),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: call accept API then pop or navigate
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                      ),
                      child: Text('Yes, Accept',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
