import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/shared/main_scaffold.dart';

import 'rfq_details_page.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class RfqPage extends StatefulWidget {
  const RfqPage({super.key});
  static const routeName = 'RfqListPage';
  static const routePath = '/rfqs';

  @override
  State<RfqPage> createState() => _RfqPageState();
}

class _RfqPageState extends State<RfqPage> {
  late final RfqBloc _rfqBloc;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>()..add(RfqListRequested());
  }

  @override
  void dispose() {
    _rfqBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: const MainScaffold(
        currentIndex: -1,
        showLocationheader: false,
        showBackButton: true,
        headerBackgroundColor: Color(0xFFE8F2EF),
        searchHints: ['Search for product, category, brand..'],
        child: _RfqBody(),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _RfqBody extends StatelessWidget {
  const _RfqBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Expanded(
          child: BlocBuilder<RfqBloc, RfqState>(
            builder: (context, state) {
              return switch (state) {
                RfqInitial() ||
                RfqLoading() =>
                  const Center(child: CircularProgressIndicator()),
                RfqError(:final message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6C7C8C),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                RfqListLoaded(:final rfqs) when rfqs.isEmpty => Center(
                    child: Text(
                      "No RFQ's yet.",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6C7C8C),
                        fontSize: 14,
                      ),
                    ),
                  ),
                RfqListLoaded(:final rfqs) => ColoredBox(
                    color: const Color(0xFFF0F0F0),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: rfqs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RfqCard(item: rfqs[index]),
                        );
                      },
                    ),
                  ),
                _ => const SizedBox.shrink(),
              };
            },
          ),
        ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

enum _RfqDisplayStatus { requested, quotationGenerated, convertedToOrder }

extension _RfqDisplayStatusX on _RfqDisplayStatus {
  String get label => switch (this) {
        _RfqDisplayStatus.requested => 'Requested',
        _RfqDisplayStatus.quotationGenerated => 'Quotation generated',
        _RfqDisplayStatus.convertedToOrder => 'Converted to order',
      };
}

_RfqDisplayStatus _parseStatus(String raw) {
  final s = raw.toLowerCase().replaceAll(' ', '_');
  if (s.contains('quotation')) return _RfqDisplayStatus.quotationGenerated;
  if (s.contains('order')) return _RfqDisplayStatus.convertedToOrder;
  return _RfqDisplayStatus.requested;
}

class _RfqCard extends StatelessWidget {
  final RfqEntity item;
  const _RfqCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final displayStatus = _parseStatus(item.status);
    final hasQuotation = displayStatus != _RfqDisplayStatus.requested;

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
                  '₹ ${item.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              'Placed on: ${item.createdAt}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF67696D),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5, color: Color(0xFFD0D4DC)),
          ),

          GestureDetector(
            onTap: () => context.push(
              RfqDetailsPage.routePath,
              extra: item.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayStatus.label,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0A243F),
                            height: 22 / 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.items.length} ${item.items.length == 1 ? 'item' : 'items'}',
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

          if (hasQuotation) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (displayStatus == _RfqDisplayStatus.convertedToOrder) ...[
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
                      onPressed: () => context.push(
                        RfqDetailsPage.routePath,
                        extra: item.id,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0360E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'View quotation',
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
