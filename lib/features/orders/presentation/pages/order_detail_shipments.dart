part of 'order_detail_page.dart';

class _ShipmentSection extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Color iconBackground;
  final List<OrderItemEntity> items;

  const _ShipmentSection({
    required this.index,
    required this.title,
    required this.icon,
    required this.iconBackground,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF0A7D83)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHIPMENT $index',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF596378),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 16 / 11,
                      ),
                    ),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 28 / 19,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 14),
          Text(
            '${items.length} ${items.length == 1 ? 'item' : 'items'} in shipment',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _ShipmentItemTile(item: items[i]),
            if (i < items.length - 1) const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _ShipmentItemTile extends StatelessWidget {
  final OrderItemEntity item;

  const _ShipmentItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: const Color(0xFFF1F1F2),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 88,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/Image-coming-soon.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/Image-coming-soon.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹ ${item.unitPrice.toStringAsFixed(0)} /unit',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xFFD9D9D9),
                    ),
                    Text(
                      '${item.qty} units',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${item.lineTotal.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateItemsStrip extends StatelessWidget {
  const _RateItemsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 71,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2C3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB800),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'How were your\nordered items?',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
          ),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0360E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Rate now',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/images/points.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '80',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
