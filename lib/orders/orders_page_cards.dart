part of 'orders_page.dart';

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final _OrderData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 0, 16),
              child: _ProductStrip(images: order.productImages),
            ),
            _PointsBanner(points: order.points),
            if (order.project != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ProjectPill(label: order.project!),
                ),
              ),
            ],
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

  final _OrderData order;

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
                      'Order delivered',
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
                '${order.amount} • ${order.dateTime}',
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
  const _ProductStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _ProductThumb(asset: images[index]),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.asset});

  final String asset;

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
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/Image-coming-soon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
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
                    text: '$points points',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(
                    text: ' will be added 7 days after delivery',
                  ),
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

class _ProjectPill extends StatelessWidget {
  const _ProjectPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD911), Color(0x00FFD911)],
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: const [
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
