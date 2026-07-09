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
    final imageUrls = order.items.map((e) => e.imageUrl).toList();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _OrderHeader(order: order),
            ),
            const Divider(
              height: 0,
              thickness: 1,
              color: Color(0xFFE5E8EE),
            ),
            if (imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: _ProductStrip(imageUrls: imageUrls),
              )
            else
              const SizedBox(height: 8),
            if (!order.isStoreOrder && order.rewardMessage.trim().isNotEmpty)
              _RewardBanner(message: order.rewardMessage),
            if (order.projectName.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _ProjectChip(projectName: order.projectName.trim()),
            ],
            const SizedBox(height: 16),
            // const Divider(
            //   height: 0,
            //   thickness: 1,
            //   color: Color(0xFFE5E8EE),
            // ),
            // _OrderActions(order: order),
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

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('d MMM, h:mm a').format(parsed.toLocal()).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          orderStatusIconAsset(order.status),
          width: 38,
          height: 38,
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
                  if (order.isQuickCommerceOrder) ...[
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
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₹${order.total.toStringAsFixed(0)}  • ${_formatDate(order.createdAt)}',
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
        borderRadius: BorderRadius.circular(6),
        child: imageUrl.isEmpty
            ? const ProductImagePlaceholder()
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                memCacheWidth: 120,
                placeholder: (_, __) => const ImageShimmer(),
                errorWidget: (_, __, ___) => const ProductImagePlaceholder(),
              ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.message});

  final String message;

  String get _displayMessage {
    return message
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('It will be', 'will be')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final displayMessage = _displayMessage;
    if (displayMessage.isEmpty) return const SizedBox.shrink();
    final pointsMatch = RegExp(r'^\d+\s+points').firstMatch(displayMessage);
    final pointsLabel = pointsMatch?.group(0);
    final suffix =
        pointsLabel == null ? '' : displayMessage.substring(pointsLabel.length);

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
              pointsLabel == null
                  ? TextSpan(text: displayMessage)
                  : TextSpan(
                      children: [
                        TextSpan(
                          text: pointsLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(text: suffix),
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

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.98, 0.5),
            end: Alignment(-0.0, 0.5),
            colors: [Color(0x00FFD911), Color(0xFFFFD911)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                projectName.startsWith('Project:')
                    ? projectName
                    : 'Project: $projectName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
