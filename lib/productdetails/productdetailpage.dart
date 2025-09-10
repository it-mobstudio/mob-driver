import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';
import '../backend/api_requests/api_calls.dart';
import 'package:go_router/go_router.dart';
import '../components/product_card.dart';

class ProductDetailPage extends StatefulWidget {
  static const String routeName = '/ProductDetailPage';
  static const String routePath = '/ProductDetailPage';

  final String slug;
  const ProductDetailPage({super.key, required this.slug});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? product;
  List<dynamic> similarProducts = [];
  bool isLoading = true;
  String? error;
  int cartQuantity = 0;
  // Attribute selection state
  // Dynamic variant selection state
  Map<String, String?> selectedVariants = {};

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails({String? mobSku}) async {
    try {
      final slug = widget.slug;
      if (slug.isEmpty) {
        setState(() {
          error = 'No product slug provided.';
          isLoading = false;
        });
        return;
      }

      final response = await ProductDetailsCall.call(
        slug: slug,
        mobSku: (mobSku != null && mobSku.isNotEmpty) ? mobSku : null,
      );
      final json = response.jsonBody;
      // print("🚀 ~ json:  ${json}");
      final productData = json?['data']?['product'];
      final similarproductData = json?['data']?['similar_products'];
      if (json == null || productData == null) {
        setState(() {
          error = 'No product data found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        product = Map<String, dynamic>.from(productData as Map);
        similarProducts = (similarproductData as List?) ?? [];
        isLoading = false;
      });
      print('Product data: $product');
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  bool _hasVariants(Map<String, dynamic> product) {
    final variants = product['variants'] as Map<String, dynamic>?;
    if (variants == null || variants.isEmpty) return false;
    for (final key in variants.keys) {
      if (variants[key] is List && (variants[key] as List).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : product == null
                  ? const Center(child: Text('No product found.'))
                  : ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        _topHeader(context),
                        const SizedBox(height: 16),
                        _productImagesCarousel(product!),
                        const SizedBox(height: 16),
                        _productInfoBlock(product!),
                        const SizedBox(height: 16),
                        if (_hasVariants(product!)) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFF1F1F2),
                            child: const SizedBox(height: 12),
                          ),
                          const SizedBox(height: 16),
                          _attributeOptionsWidget(product!),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF1F1F2),
                          child: const SizedBox(height: 12),
                        ),

                        const SizedBox(height: 16),
                        _deliveryInfoCard(),

                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF1F1F2),
                          child: const SizedBox(height: 12),
                        ),
                        const SizedBox(height: 16),
                        _keyFeatures(product!),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF1F1F2),
                          child: const SizedBox(height: 12),
                        ),
                        const SizedBox(height: 16),
                        _productDetailsTable(product!),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF1F1F2),
                          child: const SizedBox(height: 12),
                        ),
                        const SizedBox(height: 16),
                        _specifications(product),
                        const SizedBox(height: 24),

                        // _reviewsSection(),
                        // const SizedBox(height: 24),

                        Container(
                          width: double.infinity,
                          color: const Color(0xFFF1F1F2),
                          child: const SizedBox(height: 12),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 8),
                        _similarProductsCarousel(similarProducts),
                        const SizedBox(height: 24),
                      ],
                    ),
    );
  }

  // ───────────────────────── Widgets ─────────────────────────

  Widget _topHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24), // <-- Added 16px padding
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
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

  Widget _productImagesCarousel(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) {
      return Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
        child: SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/Image-coming-soon.png',
                fit: BoxFit.cover),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
      child: SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: PageView.builder(
            itemCount: images.length,
            itemBuilder: (_, index) {
              final img = (images[index] as Map)['image']?.toString() ?? '';
              return img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover)
                  : Image.asset('assets/images/Image-coming-soon.png',
                      fit: BoxFit.cover);
            },
          ),
        ),
      ),
    );
  }

  Widget _productInfoBlock(Map<String, dynamic> product) {
    final vendorPricing = product['vendorPricings'] ?? {};
    final name = product['item_name_title']?.toString() ?? '';
    final price = vendorPricing['vendor_selling_price'] ?? 0;
    final oldPrice = product['maximum_retail_price'] ?? 0;

    final priceStr =
        double.tryParse(price.toString())?.toStringAsFixed(2) ?? '$price';
    final oldPriceStr =
        double.tryParse(oldPrice.toString())?.toStringAsFixed(2) ?? '$oldPrice';

    final discount = vendorPricing['discount'] ?? 0;
    final rating = product['rating'] ?? 0;
    final reviewCount = product['review_count'] ?? 0;
    final mobSKU = product['mob_sku']?.toString() ?? '';
    final BMP = product['vendorPricings']["bmp_id"]?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style:
                  GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("Mob partner ID: " + BMP,
                style: GoogleFonts.inter(fontSize: 12)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("MOBSKU: " + mobSKU,
                style: GoogleFonts.inter(fontSize: 12)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('₹$priceStr',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
              const SizedBox(width: 8),
              if ((oldPrice is num && oldPrice > 0) ||
                  (oldPrice is String && oldPrice.isNotEmpty))
                Text('₹$oldPriceStr',
                    style: GoogleFonts.inter(
                        decoration: TextDecoration.lineThrough,
                        fontSize: 14,
                        color: Colors.grey)),
              const SizedBox(width: 8),
              if ((discount is num && discount > 0) ||
                  (discount is String && discount.toString() != '0'))
                Text('$discount% OFF',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text('$rating ($reviewCount reviews)',
                  style: GoogleFonts.inter(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deliveryInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
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
            Text("Will be delivered before tomorrow evening",
                style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _keyFeatures(product) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Key Features",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            product["product_description"],
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _productDetailsTable(product) {
    final features = product["features"] as Map<String, dynamic>? ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product Details",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
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
                1: FlexColumnWidth(3)
              },
              border: TableBorder(
                horizontalInside:
                    BorderSide(color: Color(0xFFDEDEDE), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              children: features.entries.map((e) {
                return TableRow(
                  children: [
                    Container(
                      color: const Color(0xFFE5E5E5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      child: Text(
                        e.key,
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
                          vertical: 14, horizontal: 12),
                      child: Text(
                        e.value.toString(),
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

  Widget _specifications(product) {
    String bulletPoints = product["product_bullet_points"] ?? '';
    bulletPoints = bulletPoints.replaceAll(
        RegExp(r'(<br>|<Br>|<BR>)', caseSensitive: false), '\n');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24), // <-- Added padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Specifications",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bulletPoints,
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Widget _reviewsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("21 Reviews",
  //           style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
  //       const SizedBox(height: 6),
  //       _reviewTile(
  //           "Satish Kumar", "13 Dec 2024", 4.4, "Durable build quality..."),
  //       _reviewTile("Neh Bhandari", "11 Dec 2024", 4.3,
  //           "Love the adjustable settings..."),
  //     ],
  //   );
  // }

  // Widget _reviewTile(String name, String date, double rating, String comment) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(children: [
  //           const Icon(Icons.star, size: 14, color: Colors.amber),
  //           const SizedBox(width: 4),
  //           Text(rating.toString(),
  //               style: GoogleFonts.inter(
  //                   fontWeight: FontWeight.w500, fontSize: 12)),
  //           const SizedBox(width: 8),
  //           Text(name, style: GoogleFonts.inter(fontSize: 12)),
  //           const Spacer(),
  //           Text(date,
  //               style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
  //         ]),
  //         const SizedBox(height: 4),
  //         Text(comment, style: GoogleFonts.inter(fontSize: 12)),
  //       ],
  //     ),
  //   );
  // }

  Widget _similarProductsCarousel(List<dynamic> products) {
    if (products.isEmpty) {
      return const Text('No similar products found.');
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Products',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final prod = products[index] as Map<String, dynamic>;
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: prod,
                    onTap: () {
                      final slug = prod['slug'] ?? '';
                      GoRouter.of(context).go('/ProductDetailPage/$slug');
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

// ──────────────── Attribute Options Widget ────────────────
  Widget _attributeOptionsWidget(Map<String, dynamic> product) {
    final variants = product['variants'] as Map<String, dynamic>?;

    if (variants == null || variants.isEmpty) {
      return const SizedBox.shrink();
    }

    final variantKeys = variants.keys.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in variantKeys)
            if (variants[key] is List &&
                (variants[key] as List).isNotEmpty) ...[
              Text(
                'Select ${_beautifyVariantKey(key)}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (variants[key] as List).map<Widget>((option) {
                  final value = option['value']?.toString() ?? '';
                  final isSelected = selectedVariants[key] == value;
                  return SizedBox(
                    child: ChoiceChip(
                      label: Text(value, textAlign: TextAlign.center),
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                            color: Color(0xFFB5B5B5), width: 1),
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedVariants[key] = value;
                        });
                        final mobSku = option['mob_sku']?.toString();
                        _fetchProductDetails(mobSku: mobSku);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFE5E5E5),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? Colors.black : Colors.black,
                      ),
                    ),
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
    // Converts snake_case to Title Case for display
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  // Add this method to your _ProductDetailPageState
  Widget _addToCartFooter() {
    final vendorPricing = product?['vendorPricings'] ?? {};
    final price = vendorPricing['vendor_selling_price'] ?? 0;
    final oldPrice = product?['maximum_retail_price'] ?? 0;
    final discount = vendorPricing['discount'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('₹$price',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(width: 8),
                  if ((oldPrice is num && oldPrice > 0) ||
                      (oldPrice is String && oldPrice.isNotEmpty))
                    Text('₹$oldPrice',
                        style: GoogleFonts.inter(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14,
                            color: Colors.grey)),
                  const SizedBox(width: 8),
                  if ((discount is num && discount > 0) ||
                      (discount is String && discount.toString() != '0'))
                    Text('$discount% off',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                  '₹11500', // You can update this to your actual MRP or other info
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black)),
            ],
          ),
          const Spacer(),
          // Add to cart or quantity selector
          cartQuantity == 0
              ? SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      minimumSize: const Size(120, 48),
                    ),
                    onPressed: () {
                      setState(() {
                        cartQuantity = 1;
                      });
                      // Add to cart API call here
                    },
                    child: Text('ADD',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              : Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (cartQuantity > 1) {
                              cartQuantity--;
                            } else {
                              cartQuantity = 0;
                            }
                          });
                          // Update cart API call here
                        },
                      ),
                      Text('$cartQuantity',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            cartQuantity++;
                          });
                          // Update cart API call here
                        },
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
