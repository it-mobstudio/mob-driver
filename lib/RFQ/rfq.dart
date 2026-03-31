import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

import 'rfq_details_page.dart';

// â”€â”€â”€ Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class RfqPage extends StatelessWidget {
  const RfqPage({super.key});
  static const routeName = 'RfqListPage';
  static const routePath = '/rfqs';

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      currentIndex: 3,
      showLocationheader: false,
      showBackButton: true,
      headerBackgroundColor: Color(0xFFE8F2EF),
      searchHintText: 'Search for product, category, brand..',
      child: _RfqBody(),
    );
  }
}

// â”€â”€â”€ Data Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _RfqStatus { requested, quotationGenerated, convertedToOrder }

class _RfqData {
  final String id;
  final String placedOn;
  final String amount;
  final _RfqStatus status;
  final int documents;
  final int quotations;

  const _RfqData({
    required this.id,
    required this.placedOn,
    required this.amount,
    required this.status,
    required this.documents,
    required this.quotations,
  });

  String get statusLabel => switch (status) {
        _RfqStatus.requested => 'Requested',
        _RfqStatus.quotationGenerated => 'Quotation generated',
        _RfqStatus.convertedToOrder => 'Converted to order',
      };
}

// â”€â”€â”€ Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RfqBody extends StatelessWidget {
  const _RfqBody();

  static const _items = <_RfqData>[
    _RfqData(
      id: 'MOB9867855HJS6',
      placedOn: 'Placed on: 30 Jan 2022',
      amount: 'â‚¹ 31250',
      status: _RfqStatus.quotationGenerated,
      documents: 1,
      quotations: 2,
    ),
    _RfqData(
      id: 'MOB9867855HJS6',
      placedOn: 'Placed on: 30 Jan 2022',
      amount: 'â‚¹ 31250',
      status: _RfqStatus.requested,
      documents: 1,
      quotations: 0,
    ),
    _RfqData(
      id: 'MOB9867855HJS6',
      placedOn: 'Placed on: 30 Jan 2022',
      amount: 'â‚¹ 31250',
      status: _RfqStatus.requested,
      documents: 1,
      quotations: 0,
    ),
    _RfqData(
      id: 'MOB9867855HJS6',
      placedOn: 'Placed on: 30 Jan 2022',
      amount: 'â‚¹ 31250',
      status: _RfqStatus.convertedToOrder,
      documents: 1,
      quotations: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Quotation request',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A243F),
              height: 28 / 19,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Inline search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 3),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, size: 18, color: Color(0xFF6C7C8C)),
                const SizedBox(width: 8),
                Text(
                  "Search all RFQ's",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C7C8C),
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sort chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDEDEDE)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort by',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: Color(0xFF0A243F),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // List
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF0F0F0),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RfqCard(item: _items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RfqCard extends StatelessWidget {
  final _RfqData item;
  const _RfqCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasButton = item.quotations > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID + amount
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.id,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                Text(
                  item.amount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),

          // Placed on
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              item.placedOn,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF67696D),
              ),
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5, color: Color(0xFFD0D4DC)),
          ),

          // Status row (tappable)
          GestureDetector(
            onTap: () => context.push(RfqDetailsPage.routePath),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A243F),
                            height: 22 / 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.documents} document attached',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF67696D),
                            height: 18 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF0A243F),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // CTA buttons
          if (hasButton) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (item.status == _RfqStatus.convertedToOrder) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFDEDEDE), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'View order',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A243F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push(RfqDetailsPage.routePath),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0360E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'View ${item.quotations} ${item.quotations == 1 ? 'quotation' : 'quotations'}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
