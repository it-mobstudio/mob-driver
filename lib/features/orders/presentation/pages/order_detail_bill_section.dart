part of 'order_detail_page.dart';

class _BillDetailsSection extends StatelessWidget {
  const _BillDetailsSection();

  @override
  Widget build(BuildContext context) {
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
          const _BillRow(
            label: 'Subtotal',
            value: '₹26567.00',
            oldValue: '₹ 27889.00',
          ),
          const SizedBox(height: 8),
          const _BillRow(label: 'Shipping', value: '₹500.00'),
          const SizedBox(height: 8),
          const _BillRow(
            label: 'Total tax',
            value: '₹433.00',
            dottedUnderline: true,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          const _BillRow(
            label: 'Total',
            value: '₹26567.00',
            oldValue: '₹ 27889.00',
            bold: true,
          ),
          const _SavedAmountBadge(),
          const SizedBox(height: 12),
          const _EarnPointsBanner(),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 20),
              label: Text(
                'Download invoice',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 21 / 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0360E5),
                side: const BorderSide(color: Color(0xFF0360E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedAmountBadge extends StatelessWidget {
  const _SavedAmountBadge();

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
          'SAVED ₹1055',
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
  final String? oldValue;
  final bool bold;
  final bool dottedUnderline;

  const _BillRow({
    required this.label,
    required this.value,
    this.oldValue,
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
        if (oldValue != null) ...[
          Text(
            oldValue!,
            style: GoogleFonts.inter(
              color: const Color(0xFFA2AABA),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFFA2AABA),
            ),
          ),
          const SizedBox(width: 16),
        ],
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
  const _EarnPointsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '1150 points',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ' on this purchase'),
                ],
              ),
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
