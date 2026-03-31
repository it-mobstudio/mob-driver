import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/components/product_card.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';

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
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, index) {
              final imageUrl = images.isEmpty ? '' : images[index].url;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(images.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0A243F)
                          : const Color(0xFFD0D4DC),
                      borderRadius: BorderRadius.circular(3),
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

class ProductInfoBlock extends StatelessWidget {
  const ProductInfoBlock({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final oldPrice = product.maximumRetailPrice;
    final discount = product.vendorPricing.discount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title
          Text(
            product.title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
            ),
          ),
          const SizedBox(height: 8),
          // IDs
          Text(
            'Mob partner ID: ${product.vendorPricing.bmpId}',
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 2),
          Text(
            'MOBSKU: ${product.mobSku}',
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 12),
          // Rating row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF56A77A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${product.rating}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 12, color: const Color(0xFFD0D4DC)),
              const SizedBox(width: 12),
              Text(
                '${product.reviewCount} reviews',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF0A243F)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹ ${price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A243F),
                ),
              ),
              if (oldPrice > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '₹ ${oldPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB5B5B5),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              if (discount > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '$discount% off',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF01A685),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProductDivider extends StatelessWidget {
  const ProductDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F1F2),
      child: const SizedBox(height: 12),
    );
  }
}

class DeliveryInfoCard extends StatelessWidget {
  const DeliveryInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery time row
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 20, color: Color(0xFF01A685)),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF0A243F)),
                  children: [
                    const TextSpan(text: 'Will be delivered before '),
                    TextSpan(
                      text: 'tomorrow evening',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Yellow purchase banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8E6B6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Purchase from the same seller to save on delivery cost',
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF0A243F)),
            ),
          ),
          const SizedBox(height: 16),
          // Warranty badges
          Row(
            children: [
              _warrantyBadge(Icons.replay_rounded, '7 days free\nreturn'),
              const SizedBox(width: 24),
              _warrantyBadge(Icons.verified_outlined, '2 Years\nwarranty'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _warrantyBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0A243F)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Product Details'),
          const SizedBox(height: 10),
          Text(
            description,
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0A243F)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Specifications'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
              ),
              children: features.entries.map((entry) {
                return TableRow(
                  children: [
                    Container(
                      color: const Color(0xFFE5E5E5),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
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
        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Key Features'),
          const SizedBox(height: 10),
          Text(
            formatted,
            style:
                GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0A243F)),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _SectionHeader(title: 'View similar items'),
        ),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: SizedBox(
                  width: 164,
                  child: ProductCard(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in keys)
            if ((variants[key] ?? const <ProductVariantOption>[])
                .isNotEmpty) ...[
              Text(
                'Select ${_beautifyVariantKey(key)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (variants[key] ?? const <ProductVariantOption>[])
                    .map((option) {
                  final isSelected = selectedVariants[key] == option.value;
                  return ChoiceChip(
                    label: Text(option.value, textAlign: TextAlign.center),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFFB5B5B5),
                        width: 1,
                      ),
                    ),
                    onSelected: (_) => onSelect(key, option),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFE5E5E5),
                    labelStyle: GoogleFonts.inter(color: Colors.black),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
            ),
          ),
        ),
        const Icon(Icons.keyboard_arrow_down_rounded,
            size: 20, color: Color(0xFF0A243F)),
      ],
    );
  }
}
