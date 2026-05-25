import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';
import 'package:m_o_b_demand_side/homepage/widgets/section_title.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';

class ProductRailSection extends StatefulWidget {
  const ProductRailSection({
    super.key,
    required this.title,
    required this.categorySlug,
  });

  final String title;
  final String categorySlug;

  @override
  State<ProductRailSection> createState() => _ProductRailSectionState();
}

class _ProductRailSectionState extends State<ProductRailSection> {
  static const ProductsRepository _productsRepository = ProductsRepository();
  late final Future<BrowseProductsResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _productsRepository.browseProducts(
      categorySlug: widget.categorySlug,
      page: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BrowseProductsResult>(
      future: _future,
      builder: (context, snapshot) {
        final products = snapshot.data?.products ?? const <ProductModel>[];
        if (snapshot.hasError && products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: widget.title),
            SizedBox(
              height: 276,
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return HomeProductCard(product: products[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class HomeProductCard extends StatelessWidget {
  const HomeProductCard({super.key, required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final mrp = product.maximumRetailPrice;
    final discount = product.vendorPricing.discount;
    return GestureDetector(
      onTap: () => context.go('${ProductDetailPage.routePath}/${product.slug}'),
      child: SizedBox(
        width: 136,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 136,
                  height: 136,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: product.primaryImageUrl.isEmpty
                      ? Image.asset('assets/images/Image-coming-soon.png')
                      : CachedNetworkImage(
                          imageUrl: product.primaryImageUrl,
                          fit: BoxFit.contain,
                          memCacheWidth: 240,
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/Image-coming-soon.png',
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: -20,
                  child: Container(
                    width: 68,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0360E5)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'ADD',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0360E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(-1, 1),
                    ),
                  ],
                ),
                child: Text(
                  '${discount.round()}% OFF',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Rs. ${price.round()}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                if (mrp > 0)
                  Flexible(
                    child: Text(
                      'Rs. ${mrp.round()}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB5B5B5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
