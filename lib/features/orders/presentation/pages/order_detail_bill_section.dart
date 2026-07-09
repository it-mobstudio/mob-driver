part of 'order_detail_page.dart';

class _BillDetailsSection extends StatelessWidget {
  const _BillDetailsSection({this.order});

  final OrderEntity? order;

  @override
  Widget build(BuildContext context) {
    final subTotal = order?.subTotal ?? 0.0;
    final total = order?.total ?? 0.0;
    final tax = (order?.sgst ?? 0) + (order?.cgst ?? 0);
    final shipping = order?.shippingFee ?? 0.0;
    final savedAmount = subTotal > total ? subTotal - total : 0.0;
    final points = order?.rewardPoints ?? 0;
    final rewardMessage = order?.rewardMessage ?? '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill details',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
            ),
          ),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Subtotal',
            value: '₹${subTotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _BillRow(
            label: 'Shipping',
            value: shipping > 0 ? '₹${shipping.toStringAsFixed(2)}' : 'Free',
          ),
          if (tax > 0) ...[
            const SizedBox(height: 8),
            _BillRow(
              label: 'Total tax',
              value: '₹${tax.toStringAsFixed(2)}',
              dottedUnderline: true,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Total',
            value: '₹${total.toStringAsFixed(2)}',
            bold: true,
          ),
          if (savedAmount > 0) _SavedAmountBadge(amount: savedAmount),
          if (points > 0 || rewardMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EarnPointsBanner(points: points, message: rewardMessage),
          ],
        ],
      ),
    );
  }
}

class _SavedAmountBadge extends StatelessWidget {
  const _SavedAmountBadge({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFCEFBE3)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'SAVED ₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            color: const Color(0xFF329537),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 16 / 11,
          ),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool dottedUnderline;

  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.dottedUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = bold ? 14.0 : 13.0;

    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: bold ? const Color(0xFF0A243F) : const Color(0xFF67696D),
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            height: 20 / fontSize,
            decoration: dottedUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationStyle: dottedUnderline
                ? TextDecorationStyle.dotted
                : TextDecorationStyle.solid,
            decorationColor: const Color(0xFF67696D),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            height: 20 / fontSize,
          ),
        ),
      ],
    );
  }
}

class _EarnPointsBanner extends StatelessWidget {
  const _EarnPointsBanner({required this.points, required this.message});

  final int points;
  final String message;

  @override
  Widget build(BuildContext context) {
    final displayText =
        message.isNotEmpty ? message : '$points points on this purchase';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF8F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'You will earn',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
          const SizedBox(width: 4),
          SvgPicture.asset('assets/images/points.svg', width: 16, height: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              displayText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
