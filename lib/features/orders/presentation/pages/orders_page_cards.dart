part of 'orders_page.dart';

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final OrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrls = order.items
        .map((e) => e.imageUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _OrderHeader(order: order),
            ),
            const Divider(height: 1, color: Color(0xFFE5E8EE)),
            if (imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 0, 15),
                child: _ProductStrip(imageUrls: imageUrls),
              )
            else
              const SizedBox(height: 8),
            _ItemCountBanner(itemCount: order.items.length),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E8EE)),
            const _OrderActions(),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final OrderEntity order;

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Order placed';
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase().replaceAll('_', ' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFCEFBE3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check, color: Color(0xFF0BCB60), size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _formatStatus(order.status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 16,
                    color: const Color(0xFFD9D9D9),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    'assets/images/qwik.svg',
                    width: 54,
                    height: 14,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₹${order.total.toStringAsFixed(0)} • ${order.createdAt}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF767C8F),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _ProductThumb(imageUrl: imageUrls[index]),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          memCacheWidth: 120,
          placeholder: (_, __) => const ImageShimmer(),
          errorWidget: (_, __, ___) => Image.asset(
            'assets/images/Image-coming-soon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ItemCountBanner extends StatelessWidget {
  const _ItemCountBanner({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4CA), Color(0x00FFF4CA)],
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/images/points.svg', width: 16, height: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(text: ' in this order'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(child: _OrderActionButton(label: 'Repeat')),
          Expanded(child: _OrderActionButton(label: 'Rate order')),
        ],
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final String label;

  const _OrderActionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0360E5),
        textStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
        ),
      ),
      child: Text(label),
    );
  }
}
