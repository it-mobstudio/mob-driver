import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/quote_item_row.dart';
import 'package:m_o_b_demand_side/shared/image_url.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({
    super.key,
    required this.payload,
    required this.city,
    required this.pincode,
    required this.hasUploadsContext,
    required this.addingProductSku,
    required this.quantityOf,
    required this.onQuantityChange,
    required this.onDeleteItem,
    required this.onChangeItem,
    required this.onShowAddMoreItems,
    required this.onAddRecommended,
    required this.onShowUploadsViewer,
    required this.onShowHelp,
  });

  final Map<String, dynamic> payload;
  final String city;
  final String pincode;
  final bool hasUploadsContext;
  final String addingProductSku;
  final num Function(Map<String, dynamic> item) quantityOf;
  final void Function(Map<String, dynamic> item, bool increase)
      onQuantityChange;
  final void Function(Map<String, dynamic> item) onDeleteItem;
  final void Function(Map<String, dynamic> item) onChangeItem;
  final void Function(String quoteId) onShowAddMoreItems;
  final void Function(String sku) onAddRecommended;
  final VoidCallback onShowUploadsViewer;
  final VoidCallback onShowHelp;

  @override
  Widget build(BuildContext context) {
    final quote = mapValueOf(payload, 'quote');
    final rfqOrder = mapValueOf(payload, 'rfq_order');
    final items = itemsOf(payload);
    final total = moneyValueOf(quote, const ['total', 'grand_total']);
    final subtotal = moneyValueOf(quote, const ['sub_total', 'subtotal']);
    final savings = moneyValueOf(quote, const ['discount']);
    final tax = moneyValueOf(quote, const ['sgst']) +
        moneyValueOf(quote, const ['cgst']);
    final quoteId = stringValueOf(quote, const ['id', 'quote_id']);
    final quoteTitle = quoteId.isEmpty ? 'Quote' : 'Quote $quoteId';
    final rfqNumber = stringValueOf(rfqOrder, const ['rfq_id', 'id']);

    final noMatchNumbers = <int>[];
    for (var i = 0; i < items.length; i++) {
      if (items[i]['is_product_available'] == false) {
        final index = moneyValueOf(items[i], const ['index']);
        noMatchNumbers.add(index > 0 ? index.toInt() : i + 1);
      }
    }
    final noMatchList = noMatchNumbers.isEmpty
        ? ''
        : noMatchNumbers.length > 1
            ? '${noMatchNumbers.sublist(0, noMatchNumbers.length - 1).join(", ")} and ${noMatchNumbers.last}'
            : '${noMatchNumbers.first}';

    final recommended = _recommendedProducts(payload, items);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          children: [
            MagicQuoteTopCard(
              title: quoteTitle,
              status: stringValueOf(quote, const ['quote_status']).isEmpty
                  ? 'Draft'
                  : stringValueOf(quote, const ['quote_status']),
              rfqNumber: rfqNumber,
              city: city,
              pincode: pincode,
              showAiDisclaimer: false,
              hasUploadsContext: hasUploadsContext,
              onShowUploads: onShowUploadsViewer,
            ),
            const SizedBox(height: 14),
            _heroTotalCard(
                total: total, savings: savings, itemCount: items.length),
            if (noMatchNumbers.isNotEmpty) ...[
              const SizedBox(height: 14),
              _noMatchBanner(count: noMatchNumbers.length, list: noMatchList),
            ],
            const SizedBox(height: 14),
            _aiDisclaimerOrderNoteBlock(),
            const SizedBox(height: 14),
            _addMoreItemsButton(quoteId),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const MagicQuoteCard(
                child: MagicQuoteEmptyMessage(
                  icon: Icons.search_off,
                  title: 'No matched items',
                  text:
                      'Your request was created, but no product match was returned.',
                ),
              )
            else
              ...items.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QuoteItemRow(
                    item: entry.$2,
                    idx: entry.$1,
                    quantity: quantityOf(entry.$2),
                    onQuantityChange: onQuantityChange,
                    onDelete: onDeleteItem,
                    onChange: onChangeItem,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            _addMoreItemsButton(quoteId),
            if (recommended.isNotEmpty) ...[
              const SizedBox(height: 18),
              _recommendedProductsSection(recommended),
            ],
            const SizedBox(height: 18),
            _quoteDetailsCard(
                subtotal: subtotal, tax: tax, savings: savings, total: total),
            const SizedBox(height: 14),
            _pointsStrip(items.length * 10),
            const SizedBox(height: 14),
            _saveForLaterNote(context),
            const SizedBox(height: 14),
            _nextStepsCard(),
          ],
        ),
        Positioned(right: 16, bottom: 16, child: _helpFab()),
      ],
    );
  }

  Widget _heroTotalCard({
    required num total,
    required num savings,
    required int itemCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF012D0E), Color(0xFF007937)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Check for wrong or missing SKU's & Qty",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFE600),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED TOTAL',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatInr(total),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Incl. GST',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$itemCount items',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFE600), Color(0xFFFFB800)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sell,
                        size: 16, color: MagicQuoteColors.navy),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      text: "You're saving ",
                      style:
                          GoogleFonts.inter(color: Colors.white, fontSize: 12),
                      children: [
                        TextSpan(
                          text: formatInr(savings),
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFE600),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noMatchBanner({required int count, required String list}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFAD7D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE14040),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                count == 1
                    ? '1 item match not found'
                    : '$count items match not found',
                style: GoogleFonts.inter(
                  color: const Color(0xFFB3261E),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Match not found for item no $list. Don't worry! Please submit "
            'and our team will be in touch.',
            style: GoogleFonts.inter(
              color: const Color(0xFF8A3A3A),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiDisclaimerOrderNoteBlock() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF6E2C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: MagicQuoteAiDisclaimerRow(),
          ),
          Container(height: 1, color: const Color(0xFFF0E0C0)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/mob_team.webp',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our team will get in touch for final quotation',
                        style: GoogleFonts.inter(
                          color: MagicQuoteColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please add note and submit for review',
                        style: GoogleFonts.inter(
                            color: MagicQuoteColors.muted, fontSize: 12.5),
                      ),
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

  Widget _addMoreItemsButton(String quoteId) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => onShowAddMoreItems(quoteId),
        icon: const Icon(Icons.add, size: 18, color: MagicQuoteColors.blue),
        label: Text(
          'Add more items',
          style: GoogleFonts.inter(
            color: MagicQuoteColors.blue,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: MagicQuoteColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _recommendedProducts(
    Map<String, dynamic> payload,
    List<Map<String, dynamic>> items,
  ) {
    final recommendations = payload['recommended_products'];
    if (recommendations is! List) return const [];

    final quoteSkus = items
        .map((item) => firstNonEmptyOf([
              stringValueOf(item, const ['mob_sku', 'sku']),
              stringValueOf(
                  mapValueOf(item, 'product'), const ['mob_sku', 'sku']),
            ]))
        .where((sku) => sku.isNotEmpty)
        .toSet();

    return recommendations
        .whereType<Map>()
        .map((raw) {
          final entry = Map<String, dynamic>.from(raw);
          final product = entry['product'] is Map
              ? Map<String, dynamic>.from(entry['product'] as Map)
              : entry;
          final sku = firstNonEmptyOf([
            stringValueOf(product, const ['mob_sku']),
            stringValueOf(entry, const ['mob_sku', 'sku']),
          ]);
          if (sku.isEmpty) return null;
          final name = firstNonEmptyOf([
            stringValueOf(product, const ['product_name', 'name']),
            stringValueOf(entry, const ['product_name']),
          ]);
          final price = moneyValueOf(entry, const ['price_after_tax']) > 0
              ? moneyValueOf(entry, const ['price_after_tax'])
              : moneyValueOf(product, const ['price_after_tax']);
          return {
            'mob_sku': sku,
            'isAdded': quoteSkus.contains(sku),
            'name': name.isEmpty ? 'Recommended product' : name,
            'img': sanitizeImageUrl(firstNonEmptyOf([
              stringValueOf(product, const ['product_image', 'image']),
              stringValueOf(entry, const ['product_image']),
            ])),
            'price': price,
            'unit': firstNonEmptyOf([
              stringValueOf(entry, const ['unit']),
              stringValueOf(product, const ['unit']),
            ]),
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Widget _recommendedProductsSection(List<Map<String, dynamic>> recommended) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFB8893A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Would you also like to add this?',
                    style: GoogleFonts.inter(
                      color: MagicQuoteColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Common items others added with this list',
                    style: GoogleFonts.inter(
                        color: MagicQuoteColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _recommendationCard(recommended[index]),
          ),
        ),
      ],
    );
  }

  Widget _recommendationCard(Map<String, dynamic> item) {
    final sku = item['mob_sku'] as String;
    final isAdded = item['isAdded'] == true;
    final name = item['name'] as String;
    final img = item['img'] as String;
    final price = item['price'] as num;
    final unit = item['unit'] as String;
    final isAdding = addingProductSku == sku;

    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MagicQuoteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 84,
                  width: double.infinity,
                  color: const Color(0xFFF7F9FC),
                  child: img.isEmpty
                      ? const Icon(Icons.inventory_2_outlined,
                          color: MagicQuoteColors.navy)
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              color: MagicQuoteColors.navy),
                        ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  onTap:
                      isAdded || isAdding ? null : () => onAddRecommended(sku),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAdded ? const Color(0xFF01A685) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAdded
                            ? const Color(0xFF01A685)
                            : MagicQuoteColors.blue,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      isAdded ? '✓ Added' : (isAdding ? '...' : '+ Add'),
                      style: GoogleFonts.inter(
                        color: isAdded ? Colors.white : MagicQuoteColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MagicQuoteColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: formatInr(price),
              style: GoogleFonts.inter(
                color: MagicQuoteColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' / $unit',
                    style: GoogleFonts.inter(
                        color: MagicQuoteColors.muted, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteDetailsCard({
    required num subtotal,
    required num tax,
    required num savings,
    required num total,
  }) {
    return MagicQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MagicQuoteSectionTitle('Quote details'),
          const SizedBox(height: 12),
          MagicQuoteSummaryRow('Subtotal', subtotal),
          MagicQuoteSummaryRow('Total tax', tax),
          MagicQuoteSummaryRow('Savings', savings,
              valueColor: const Color(0xFF169B58)),
          const Divider(height: 24),
          MagicQuoteSummaryRow('Estimated total', total, strong: true),
        ],
      ),
    );
  }

  Widget _pointsStrip(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFE9A23B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'You will earn ',
                style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$points points',
                    style: GoogleFonts.inter(
                        color: MagicQuoteColors.navy,
                        fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' on this purchase'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveForLaterNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MagicQuoteColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F0FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_outline,
                color: MagicQuoteColors.blue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    color: MagicQuoteColors.muted, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(
                    text: 'Not ready to order? ',
                    style: GoogleFonts.inter(
                        color: MagicQuoteColors.navy,
                        fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                      text: 'No worries. Find this quote anytime in '),
                  TextSpan(
                    text: 'My RFQs',
                    style: GoogleFonts.inter(
                        color: MagicQuoteColors.blue,
                        fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/rfqs'),
                  ),
                  const TextSpan(text: ' in your account.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepsCard() {
    const steps = [
      'MOB team will review upon submission',
      'Delivery cost might be added',
      'Final quote will be shared after availability check',
    ];
    return MagicQuoteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MagicQuoteSectionTitle('Next steps'),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.inter(
                          color: MagicQuoteColors.navy, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _helpFab() {
    return FloatingActionButton(
      heroTag: 'magic-quote-help',
      onPressed: onShowHelp,
      backgroundColor: MagicQuoteColors.navy,
      child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
    );
  }
}
