import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/shared/item_card.dart';

class SimilarProductsSection extends StatelessWidget {
  const SimilarProductsSection({
    super.key,
    required this.products,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
    this.title = 'View similar items',
    this.quantityResolver,
    this.isUpdatingResolver,
  });

  final List<ProductModel> products;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;

  /// Section heading — override to reuse in other contexts.
  final String title;

  /// Optional BLoC-connected quantity resolver for accurate cart counts.
  final int Function(String productId)? quantityResolver;
  final bool Function(String productId)? isUpdatingResolver;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Text(
              title,
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
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ItemCard(
                    product: products[index],
                    quantityResolver: quantityResolver,
                    isUpdatingResolver: isUpdatingResolver,
                    onCartQuantityChanged: onCartQuantityChanged,
                    onNotifyTap: onNotifyTap,
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
