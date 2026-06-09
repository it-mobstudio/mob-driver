import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/components/item_card.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';
import 'package:m_o_b_demand_side/homepage/widgets/section_title.dart';

class ProductRailSection extends StatefulWidget {
  const ProductRailSection({
    super.key,
    required this.title,
    this.categorySlug,
    this.products,
  }) : assert(
          categorySlug != null || products != null,
          'Either categorySlug or products must be provided.',
        );

  final String title;
  final String? categorySlug;
  final List<ProductModel>? products;

  @override
  State<ProductRailSection> createState() => _ProductRailSectionState();
}

class _ProductRailSectionState extends State<ProductRailSection> {
  static const ProductsRepository _productsRepository = ProductsRepository();
  Future<BrowseProductsResult>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.products == null) {
      _future = _productsRepository.browseProducts(
        categorySlug: widget.categorySlug!,
        page: 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products != null) {
      return _buildSection(products: widget.products!);
    }

    return FutureBuilder<BrowseProductsResult>(
      future: _future,
      builder: (context, snapshot) {
        final products = snapshot.data?.products ?? const <ProductModel>[];
        if (snapshot.hasError && products.isEmpty) {
          return const SizedBox.shrink();
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            products.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: widget.title),
              const SizedBox(
                height: 276,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          );
        }
        return _buildSection(products: products);
      },
    );
  }

  Widget _buildSection({required List<ProductModel> products}) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: widget.title),
        SizedBox(
          height: 276,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ItemCard(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}
