import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';

class ProductDetailTopHeader extends StatelessWidget {
  const ProductDetailTopHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class ProductImagesCarousel extends StatefulWidget {
  const ProductImagesCarousel({
    super.key,
    required this.images,
  });

  final List<ProductImageRef> images;

  @override
  State<ProductImagesCarousel> createState() => _ProductImagesCarouselState();
}

class _ProductImagesCarouselState extends State<ProductImagesCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return Container(
      color: Colors.white,
      height: 375,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 32,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, index) {
              final imageUrl = images.isEmpty ? '' : images[index].url;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (images.isEmpty) {
                    return;
                  }
                  showGeneralDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'Close image preview',
                    barrierColor: Colors.white,
                    transitionDuration: const Duration(milliseconds: 180),
                    pageBuilder: (_, __, ___) {
                      return ProductImagePreviewOverlay(
                        images: images,
                        initialIndex: index,
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 48, 60, 76),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: 900,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/Image-coming-soon.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/images/Image-coming-soon.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(images.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0A243F)
                          : const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductImagePreviewOverlay extends StatefulWidget {
  const ProductImagePreviewOverlay({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  final List<ProductImageRef> images;
  final int initialIndex;

  @override
  State<ProductImagePreviewOverlay> createState() =>
      _ProductImagePreviewOverlayState();
}

class _ProductImagePreviewOverlayState
    extends State<ProductImagePreviewOverlay> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex).toInt();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
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
                        color: Colors.black.withOpacity(0.14),
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
            Positioned.fill(
              top: 92,
              bottom: 116,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.isEmpty ? 1 : widget.images.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _PreviewImage(
                      imageUrl:
                          widget.images.isEmpty ? '' : widget.images[index].url,
                      memCacheWidth: 1100,
                    ),
                  );
                },
              ),
            ),
            if (widget.images.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          );
                          setState(() => _currentIndex = index);
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0A243F)
                                  : const Color(0xFFDEDEDE),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _PreviewImage(
                              imageUrl: widget.images[index].url,
                              memCacheWidth: 180,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({
    required this.imageUrl,
    required this.memCacheWidth,
  });

  final String imageUrl;
  final int memCacheWidth;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/Image-coming-soon.png',
        fit: BoxFit.contain,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      memCacheWidth: memCacheWidth,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/Image-coming-soon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class ProductInfoBlock extends StatelessWidget {
  const ProductInfoBlock({
    super.key,
    required this.product,
    this.selectedVariants = const <String, String?>{},
    this.onVariantSelect,
  });

  final ProductModel product;
  final Map<String, String?> selectedVariants;
  final void Function(String key, ProductVariantOption option)? onVariantSelect;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final oldPrice = product.maximumRetailPrice;
    final discount = product.vendorPricing.discount;
    final brand = product.brandName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailCard(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (brand.isNotEmpty) _BrandNameRow(brandName: brand),
                    const Spacer(),
                    if (product.rating > 0)
                      _RatingBadge(
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 22 / 15,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '\u20B9 ${price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 31 / 21,
                        color: const Color(0xFF0A243F),
                      ),
                    ),
                    if (discount > 0) ...[
                      const SizedBox(width: 16),
                      _DiscountBadge(discount: discount),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (oldPrice > 0)
                      Text(
                        'MRP: \u20B9 ${oldPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 16 / 11,
                          color: const Color(0xFF767C8F),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Inclusive of 18% tax / unit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 16 / 11,
                          color: const Color(0xFF767C8F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RewardLine(price: price),
              ],
            ),
          ),
        ),
        if (product.hasVariants)
          _DetailCard(
            padding: EdgeInsets.zero,
            child: _ProductInfoVariants(
              variants: product.variants,
              selectedVariants: selectedVariants,
              onSelect: onVariantSelect,
            ),
          ),
      ],
    );
  }
}

class _ProductInfoVariants extends StatelessWidget {
  const _ProductInfoVariants({
    required this.variants,
    required this.selectedVariants,
    required this.onSelect,
  });

  final Map<String, List<ProductVariantOption>> variants;
  final Map<String, String?> selectedVariants;
  final void Function(String key, ProductVariantOption option)? onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = variants.entries
        .where((entry) => entry.value.any((option) => option.value.trim().isNotEmpty))
        .toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            _ProductInfoVariantGroup(
              entry: entry,
              selectedVariants: selectedVariants,
              onSelect: onSelect,
              addBottomGap: entry != entries.last,
            ),
        ],
      ),
    );
  }
}

class _ProductInfoVariantGroup extends StatelessWidget {
  const _ProductInfoVariantGroup({
    required this.entry,
    required this.selectedVariants,
    required this.onSelect,
    required this.addBottomGap,
  });

  final MapEntry<String, List<ProductVariantOption>> entry;
  final Map<String, String?> selectedVariants;
  final void Function(String key, ProductVariantOption option)? onSelect;
  final bool addBottomGap;

  @override
  Widget build(BuildContext context) {
    final isColorGroup = entry.key.toLowerCase().contains('colo');

    return Padding(
      padding: EdgeInsets.only(bottom: addBottomGap ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _beautifyVariantKey(entry.key),
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 20 / 13,
            ),
          ),
          const SizedBox(height: 10),
          if (isColorGroup)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: entry.value.asMap().entries.map((optionEntry) {
                  return _productInfoVariantChip(
                    optionEntry: optionEntry,
                    isColorGroup: true,
                  );
                }).toList(),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entry.value.asMap().entries.map((optionEntry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _productInfoVariantChip(
                      optionEntry: optionEntry,
                      isColorGroup: false,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productInfoVariantChip({
    required MapEntry<int, ProductVariantOption> optionEntry,
    required bool isColorGroup,
  }) {
    final option = optionEntry.value;
    final selected = selectedVariants[entry.key] == option.value ||
        (selectedVariants[entry.key] == null && optionEntry.key == 0);

    return _VariantChip(
      label: option.value,
      isSelected: selected,
      isColorChip: isColorGroup,
      height: 40,
      horizontalPadding: 16,
      fontSize: 13,
      onTap: () => onSelect?.call(entry.key, option),
    );
  }
}

class ProductDivider extends StatelessWidget {
  const ProductDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F8FB),
      child: const SizedBox(height: 12),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class DeliveryInfoCard extends StatelessWidget {
  const DeliveryInfoCard({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Delivery details'),
          const SizedBox(height: 10),
          _DeliveryDetailRow(
            icon: Icons.local_shipping_outlined,
            text: 'Delivery in 1-4 hrs',
            isHighlighted: true,
            showQwikAssets: true,
          ),
          const SizedBox(height: 8),
          const _DeliveryDetailRow(
            icon: Icons.inventory_2_outlined,
            text: 'Fulfilled by BENG 21',
            leadingAsset: 'assets/images/home.svg',
          ),
        ],
      ),
    );
  }
}

class MobCreditBannerSection extends StatelessWidget {
  const MobCreditBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 32,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF272727),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              'assets/images/mobcredit.svg',
              height: 14,
            ),
          ),
          Container(
            height: 58,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF096754),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/buildnowpaylater.svg',
                  width: 82,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '0% Interest',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF02FE6D),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 16 / 11,
                              ),
                            ),
                            TextSpan(
                              text: ' for 21 days',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                height: 16 / 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '90 days',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF02FE6D),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 16 / 11,
                              ),
                            ),
                            TextSpan(
                              text: ' credit period',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                height: 16 / 11,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Apply now',
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

class ProductAssuranceSection extends StatelessWidget {
  const ProductAssuranceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      child: Row(
        children: const [
          SizedBox(
            width: 76,
            child: _WarrantyBadge(
              assetPath: 'assets/images/return.svg',
              label: '7 days free\nreturn',
            ),
          ),
          SizedBox(width: 27),
          SizedBox(
            width: 76,
            child: _WarrantyBadge(
              assetPath: 'assets/images/warrenty.svg',
              label: '2 Years\nwarranty',
            ),
          ),
        ],
      ),
    );
  }
}

class _WarrantyBadge extends StatelessWidget {
  const _WarrantyBadge({
    required this.assetPath,
    required this.label,
  });

  final String assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          assetPath,
          width: 48,
          height: 48,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 18 / 12,
            color: const Color(0xFF0A243F),
          ),
        ),
      ],
    );
  }
}

class KeyFeaturesSection extends StatelessWidget {
  const KeyFeaturesSection({
    super.key,
    required this.description,
  });

  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Product description'),
          const SizedBox(height: 10),
          Text(
            _cleanHtmlText(description),
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 20 / 13,
              color: const Color(0xFF0A243F),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsTableSection extends StatelessWidget {
  const ProductDetailsTableSection({
    super.key,
    required this.features,
  });

  final Map<String, String> features;

  @override
  Widget build(BuildContext context) {
    return _ExpandableSection(
      title: 'Specifications',
      initiallyExpanded: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          border: TableBorder(
            horizontalInside:
                const BorderSide(color: Color(0xFFDEDEDE), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          children: features.entries.map((entry) {
            return TableRow(
              children: [
                Container(
                  color: const Color(0xFFF6F8FB),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  child: Text(
                    entry.key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF57627A),
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SpecificationsSection extends StatelessWidget {
  const SpecificationsSection({
    super.key,
    required this.bulletPoints,
  });

  final String bulletPoints;

  @override
  Widget build(BuildContext context) {
    final formatted = bulletPoints.replaceAll(
      RegExp(r'(<br>|<Br>|<BR>)', caseSensitive: false),
      '\n',
    );

    return _ExpandableSection(
      title: 'Key features',
      initiallyExpanded: false,
      child: Text(
        _cleanHtmlText(formatted),
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 20 / 13,
          color: const Color(0xFF0A243F),
        ),
      ),
    );
  }
}

class ProductLongDetailsSection extends StatelessWidget {
  const ProductLongDetailsSection({
    super.key,
    required this.description,
    required this.features,
    required this.bulletPoints,
  });

  final String description;
  final Map<String, String> features;
  final String bulletPoints;

  @override
  Widget build(BuildContext context) {
    final cleanedDescription = _cleanHtmlText(description);
    final cleanedBullets = _cleanHtmlText(
      bulletPoints.replaceAll(
        RegExp(r'(<br>|<Br>|<BR>)', caseSensitive: false),
        '\n',
      ),
    );

    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineExpandableSection(
            title: 'Product details',
            initiallyExpanded: true,
            child: Text(
              cleanedDescription.isEmpty
                  ? 'Product information will be updated soon.'
                  : cleanedDescription,
              style: _detailBodyStyle(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          _InlineExpandableSection(
            title: 'Features',
            initiallyExpanded: false,
            child: _FeatureTable(features: features),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          _InlineExpandableSection(
            title: 'Specification',
            initiallyExpanded: false,
            child: Text(
              cleanedBullets.isEmpty
                  ? 'Specifications will be updated soon.'
                  : cleanedBullets,
              style: _detailBodyStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class SimilarProductsSection extends StatelessWidget {
  const SimilarProductsSection({
    super.key,
    required this.products,
  });

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Text(
            'View similar items',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
            ),
          ),
        ),
        SizedBox(
          height: 282,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 136,
                  child: _SimilarProductCard(
                    product: product,
                    onTap: () {
                      GoRouter.of(context).go(
                        '${ProductDetailPage.routePath}/${product.slug}',
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VariantOptionsSection extends StatelessWidget {
  const VariantOptionsSection({
    super.key,
    required this.variants,
    required this.selectedVariants,
    required this.onSelect,
  });

  final Map<String, List<ProductVariantOption>> variants;
  final Map<String, String?> selectedVariants;
  final void Function(String key, ProductVariantOption option) onSelect;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return const SizedBox.shrink();
    }

    final keys = variants.keys.toList();

    return _DetailCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in keys)
            if ((variants[key] ?? const <ProductVariantOption>[])
                .isNotEmpty) ...[
              Text(
                _beautifyVariantKey(key),
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 18 / 12,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (variants[key] ?? const <ProductVariantOption>[])
                      .asMap()
                      .entries
                      .map((entry) {
                    final option = entry.value;
                    final selected = selectedVariants[key] == option.value ||
                        (selectedVariants[key] == null && entry.key == 0);
                    return _VariantChip(
                      label: option.value,
                      isSelected: selected,
                      isColorChip: false,
                      onTap: () => onSelect(key, option),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }

  String _beautifyVariantKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}

class _BrandNameRow extends StatelessWidget {
  const _BrandNameRow({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          brandName,
          style: GoogleFonts.inter(
            color: const Color(0xFF01A685),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 18 / 12,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.keyboard_arrow_right_rounded,
          size: 14,
          color: Color(0xFF01A685),
        ),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 16 / 11,
        color: const Color(0xFF7E868A),
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.price});

  final num price;

  @override
  Widget build(BuildContext context) {
    final coins = (price / 100).round().clamp(1, 9999);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4CA), Color(0x00FFF4CA)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Earn',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 16 / 11,
              ),
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/images/points.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$coins points',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 16 / 11,
                    ),
                  ),
                  TextSpan(
                    text: ' on this purchase',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 16 / 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.discount});

  final num discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9ED),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${discount.round()}% off',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
          color: const Color(0xFF01A685),
        ),
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.label,
    required this.isSelected,
    required this.isColorChip,
    required this.onTap,
    this.height = 34,
    this.horizontalPadding = 13,
    this.fontSize = 11,
  });

  final String label;
  final bool isSelected;
  final bool isColorChip;
  final VoidCallback onTap;
  final double height;
  final double horizontalPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.fromLTRB(
          isColorChip ? 10 : horizontalPadding,
          0,
          horizontalPadding,
          0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A243F) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0A243F) : const Color(0xFFDFE4EC),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isColorChip) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _swatchColor(label),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDFE4EC)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : const Color(0xFF0A243F),
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 16 / fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _swatchColor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('white')) return Colors.white;
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('blue')) return const Color(0xFF2364D2);
    if (lower.contains('grey') || lower.contains('gray')) return Colors.grey;
    if (lower.contains('red')) return const Color(0xFFD02F2F);
    if (lower.contains('green')) return const Color(0xFF01A685);
    if (lower.contains('yellow')) return const Color(0xFFFFD84D);
    if (lower.contains('brown')) return const Color(0xFF8A5A32);
    return const Color(0xFFECEFF4);
  }
}

class _DeliveryDetailRow extends StatelessWidget {
  const _DeliveryDetailRow({
    required this.icon,
    required this.text,
    this.isHighlighted = false,
    this.showQwikAssets = false,
    this.leadingAsset,
  });

  final IconData icon;
  final String text;
  final bool isHighlighted;
  final bool showQwikAssets;
  final String? leadingAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isHighlighted ? 40 : 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFEFCE) : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.vertical(
          top: isHighlighted ? const Radius.circular(12) : Radius.zero,
          bottom: isHighlighted ? Radius.zero : const Radius.circular(12),
        ),
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFFEFCE))
            : Border.all(color: const Color(0xFFF8F8F8)),
      ),
      child: Row(
        children: [
          if (showQwikAssets) ...[
            SvgPicture.asset(
              'assets/images/car.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 12),
            SvgPicture.asset(
              'assets/images/qwik.svg',
              height: 14,
            ),
          ] else if (leadingAsset != null)
            SvgPicture.asset(
              leadingAsset!,
              width: 16,
              height: 16,
            )
          else
            Icon(icon, size: 16, color: const Color(0xFF0A243F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: isHighlighted ? 12 : 11,
                fontWeight: FontWeight.w600,
                height: isHighlighted ? 18 / 12 : 16 / 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractorBanner extends StatelessWidget {
  const _ContractorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF005B4F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCIDENTAL MOB DAMAGE PLAN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 12 / 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Protect your product with our plan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 12 / 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Apply now',
            style: GoogleFonts.inter(
              color: const Color(0xFF9BFF9C),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 14 / 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({
    required this.rating,
    required this.reviewCount,
  });

  final num rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC107)),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: const Color(0xFF0A243F),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Expanded(child: _SectionTitle(title: widget.title)),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF0A243F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: widget.child,
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _InlineExpandableSection extends StatefulWidget {
  const _InlineExpandableSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_InlineExpandableSection> createState() => _InlineExpandableSectionState();
}

class _InlineExpandableSectionState extends State<_InlineExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(child: _SectionTitle(title: widget.title)),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: widget.child,
          ),
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable({required this.features});

  final Map<String, String> features;

  @override
  Widget build(BuildContext context) {
    final entries = features.entries
        .where((entry) => entry.key.trim().isNotEmpty || entry.value.trim().isNotEmpty)
        .toList();

    if (entries.isEmpty) {
      return Text(
        'Feature information will be updated soon.',
        style: _detailBodyStyle(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _FeatureRow(
              label: _beautifyFeatureLabel(entries[i].key),
              value: entries[i].value,
              showDivider: i < entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: showDivider
              ? const BorderSide(color: Colors.white)
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(
                right: BorderSide(color: Colors.white),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                value,
                style: _detailBodyStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarProductCard extends StatelessWidget {
  const _SimilarProductCard({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final oldPrice = product.maximumRetailPrice;
    final discount = product.vendorPricing.discount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 136,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 156,
              child: Stack(
                children: [
                  Positioned.fill(
                    bottom: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 8,
                    height: 120,
                    child: product.primaryImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.primaryImageUrl,
                            fit: BoxFit.contain,
                            memCacheWidth: 240,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/Image-coming-soon.png',
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/images/Image-coming-soon.png',
                            fit: BoxFit.contain,
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ProductCartActionButton(
                      product: product,
                      compact: true,
                      showCounter: false,
                      onVariantsTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 16 / 12,
              ),
            ),
            const SizedBox(height: 8),
            if (discount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE600),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(-1, 1)),
                  ],
                ),
                child: Text(
                  '${discount.round()}% OFF',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 14 / 10,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\u20B9 ${price.round()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                  ),
                ),
                if (oldPrice > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '\u20B9 ${oldPrice.round()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB5B5B5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 16 / 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _detailBodyStyle() {
  return GoogleFonts.inter(
    color: const Color(0xFF0A243F),
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
  );
}

String _beautifyFeatureLabel(String key) {
  return key
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _beautifyVariantKey(String key) {
  return key
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

String _cleanHtmlText(String value) {
  return value
      .replaceAll(RegExp(r'(<br\s*/?>)', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}
