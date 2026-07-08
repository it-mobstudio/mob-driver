part of 'order_detail_page.dart';

class _ShipmentSection extends StatelessWidget {
  final OrderEntity order;
  final OrderShipmentEntity shipment;
  final int index;
  final String title;
  final String iconAsset;
  final List<OrderItemEntity> items;

  const _ShipmentSection({
    required this.order,
    required this.shipment,
    required this.index,
    required this.title,
    required this.iconAsset,
    required this.items,
  });

  void _showFilesAttachedSheet(
    BuildContext context,
    List<OrderShipmentFileEntity> files,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SuborderFilesSheet(files: files),
    );
  }

  String _formatDeliveryDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _buildDeliveryLabel() {
    if (shipment.deliverySlot.isNotEmpty) return shipment.deliverySlot;
    final isDelivered = order.status.trim() == 'Order Delivered';
    if (isDelivered) {
      final date = _formatDeliveryDate(order.createdAt);
      return date.isNotEmpty ? 'Delivered $date' : 'Delivered';
    }

    final suborders = order.shipments;
    if (suborders.length <= 1) {
      final date = _formatDeliveryDate(shipment.deliveryDate);
      return date.isNotEmpty ? 'Arriving by $date' : '';
    }

    // 4. Multiple suborders → "Arriving between {first} - {last}"
    final firstDate = _formatDeliveryDate(suborders.first.deliveryDate);
    final lastDate = _formatDeliveryDate(suborders.last.deliveryDate);
    if (firstDate.isNotEmpty && lastDate.isNotEmpty) {
      return 'Arriving between $firstDate - $lastDate';
    }
    if (firstDate.isNotEmpty) return 'Arriving by $firstDate';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final deliveryLabel = _buildDeliveryLabel();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push(
              OrderTrackingPage.routePath,
              extra: {'order': order, 'shipment': shipment},
            ),
            child: Row(
              children: [
                SvgPicture.asset(iconAsset, width: 38, height: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHIPMENT $index',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      if (deliveryLabel.isNotEmpty)
                        Text(
                          deliveryLabel,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF596378),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 18 / 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 0,
            thickness: 1,
            color: Color(0xFFE0E0E0),
          ),
          const SizedBox(height: 14),
          if (shipment.files.isNotEmpty) ...[
            _FilesAttachedRow(
              count: shipment.files.length,
              onTap: () => _showFilesAttachedSheet(context, shipment.files),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            '${items.length} ${items.length == 1 ? 'item' : 'items'} in shipment',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
                      fit: BoxFit.contain,
                      memCacheWidth: 88,
                      placeholder: (_, __) => const ImageShimmer(),
                      errorWidget: (_, __, ___) =>
                          const ProductImagePlaceholder(),
                    )
                  : const ProductImagePlaceholder(),
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
                      '\u20B9${item.unitPrice.toStringAsFixed(0)} /unit',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\u20B9${item.lineTotal.toStringAsFixed(0)}.00',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
              Text(
                '\u20B9${(item.lineTotal * 1.37).toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA2AABA),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 16 / 11,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: const Color(0xFFA2AABA),
                ),
              ),
            ],
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

class _FilesAttachedRow extends StatelessWidget {
  const _FilesAttachedRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/attachment.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '$count ${count == 1 ? 'file' : 'files'} attached',
              style: GoogleFonts.inter(
                color: const Color(0xFF0360E5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Close button sits as a normal flow child directly above the sheet (not a
// Positioned overlap) — a negative-offset Positioned outside a Stack's own
// bounds paints fine but never receives hit-test dispatch (RenderBox.hitTest
// gates on its own reported size first), the same issue already hit and
// fixed in the RFQ "recheck prices" sheet.
class _SuborderFilesSheet extends StatelessWidget {
  const _SuborderFilesSheet({required this.files});

  final List<OrderShipmentFileEntity> files;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF0A243F),
                size: 22,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${files.length} ${files.length == 1 ? 'file' : 'files'} attached',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 26 / 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These are the files shared by MOB team',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF596378),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 18 / 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var i = 0; i < files.length; i++)
                            _SuborderFileThumbnail(
                              file: files[i],
                              onTap: () => _openPreview(context, i),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context, int index) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close file preview',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return _SuborderFilePreviewOverlay(files: files, initialIndex: index);
      },
    );
  }
}

class _SuborderFileThumbnail extends StatelessWidget {
  const _SuborderFileThumbnail({required this.file, required this.onTap});

  final OrderShipmentFileEntity file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 88,
          height: 88,
          color: const Color(0xFFF1F1F2),
          child: file.fileUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: file.fileUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 176,
                  placeholder: (_, __) => const ImageShimmer(),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.insert_drive_file_outlined,
                    color: Color(0xFF8A8A8A),
                  ),
                )
              : const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Color(0xFF8A8A8A),
                ),
        ),
      ),
    );
  }
}

class _SuborderFilePreviewOverlay extends StatefulWidget {
  const _SuborderFilePreviewOverlay({
    required this.files,
    required this.initialIndex,
  });

  final List<OrderShipmentFileEntity> files;
  final int initialIndex;

  @override
  State<_SuborderFilePreviewOverlay> createState() =>
      _SuborderFilePreviewOverlayState();
}

class _SuborderFilePreviewOverlayState
    extends State<_SuborderFilePreviewOverlay> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.files.isEmpty ? 0 : widget.files.length - 1;
    _pageController =
        PageController(initialPage: widget.initialIndex.clamp(0, maxIndex));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.files.isEmpty ? 1 : widget.files.length,
              itemBuilder: (context, index) {
                final fileUrl =
                    widget.files.isEmpty ? '' : widget.files[index].fileUrl;
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: fileUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: fileUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: 1100,
                            placeholder: (_, __) => const ImageShimmer(),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.insert_drive_file_outlined,
                              color: Colors.white,
                              size: 64,
                            ),
                          )
                        : const Icon(
                            Icons.insert_drive_file_outlined,
                            color: Colors.white,
                            size: 64,
                          ),
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              top: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF0A243F),
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
