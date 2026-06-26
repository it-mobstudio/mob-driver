part of 'order_detail_page.dart';

class _OrderInfoSection extends StatelessWidget {
  const _OrderInfoSection();

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 7),
          const _DetailLabel('Order ID'),
          Row(
            children: [
              const _DetailValue('OD20260106004961'),
              const SizedBox(width: 8),
              Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 12),
          const _DetailLabel('Order placed'),
          const _DetailValue('15 Jan 2026 at 12:46 PM'),
          const SizedBox(height: 12),
          const _DetailLabel('Payment method'),
          const _DetailValue('mobCREDIT'),
          const SizedBox(height: 12),
          const _DetailLabel('Delivery address'),
          const _DetailValue(
            'Carlos Sainz\n10 Downing Street, 4th floor, Infront of westend mall, Chennai, 600005\n+91 9876554324',
          ),
          const SizedBox(height: 12),
          const _DetailLabel('Billing address'),
          const _DetailValue('Carlos Sainz'),
          const SizedBox(height: 4),
          const _GstBadge(),
          const SizedBox(height: 4),
          const _DetailValue(
            '10 Downing Street, 4th floor, Infront of westend mall, Chennai, 600005\n+91 9876554324',
          ),
        ],
      ),
    );
  }
}

class _GstBadge extends StatelessWidget {
  const _GstBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF133B62),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        'GST NO: 18AABCU9603R1ZM',
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
