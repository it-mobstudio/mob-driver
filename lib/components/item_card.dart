import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/components/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';
import 'package:m_o_b_demand_side/components/variant_selection_sheet.dart';

class ItemCard extends StatefulWidget {
  const ItemCard({
    super.key,
    required this.product,
    this.onTap,
    this.cartQuantity,
    this.isCartUpdating = false,
    this.quantityResolver,
    this.isUpdatingResolver,
    this.onCartQuantityChanged,
    this.onNotifyTap,
  });

  final ProductModel product;
  final VoidCallback? onTap;
  final int? cartQuantity;
  final bool isCartUpdating;
  final int Function(String productId)? quantityResolver;
  final bool Function(String productId)? isUpdatingResolver;
  final Future<void> Function(ProductModel product, int quantity)?
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product)? onNotifyTap;

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  int _quantity = 0;

  int _quantityFor(ProductModel product) {
    final resolver = widget.quantityResolver;
    if (resolver != null) {
      return resolver(product.addToCartProductId);
    }
    return widget.cartQuantity ?? _quantity;
  }

  bool _isUpdating(ProductModel product) {
    final resolver = widget.isUpdatingResolver;
    return resolver?.call(product.addToCartProductId) ?? widget.isCartUpdating;
  }

  Future<void> _openVariantSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => VariantSelectionSheet(
        product: widget.product,
        quantityResolver: widget.quantityResolver,
        isUpdatingResolver: widget.isUpdatingResolver,
        onCartQuantityChanged: widget.onCartQuantityChanged,
        onNotifyTap: widget.onNotifyTap,
      ),
    );
  }

  void _increment() {
    if (widget.product.hasVariants) {
      _openVariantSheet();
      return;
    }
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      callback(widget.product, _quantityFor(widget.product) + 1);
      return;
    }
    setState(() {
      _quantity += 1;
    });
  }

  void _decrement() {
    if (_quantityFor(widget.product) <= 0) {
      return;
    }
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      callback(widget.product, _quantityFor(widget.product) - 1);
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
                  child: ProductCartActionButton(
                    product: product,
                    style: ProductCartActionButtonStyle.rail,
                    showCounter:
                        !product.shouldShowNotify && _quantityFor(product) > 0,
                    quantity: _quantityFor(product) > 0
                        ? _quantityFor(product)
                        : 1,
                    isFetchingCart: _isUpdating(product),
                    onAdd: (_) async => _increment(),
                    onAddForQuote: (_) async => _increment(),
                    onQuantityChanged: (quantity) {
                      if (quantity > _quantityFor(product)) {
                        _increment();
                        return;
                      }
                      if (quantity < _quantityFor(product)) {
                        _decrement();
                      }
                    },
                    onNotify: widget.onNotifyTap == null
                        ? null
                        : () => widget.onNotifyTap!(product),
                    onVariantsTap: _openVariantSheet,
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
