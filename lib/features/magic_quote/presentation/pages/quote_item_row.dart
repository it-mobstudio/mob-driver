import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_utils.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

/// Mirrors the web's `getItemSku`: the mob_sku used to look up swap
/// candidates for [item].
String magicQuoteItemSku(Map<String, dynamic> item) {
  final product = mapValueOf(item, 'product');
  return firstNonEmptyOf([
    stringValueOf(product, const ['mob_sku', 'MOBSKU', 'sku']),
    stringValueOf(item, const ['mob_sku', 'MOBSKU', 'sku']),
  ]);
}

({String label, String kind}) _quoteItemStatus(Map<String, dynamic> item) {
  if (item['is_product_available'] == false) {
    final label = stringValueOf(item, const ['status_label']);
    return (
      label: label.isEmpty ? 'No match found' : label,
      kind: 'not-matched'
    );
  }

  final product = mapValueOf(item, 'product');
  final matchStatus = firstNonEmptyOf([
    stringValueOf(item, const ['match_status', 'match_type']),
    stringValueOf(product, const ['match_type']),
  ]);
  final rawStatus = firstNonEmptyOf([
    stringValueOf(item, const ['status_label', 'status']),
    magicQuoteMatchStatusLabels[matchStatus] ?? '',
    matchStatus,
  ]);
  final normalized = rawStatus.toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ');

  if (normalized.contains('no match') ||
      normalized.contains('not matched') ||
      normalized.contains('unavailable')) {
    return (
      label: rawStatus.isEmpty ? 'No match found' : rawStatus,
      kind: 'not-matched'
    );
  }
  if (normalized.contains('similar') ||
      normalized.contains('alternative') ||
      normalized.contains('brand') ||
      normalized.contains('seller')) {
    return (label: rawStatus.isEmpty ? 'Similar' : rawStatus, kind: 'similar');
  }
  return (label: rawStatus.isEmpty ? 'Matched' : rawStatus, kind: 'matched');
}

class QuoteItemRow extends StatelessWidget {
  const QuoteItemRow({
    super.key,
    required this.item,
    required this.idx,
    required this.quantity,
    required this.onQuantityChange,
    required this.onDelete,
    required this.onChange,
  });

  final Map<String, dynamic> item;
  final int idx;
  final num quantity;
  final void Function(Map<String, dynamic> item, bool increase)
      onQuantityChange;
  final void Function(Map<String, dynamic> item) onDelete;
  final void Function(Map<String, dynamic> item) onChange;

  @override
  Widget build(BuildContext context) {
    final product = mapValueOf(item, 'product');
    final status = _quoteItemStatus(item);
    final requestedText = firstNonEmptyOf([
      stringValueOf(item, const ['requested']),
      stringValueOf(product, const ['product_name', 'name']),
    ]);

    if (item['is_product_available'] == false) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MagicQuoteColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _requestedStatusRow(requestedText, status),
            const SizedBox(height: 8),
            _noMatchItemRow(idx),
          ],
        ),
      );
    }

    final name = firstNonEmptyOf(
      [
        stringValueOf(item, const ['name', 'product_name', 'item_name']),
        stringValueOf(product, const ['name', 'product_name', 'title']),
      ],
    );
    final imageUrl = firstNonEmptyOf([
      stringValueOf(product, const ['product_image', 'image']),
      stringValueOf(item, const ['product_image', 'image']),
    ]);
    final lineTotal =
        moneyValueOf(item, const ['total', 'line_total', 'amount']);
    final price = moneyValueOf(
      item,
      const ['price_after_tax', 'price', 'selling_price', 'rate'],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MagicQuoteColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _requestedStatusRow(requestedText, status),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: MagicQuoteColors.border),
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.inventory_2_outlined,
                          color: MagicQuoteColors.navy)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              color: MagicQuoteColors.navy),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Matched product' : name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.navy,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price > 0 ? '${formatInr(price)} /unit, Incl. tax' : '-',
                      style: GoogleFonts.inter(
                        color: MagicQuoteColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lineTotal > 0 ? formatInr(lineTotal) : '-',
                style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () => onDelete(item),
                icon: const Icon(Icons.delete_outline,
                    size: 19, color: MagicQuoteColors.muted),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: MagicQuoteColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => onChange(item),
                icon: const Icon(Icons.swap_horiz,
                    size: 16, color: MagicQuoteColors.navy),
                label: Text(
                  'Change',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: MagicQuoteColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Spacer(),
              _quantityStepper(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quantityStepper() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MagicQuoteColors.border),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed:
                quantity <= 1 ? null : () => onQuantityChange(item, false),
            icon: const Icon(Icons.remove, size: 16),
            color: MagicQuoteColors.navy,
            style: IconButton.styleFrom(minimumSize: const Size(34, 34)),
          ),
          SizedBox(
            width: 32,
            child: Text(
              quantity % 1 == 0
                  ? quantity.toInt().toString()
                  : quantity.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: MagicQuoteColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () => onQuantityChange(item, true),
            icon: const Icon(Icons.add, size: 16),
            color: MagicQuoteColors.navy,
            style: IconButton.styleFrom(minimumSize: const Size(34, 34)),
          ),
        ],
      ),
    );
  }

  Widget _requestedStatusRow(
    String requestedText,
    ({String label, String kind}) status,
  ) {
    final (bg, fg) = switch (status.kind) {
      'not-matched' => (const Color(0xFFFAD7D7), const Color(0xFFB3261E)),
      'similar' => (const Color(0xFFFFF4E4), const Color(0xFF9B5C00)),
      _ => (const Color(0xFFE8F7EF), const Color(0xFF169B58)),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Asked: ',
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: requestedText.isEmpty ? '-' : requestedText,
                  style: GoogleFonts.inter(
                    color: MagicQuoteColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _noMatchItemRow(int idx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFFAD7D7),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${idx + 1}',
            style: GoogleFonts.inter(
              color: const Color(0xFFB3261E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "Don't worry! Please submit and our team will be in touch",
              style: GoogleFonts.inter(
                color: const Color(0x8A8A8A8A),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
