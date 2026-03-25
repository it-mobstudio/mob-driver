import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

class ProductImagesCarousel extends StatelessWidget {
  const ProductImagesCarousel({
    super.key,
    required this.images,
  });

  final List<ProductImageRef> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/Image-coming-soon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, index) {
              final imageUrl = images[index].url;
              return imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Image.asset(
                      'assets/images/Image-coming-soon.png',
                      fit: BoxFit.cover,
                    );
            },
          ),
        ),
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

    final priceStr =
        double.tryParse(price.toString())?.toStringAsFixed(2) ?? '$price';
    final oldPriceStr =
        double.tryParse(oldPrice.toString())?.toStringAsFixed(2) ?? '$oldPrice';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Mob partner ID: ${product.vendorPricing.bmpId}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'MOBSKU: ${product.mobSku}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '₹$priceStr',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              if (oldPrice > 0)
                Text(
                  '₹$oldPriceStr',
                  style: GoogleFonts.inter(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(width: 8),
              if (discount > 0)
                Text(
                  '$discount% OFF',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${product.rating} (${product.reviewCount} reviews)',
                style: GoogleFonts.inter(fontSize: 12),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFEEF7E9),
        ),
        child: Row(
          children: [
            const Icon(Icons.delivery_dining, size: 20, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              'Will be delivered before tomorrow evening',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(description, style: GoogleFonts.inter(fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(formatted, style: GoogleFonts.inter(fontSize: 12)),
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text('No similar products found.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Products',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: product,
                    onTap: () {
                      GoRouter.of(context).go(
                        '${ProductDetailPage.routePath}/${product.slug}',
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
            if ((variants[key] ?? const <ProductVariantOption>[]).isNotEmpty) ...[
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
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }
}
