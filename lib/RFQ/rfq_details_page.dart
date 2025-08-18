import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/RFQ/showAcceptQuoteSheet.dart';

class RfqDetailsPage extends StatelessWidget {
  const RfqDetailsPage({super.key});

  static const routeName = 'RfqDetailsPage';
  static const routePath = '/rfq-details';

  @override
  Widget build(BuildContext context) {
    final mint = const Color(0xFFE9F4F1);
    final border = const Color(0xFFE6ECF2);
    final ink = const Color(0xFF0A243F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(height: 112, color: mint), // mint header tint
          SafeArea(
            child: Column(
              children: [
                // Top search row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for product, category, brand…',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF2F6F9),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _circleIcon(Icons.mic_none),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    children: [
                      // RFQ id + status + placed on
                      Text('RFQ_000000101',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statusPill('Quotation generated'),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Placed on: 6 Feb 2022, 10:32am',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFF6C7C8C))),
                      const SizedBox(height: 16),

                      Text('MOB Quotes',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      // Quote 1 (no comments)
                      _quoteCard(
                        title: 'Quote 1',
                        time: 'Today, 10:24 am',
                        items: 2,
                        total: 10800,
                        showComments: false,
                        onAccept: () {
                          showAcceptQuoteSheet(
                            context,
                            quoteTitle: 'Quote 1',
                            itemsCount: 8,
                            totalAmount: 31250,
                            timeText: 'Today, 10:24 am',
                          );
                        },
                        onViewQuotation: () {},
                      ),
                      const SizedBox(height: 12),

                      // Quote 2 (with comments block)
                      _quoteCard(
                        title: 'Quote 2',
                        time: 'Today, 10:24 am',
                        items: 2,
                        total: 10800,
                        showComments: true,
                        onAccept: () {
                          showAcceptQuoteSheet(
                            context,
                            quoteTitle: 'Quote 1',
                            itemsCount: 8,
                            totalAmount: 31250,
                            timeText: 'Today, 10:24 am',
                          );
                        },
                        onViewQuotation: () {},
                      ),
                      const SizedBox(height: 16),

                      // Requested tracker + attachments + comments
                      _requestedBlock(border),

                      const SizedBox(height: 20),

                      // Customer info
                      _customerInfo(),

                      const SizedBox(height: 12),

                      // GST row
                      _gstRow(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- small widgets ----------

  static Widget _circleIcon(IconData icon) => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE9EEF3),
        ),
        child: Icon(icon, color: Colors.black87),
      );

  static Widget _statusPill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF5FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12, color: const Color(0xFF2563EB))),
      );

  static Widget _quoteCard({
    required String title,
    required String time,
    required int items,
    required int total,
    required bool showComments,
    required VoidCallback onAccept,
    required VoidCallback onViewQuotation,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6ECF2)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(time,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF6C7C8C))),
                        const SizedBox(height: 8),
                        Text('Items:  $items',
                            style: GoogleFonts.inter(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('Total:  ₹ $total',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ]),
                ),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text('Accept quote',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (showComments)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comments',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                      'Curabitur vel massa aliquet, commodo lacus egestas, '
                      'tincidunt massa. Maecenas nibh diam, tempor at metus dapibus.',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ]),
            ),
          const Divider(height: 1),
          InkWell(
            onTap: onViewQuotation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text('View quotation',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _requestedBlock(Color border) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requested',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                Text('You will receive a quotation from our side within 24 hrs',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6C7C8C))),
              ],
            ),
          ),
          // Progress (1/4)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                _stepDot(active: true),
                _stepLine(),
                _stepDot(),
                _stepLine(),
                _stepDot(),
                _stepLine(),
                _stepDot(),
              ],
            ),
          ),
          const Divider(height: 1),

          // Files
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2 items',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                _fileTile('Marriot materials requirements.pdf'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Comments
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comments',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Curabitur vel massa aliquet, commodo lacus egestas.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _stepDot({bool active = false}) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF0A243F) : const Color(0xFFE9EEF3),
          border: Border.all(
              color:
                  active ? const Color(0xFF0A243F) : const Color(0xFFD8E0E8)),
        ),
        child: active
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : null,
      );

  static Widget _stepLine() => Expanded(
        child: Container(
          height: 3,
          color: const Color(0xFFE9EEF3),
        ),
      );

  static Widget _fileTile(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined,
                color: Color(0xFF0A243F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: GoogleFonts.inter(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  static Widget _customerInfo() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Johnnathan Wick',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text('8655426554', style: GoogleFonts.inter(fontSize: 13)),
          const SizedBox(height: 4),
          Text('johnwick@gmail.com',
              style: GoogleFonts.inter(
                  fontSize: 13, decoration: TextDecoration.underline)),
          const SizedBox(height: 6),
          Text('RFQ details will be sent to this phone number and email',
              style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF6C7C8C))),
        ],
      );

  static Widget _gstRow() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text('Forgot to add GST?',
                    style: GoogleFonts.inter(fontSize: 13))),
            Text('Request to add',
                style: GoogleFonts.inter(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
