import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  Future<void> _addToCart(BuildContext context) async {
    final response = await AddToCartCall.call(
      items: [
        {"product": product.addToCartProductId, "quantity": 1}
      ],
    );
    if (!context.mounted) return;
    final message = (response.jsonBody?['message'] ??
            response.jsonBody?['detail'] ??
            'Something went wrong')
        .toString();
    final isSuccess = response.jsonBody?['status'] == true;
    AnalyticsService.instance.logAddToCart(
      productId: product.addToCartProductId.toString(),
      slug: product.slug,
      price: product.vendorPricing.vendorSellingPrice.toDouble(),
      success: isSuccess,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = product.title;
    final price = product.vendorPricing.vendorSellingPrice;
    final oldPrice = product.maximumRetailPrice;
    final priceStr = '₹${price.toStringAsFixed(2)}';
    final oldPriceStr = '₹${oldPrice.toStringAsFixed(2)}';
    final discount = product.vendorPricing.discount;
    final delivery = product.vendorPricing.fullfillmentLatency;
    final imageUrl = product.primaryImageUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 164,
        height: 320,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Image background area
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Product image
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              height: 132,
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 264,
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

            // Discount badge
            if (discount != 0)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF01A685),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(2),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$discount% OFF',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Add to cart button
            Positioned(
              right: 8,
              top: 148,
              child: GestureDetector(
                onTap: () => _addToCart(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Color(0xFF0A243F),
                  ),
                ),
              ),
            ),

            // Product info
            Positioned(
              top: 192,
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A243F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        priceStr,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                      if (oldPrice != 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          oldPriceStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFB5B5B5),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flash_on,
                          size: 10, color: Color(0xFFFAA500)),
                      const SizedBox(width: 2),
                      Text(
                        delivery,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
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
