import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'rfq_details_page.dart'; // if you navigate to details

// ---- Mock model -------------------------------------------------------------
class RfqItem {
  final String id;
  final String placedOn;
  final int amount;
  final String status; // Requested / Quotation generated / Converted to order
  final int documents;
  final int quotations;
  final bool convertedToOrder;
  const RfqItem({
    required this.id,
    required this.placedOn,
    required this.amount,
    required this.status,
    required this.documents,
    required this.quotations,
    this.convertedToOrder = false,
  });
}

// ---- Page -------------------------------------------------------------------
class RfqPage extends StatefulWidget {
  const RfqPage({super.key});
  static const routeName = 'RfqListPage';
  static const routePath = '/rfqs';

  @override
  State<RfqPage> createState() => _RfqListPageState();
}

class _RfqListPageState extends State<RfqPage> {
  final TextEditingController _headerSearch = TextEditingController();
  final TextEditingController _inlineSearch = TextEditingController();

  final items = const <RfqItem>[
    RfqItem(
      id: 'MOB8967855HJS6',
      placedOn: '2022, 1, 30',
      amount: 31250,
      status: 'Quotation generated',
      documents: 1,
      quotations: 2,
    ),
    RfqItem(
      id: 'MOB8967855HJS6',
      placedOn: '2022, 1, 30',
      amount: 31250,
      status: 'Requested',
      documents: 1,
      quotations: 0,
    ),
    RfqItem(
      id: 'MOB8967855HJS6',
      placedOn: '2022, 1, 30',
      amount: 31250,
      status: 'Requested',
      documents: 1,
      quotations: 0,
    ),
    RfqItem(
      id: 'MOB8967855HJS6',
      placedOn: '2022, 1, 30',
      amount: 31250,
      status: 'Converted to order',
      documents: 1,
      quotations: 2,
      convertedToOrder: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final mint = const Color(0xFFE9F4F1); // header tint
    final ink = const Color(0xFF0A243F);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mint header background
          Container(height: 112, color: mint),
          SafeArea(
            child: Column(
              children: [
                // Top search bar row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                          child: _searchField(_headerSearch,
                              hint: 'Search for product, category, brand…',
                              dense: true)),
                      const SizedBox(width: 8),
                      _iconCircle(Icons.mic_none),
                    ],
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Quotation request',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                  ),
                ),

                // Inline RFQ search + sort
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _searchField(_inlineSearch,
                            hint: "Search all RFQ's"),
                      ),
                      const SizedBox(width: 12),
                      _sortButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // List
                Expanded(
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _rfqCard(context, items[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Widgets --------------------------------------------------------------

  Widget _searchField(TextEditingController c,
      {required String hint, bool dense = false}) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: dense,
        filled: true,
        fillColor: const Color(0xFFF2F6F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE9EEF3),
      ),
      child: Icon(icon, color: Colors.black87),
    );
  }

  Widget _sortButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.sort, size: 18),
      label: const Text('Sort by'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: const BorderSide(color: Color(0xFFE3E8EF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _rfqCard(BuildContext context, RfqItem it) {
    final subtle = const Color(0xFFF2F6F9);
    final border = const Color(0xFFE8EEF5);
    final title = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600);
    final small =
        GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6C7C8C));

    return Container(
      decoration: BoxDecoration(
        color: subtle,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            // Header row (id + amount)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.id,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A4B5B))),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on: ${_fmtDate(it.placedOn)}',
                          style: small,
                        ),
                      ],
                    ),
                  ),
                  Text('₹ ${it.amount}',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Status row
            InkWell(
              onTap: () {
                context.go(
                    '/rfq-details'); // or context.goNamed(RfqDetailsPage.routeName)
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.status, style: title),
                            const SizedBox(height: 4),
                            Text(
                              '${it.documents} document attached',
                              style: small,
                            ),
                          ]),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
              ),
            ),

            // Bottom CTA row (varies)
            if (it.convertedToOrder || it.quotations > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    if (it.convertedToOrder) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('View order'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go(RfqDetailsPage.routePath),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: Text(
                          'View ${it.quotations} ${it.quotations == 1 ? 'quotation' : 'quotations'}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String date) {
    final parts = date.split(', ');
    if (parts.length != 3) return date;

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    final day = int.tryParse(parts[2]) ?? 0;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateObj = DateTime(year, month, day);
    return '${dateObj.day} ${months[dateObj.month - 1]} ${dateObj.year}';
  }
}
