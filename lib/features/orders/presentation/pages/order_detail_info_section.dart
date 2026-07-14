part of 'order_detail_page.dart';

class _OrderInfoSection extends StatelessWidget {
  const _OrderInfoSection({this.order});

  final OrderEntity? order;

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat("dd MMM yyyy 'at' hh:mm a").format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatPaymentMethod(String method) {
    const map = {
      'mobWALLET': 'MOB Wallet',
      'mobCREDIT': 'MOB Credit',
      'RAZORPAY': 'Razorpay',
      'COD': 'Cash on delivery',
      'STRIPE': 'Stripe',
    };
    return map[method] ?? method;
  }

  String _formatPhone(String phone) {
    if (phone.isEmpty) return '';
    if (phone.startsWith('+')) return phone;
    return '+91 $phone';
  }

  Future<void> _copyOrderId(BuildContext context, String orderId) async {
    await Clipboard.setData(ClipboardData(text: orderId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (order == null) return const SizedBox.shrink();

    final orderId = order!.orderNumber;
    final createdAt = _formatDate(order!.createdAt);
    final paymentMethod = order!.paymentMethods.isEmpty
        ? '—'
        : order!.paymentMethods.map(_formatPaymentMethod).join(', ');

    final deliveryPhone = _formatPhone(order!.deliveryPhone);
    final billingPhone = _formatPhone(order!.billingPhone);

    final deliveryAddressText = [
      order!.shippingAddress,
      if (deliveryPhone.isNotEmpty) deliveryPhone,
    ].where((p) => p.isNotEmpty).join('\n');

    final billingAddressText = [
      order!.billingAddressFormatted,
      if (billingPhone.isNotEmpty) billingPhone,
    ].where((p) => p.isNotEmpty).join('\n');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order details',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
            ),
          ),
          const SizedBox(width: 7),
          const _DetailLabel('Order ID'),
          GestureDetector(
            onTap: () => _copyOrderId(context, orderId),
            child: Row(
              children: [
                _DetailValue(orderId),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _DetailLabel('Order placed'),
          _DetailValue(createdAt),
          const SizedBox(height: 12),
          const _DetailLabel('Payment method'),
          _DetailValue(paymentMethod),
          if (order!.deliveryName.isNotEmpty ||
              deliveryAddressText.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DetailLabel('Delivery address'),
            if (order!.deliveryName.isNotEmpty)
              _DetailValue(order!.deliveryName),
            if (deliveryAddressText.isNotEmpty)
              _DetailValue(deliveryAddressText),
          ],
          if (order!.billingName.isNotEmpty ||
              billingAddressText.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _DetailLabel('Billing address'),
            if (order!.billingName.isNotEmpty) _DetailValue(order!.billingName),
            if (order!.gstNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              _GstBadge(gstNumber: order!.gstNumber),
              const SizedBox(height: 4),
            ],
            if (billingAddressText.isNotEmpty) _DetailValue(billingAddressText),
          ],
        ],
      ),
    );
  }
}

class _GstBadge extends StatelessWidget {
  const _GstBadge({required this.gstNumber});

  final String gstNumber;

  @override
  Widget build(BuildContext context) {
    // No `height` + `alignment` here: Container wraps its child in an
    // Align when alignment is set, and Align expands to fill all
    // available width by default rather than shrink-wrapping — that's
    // what stretched this pill across the full card width. Sizing purely
    // from padding keeps it hugging the text instead.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF133B62),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'GST NO: $gstNumber',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 16 / 11,
        ),
      ),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;

  const _DetailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF67696D),
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 16 / 11,
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  final String text;

  const _DetailValue(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF0A243F),
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 20 / 13,
      ),
    );
  }
}
