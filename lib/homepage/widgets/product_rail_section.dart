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

class HomeProductCard extends StatefulWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.cartQuantity,
    this.isCartUpdating = false,
    this.onCartQuantityChanged,
    this.onNotifyTap,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final int? cartQuantity;
  final bool isCartUpdating;
  final Future<void> Function(int quantity)? onCartQuantityChanged;
  final Future<void> Function()? onNotifyTap;

  @override
  State<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends State<HomeProductCard> {
  int _quantity = 0;

  int get _effectiveQuantity => widget.cartQuantity ?? _quantity;

  void _increment() {
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      callback(_effectiveQuantity + 1);
      return;
    }
    setState(() {
      _quantity += 1;
    });
  }

  void _decrement() {
    if (_effectiveQuantity <= 0) {
      return;
    }
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      callback(_effectiveQuantity - 1);
      return;
    }
    setState(() {
      _quantity -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product.vendorPricing.vendorSellingPrice;
    final mrp = product.maximumRetailPrice;
    final discount = product.vendorPricing.discount;
    return SizedBox(
      width: 136,
      height: 276,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 156,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: widget.onTap ??
                      () => context
                          .go('${ProductDetailPage.routePath}/${product.slug}'),
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: product.primaryImageUrl.isEmpty
                          ? Image.asset(
                              'assets/images/Image-coming-soon.png',
                              fit: BoxFit.contain,
                            )
                          : CachedNetworkImage(
                              imageUrl: product.primaryImageUrl,
                              fit: BoxFit.contain,
                              memCacheWidth: 240,
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/Image-coming-soon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _HomeRailCartButton(
                    quantity: _effectiveQuantity,
                    isBusy: widget.isCartUpdating,
                    hasVariants: product.hasVariants,
                    variantCount: product.variants.values.fold<int>(
                      0,
                      (sum, options) => sum + options.length,
                    ),
                    shouldShowNotify: product.shouldShowNotify,
                    onAdd: _increment,
                    onIncrement: _increment,
                    onDecrement: _decrement,
                    onNotify: widget.onNotifyTap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Text(
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
                  height: 14 / 10,
                ),
              ),
            )
          else
            const SizedBox(height: 18),
          const SizedBox(height: 8),
          SizedBox(
            height: 26,
            child: Row(
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
                const SizedBox(width: 12),
                if (mrp > 0)
                  Flexible(
                    child: Text(
                      '\u20B9 ${mrp.round()}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB5B5B5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFFB5B5B5),
                        decorationThickness: 1,
                      ),
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

class _HomeRailCartButton extends StatelessWidget {
  const _HomeRailCartButton({
    required this.quantity,
    required this.isBusy,
    required this.hasVariants,
    required this.variantCount,
    required this.shouldShowNotify,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onNotify,
  });

  final int quantity;
  final bool isBusy;
  final bool hasVariants;
  final int variantCount;
  final bool shouldShowNotify;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Future<void> Function()? onNotify;

  @override
  Widget build(BuildContext context) {
    if (shouldShowNotify) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isBusy ? null : onNotify,
        child: Container(
          width: 68,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0360E5)),
          ),
          child: isBusy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'NOTIFY',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0360E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 16 / 10,
                  ),
                ),
        ),
      );
    }

    if (quantity <= 0) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isBusy ? null : onAdd,
        child: Container(
          width: 68,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0360E5)),
          ),
          child: isBusy
              ? const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ADD',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0360E5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                      ),
                    ),
                    if (hasVariants && variantCount > 0)
                      Container(
                        width: double.infinity,
                        height: 12,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0x1A0360E5),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          '$variantCount options',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7E7E7E),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            height: 12 / 8,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    }

    return Container(
      width: 91,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0360E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isBusy
          ? const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuantityControlTapTarget(
                  icon: Icons.remove,
                  onTap: onDecrement,
                ),
                Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                _QuantityControlTapTarget(
                  icon: Icons.add,
                  onTap: onIncrement,
                ),
              ],
            ),
    );
  }
}

class _QuantityControlTapTarget extends StatelessWidget {
  const _QuantityControlTapTarget({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 40,
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
