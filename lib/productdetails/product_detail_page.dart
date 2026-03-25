import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/features/products/controllers/product_detail_controller.dart';
import 'package:m_o_b_demand_side/features/products/widgets/product_detail_sections.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

class ProductDetailPage extends StatefulWidget {
  static const String routeName = 'ProductDetailPage';
  static const String routePath = '/product-detail';

  final String slug;

  const ProductDetailPage({super.key, required this.slug});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductDetailController(slug: widget.slug);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error != null) {
            return Center(child: Text('Error: ${_controller.error}'));
          }

          final product = _controller.product;
          if (product == null) {
            return const Center(child: Text('No product found.'));
          }

          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              ProductDetailTopHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              ProductImagesCarousel(images: product.images),
              const SizedBox(height: 16),
              ProductInfoBlock(product: product),
              if (product.hasVariants) ...[
                const SizedBox(height: 16),
                const ProductDivider(),
                const SizedBox(height: 16),
                VariantOptionsSection(
                  variants: product.variants,
                  selectedVariants: _controller.selectedVariants,
                  onSelect: (key, option) => _controller.selectVariant(
                    key: key,
                    option: option,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const ProductDivider(),
              const SizedBox(height: 16),
              const DeliveryInfoCard(),
              const SizedBox(height: 16),
              const ProductDivider(),
              const SizedBox(height: 16),
              KeyFeaturesSection(description: product.productDescription),
              const SizedBox(height: 16),
              const ProductDivider(),
              const SizedBox(height: 16),
              ProductDetailsTableSection(features: product.features),
              const SizedBox(height: 16),
              const ProductDivider(),
              const SizedBox(height: 16),
              SpecificationsSection(bulletPoints: product.productBulletPoints),
              const SizedBox(height: 24),
              const ProductDivider(),
              const SizedBox(height: 16),
              SimilarProductsSection(products: _controller.similarProducts),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
