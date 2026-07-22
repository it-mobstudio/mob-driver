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

    final suborders = order.shipments.isEmpty
        ? const <OrderShipmentEntity>[]
        : [...order.shipments]
      ..sort((a, b) {
        final suffixCompare =
            _suborderSuffixNumber(a.id).compareTo(_suborderSuffixNumber(b.id));
        if (suffixCompare != 0) return suffixCompare;
        return a.id.compareTo(b.id);
      });
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

  int _suborderSuffixNumber(String id) {
    final match = RegExp(r'_(\d+)$').firstMatch(id.trim());
    if (match == null) return 999999;
    return int.tryParse(match.group(1) ?? '') ?? 999999;
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
                      // if (deliveryLabel.isNotEmpty)
                      //   Text(
                      //     deliveryLabel,
                      //     style: GoogleFonts.inter(
                      //       color: const Color(0xFF596378),
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.w400,
                      //       height: 18 / 12,
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF1F1F2),
                    shape: OvalBorder(),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/greaterarrow.svg',
                      width: 12,
                      height: 12,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: item.slug.isEmpty
                ? null
                : () =>
                    context.push('${ProductDetailPage.routePath}/${item.slug}'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 44,
                height: 44,
               // color: const Color(0xFFF1F1F2),
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
              ? _SuborderFilePreviewContent(
                  url: file.fileUrl,
                  compact: true,
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
                final type = _SuborderFileType.fromUrl(fileUrl);
                final content = Center(
                  child: fileUrl.isNotEmpty
                      ? _SuborderFilePreviewContent(url: fileUrl)
                      : const Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.white,
                          size: 64,
                        ),
                );
                if (!type.isImage) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: content,
                  );
                }
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: content,
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

enum _SuborderFileType {
  svg,
  image,
  pdf,
  spreadsheet,
  document,
  unknown;

  bool get isImage => this == svg || this == image;

  static _SuborderFileType fromUrl(String url) {
    final extension = _fileExtension(url);
    if (extension == 'svg') return svg;
    if (const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'}.contains(extension)) {
      return image;
    }
    if (extension == 'pdf') return pdf;
    if (const {'xls', 'xlsx', 'csv'}.contains(extension)) return spreadsheet;
    if (const {'doc', 'docx'}.contains(extension)) return document;
    return unknown;
  }
}

class _SuborderFilePreviewContent extends StatelessWidget {
  const _SuborderFilePreviewContent({
    required this.url,
    this.compact = false,
  });

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = _SuborderFileType.fromUrl(url);
    return switch (type) {
      _SuborderFileType.svg => _NetworkSvgPreview(url: url, compact: compact),
      _SuborderFileType.image => _NetworkImagePreview(
          url: url,
          compact: compact,
        ),
      _ => _DocumentPreview(url: url, type: type, compact: compact),
    };
  }
}

class _NetworkImagePreview extends StatelessWidget {
  const _NetworkImagePreview({required this.url, required this.compact});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: compact ? BoxFit.cover : BoxFit.contain,
      memCacheWidth: compact ? 176 : 1100,
      placeholder: (_, __) => const ImageShimmer(),
      errorWidget: (_, __, ___) => _FileFallbackIcon(compact: compact),
    );
  }
}

class _NetworkSvgPreview extends StatelessWidget {
  const _NetworkSvgPreview({required this.url, required this.compact});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.network(
      url,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const ImageShimmer(),
      width: compact ? 68 : null,
      height: compact ? 68 : null,
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({
    required this.url,
    required this.type,
    required this.compact,
  });

  final String url;
  final _SuborderFileType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _FileFallbackIcon(compact: true, type: type);
    }
    final fileName = _fileName(url);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FileFallbackIcon(compact: false, type: type),
          const SizedBox(height: 16),
          Text(
            fileName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_fileTypeLabel(type)} file',
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0360E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => _openAttachmentUrl(context, url),
              child: Text(
                'Open file',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileFallbackIcon extends StatelessWidget {
  const _FileFallbackIcon({
    required this.compact,
    this.type = _SuborderFileType.unknown,
  });

  final bool compact;
  final _SuborderFileType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      _SuborderFileType.pdf => const Color(0xFFE53935),
      _SuborderFileType.spreadsheet => const Color(0xFF138A43),
      _SuborderFileType.document => const Color(0xFF0360E5),
      _ => compact ? const Color(0xFF8A8A8A) : const Color(0xFF596378),
    };
    final icon = switch (type) {
      _SuborderFileType.pdf => Icons.picture_as_pdf_outlined,
      _SuborderFileType.spreadsheet => Icons.table_chart_outlined,
      _SuborderFileType.document => Icons.description_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
    return Icon(
      icon,
      color: color,
      size: compact ? 34 : 72,
    );
  }
}

Future<void> _openAttachmentUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    TopSnackBar.show(
      context,
      message: 'Unable to open file',
      type: TopSnackBarType.error,
    );
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    TopSnackBar.show(
      context,
      message: 'Unable to open file',
      type: TopSnackBarType.error,
    );
  }
}

String _fileExtension(String url) {
  final path = Uri.tryParse(url)?.path ?? url;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final name = parts.isEmpty ? '' : parts.last;
  final dotIndex = name.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == name.length - 1) return '';
  return name.substring(dotIndex + 1).toLowerCase();
}

String _fileName(String url) {
  final path = Uri.tryParse(url)?.path ?? url;
  final parts = path.split('/').where((part) => part.isNotEmpty).toList();
  final name = parts.isEmpty ? '' : parts.last;
  if (name.isEmpty) return 'Attachment';
  return Uri.decodeComponent(name);
}

String _fileTypeLabel(_SuborderFileType type) {
  return switch (type) {
    _SuborderFileType.pdf => 'PDF',
    _SuborderFileType.spreadsheet => 'Spreadsheet',
    _SuborderFileType.document => 'Document',
    _SuborderFileType.svg => 'SVG',
    _SuborderFileType.image => 'Image',
    _ => 'Attachment',
  };
}
