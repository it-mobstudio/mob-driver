import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';
import '../backend/api_requests/api_calls.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final slug = widget.slug;
      if (slug.isEmpty) {
        setState(() {
          error = 'No product slug provided.';
          isLoading = false;
        });
        return;
      }

      final response = await ProductDetailsCall.call(slug: slug);
      final json = response.jsonBody;

      if (json == null || json['product'] == null) {
        setState(() {
          error = 'No product data found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        product = Map<String, dynamic>.from(json['product'] as Map);
        similarProducts = (json['similar_products'] as List?) ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      // Keep bottom nav visible; product detail is under Home tab
      currentIndex: 0,
      // No AppBar; custom header below
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : product == null
                  ? const Center(child: Text('No product found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _topHeader(context),
                        const SizedBox(height: 16),
                        _productImagesCarousel(product!),
                        const SizedBox(height: 16),
                        _productInfoBlock(product!),
                        const SizedBox(height: 16),
                        _deliveryInfoCard(),
                        const SizedBox(height: 16),
                        _keyFeatures(),
                        const SizedBox(height: 16),
                        _productDetailsTable(),
                        const SizedBox(height: 16),
                        _specifications(),
                        const SizedBox(height: 16),
                        _reviewsSection(),
                        const SizedBox(height: 24),
                        Text('Similar Products',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        _similarProductsCarousel(similarProducts),
                        const SizedBox(height: 24),
                      ],
                    ),
    );
  }

  // ───────────────────────── Widgets ─────────────────────────

  Widget _topHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Prefer GoRouter if present
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              Navigator.of(context).maybePop();
            }
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
    );
  }

  Widget _productImagesCarousel(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>?;
    if (images == null || images.isEmpty) {
      return SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/images/Image-coming-soon.png',
              fit: BoxFit.cover),
        ),
      );
    }

    return SizedBox(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name,
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange)),
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
    );
  }

  Widget _deliveryInfoCard() {
    return Container(
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
    );
  }

  Widget _keyFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Features",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          "Relax in a shower that fully soaks, restores, and targets sore muscles—all at the touch of a button...",
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ],
    );
  }

  Widget _productDetailsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Product Details",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
          children: [
            _tableRow("Type", "Multifunction showerhead"),
            _tableRow("Finish", "Polished Chrome"),
            _tableRow("Brand", "Kohler"),
            _tableRow("Material", "Wood"),
            _tableRow("Color", "Polished Chrome"),
          ],
        )
      ],
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value,
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _specifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Specifications",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          "• Multifunction showerhead with advanced spray engine...\n"
          "• Deep massage streams...",
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ],
    );
  }

  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("21 Reviews",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _reviewTile(
            "Satish Kumar", "13 Dec 2024", 4.4, "Durable build quality..."),
        _reviewTile("Neh Bhandari", "11 Dec 2024", 4.3,
            "Love the adjustable settings..."),
      ],
    );
  }

  Widget _reviewTile(String name, String date, double rating, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(rating.toString(),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 12)),
            const SizedBox(width: 8),
            Text(name, style: GoogleFonts.inter(fontSize: 12)),
            const Spacer(),
            Text(date,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text(comment, style: GoogleFonts.inter(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _similarProductsCarousel(List<dynamic> products) {
    if (products.isEmpty) {
      return const Text('No similar products found.');
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final prod = products[index] as Map<String, dynamic>;
          final img =
              (prod['images'] != null && (prod['images'] as List).isNotEmpty)
                  ? ((prod['images'][0] as Map)['image']?.toString() ?? '')
                  : '';
          final name = prod['item_name_title']?.toString() ?? '';
          final vendor = prod['vendorPricings'] ?? {};
          final price = vendor['vendor_selling_price'] ?? 0;
          final oldPrice = vendor['maximum_retail_price'] ?? 0;
          final discount = vendor['discount'] ?? 0;

          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: img.isNotEmpty
                      ? Image.network(img, height: 80, fit: BoxFit.cover)
                      : Image.asset('assets/images/Image-coming-soon.png',
                          height: 80),
                ),
                const SizedBox(height: 8),
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('₹$price',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                if ((oldPrice is num && oldPrice > 0) ||
                    (oldPrice is String && oldPrice.toString().isNotEmpty))
                  Text('₹$oldPrice',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                if ((discount is num && discount > 0) ||
                    (discount is String && discount.toString() != '0'))
                  Text('$discount% OFF',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.orange)),
              ],
            ),
          );
        },
      ),
    );
  }
}
