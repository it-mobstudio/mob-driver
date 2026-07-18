import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/shared/item_card.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/section_title.dart';

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
  Future<List<ProductModel>>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.products == null) {
      _future = _fetchProducts();
    }
  }

  Future<List<ProductModel>> _fetchProducts() async {
    final (result, _) = await sl<ProductRepository>().browseProducts(
      categorySlug: widget.categorySlug!,
      page: 1,
    );
    return result?.products ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products != null) {
      return _buildSection(products: widget.products!);
    }

    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <ProductModel>[];
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
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ],
          );
        }
        return _buildSection(products: products);
      },
    );
  }

  Widget _buildSection({required List<ProductModel> products}) {
    if (products.isEmpty) return const SizedBox.shrink();

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
            itemBuilder: (ctx, index) {
              final product = products[index];
              // BlocBuilder here so each card subscribes to CartBloc directly.
              // ListView.separated caches its children and does NOT propagate
              // parent widget updates to already-built items — so watching at
              // the ProductRailSection level never reaches the cards after first
              // render. Each BlocBuilder is an independent subscriber.
              return BlocBuilder<CartBloc, CartState>(
                buildWhen: (previous, current) {
                  if (previous is! CartLoaded || current is! CartLoaded) {
                    return previous.runtimeType != current.runtimeType;
                  }
                  final productId = product.addToCartProductId;
                  return previous.quantityFor(productId) !=
                          current.quantityFor(productId) ||
                      previous.isUpdatingFor(productId) !=
                          current.isUpdatingFor(productId);
                },
                builder: (context, cartState) {
                  final cart = cartState is CartLoaded ? cartState : null;
                  return ItemCard(
                    product: product,
                    quantityResolver:
                        cart != null ? (id) => cart.quantityFor(id) : null,
                    isUpdatingResolver:
                        cart != null ? (id) => cart.isUpdatingFor(id) : null,
                    onCartQuantityChanged: (p, qty) async {
                      context.read<CartBloc>().add(
                            CartQuantityUpdateRequested(
                              item: CartItem(
                                title: p.title,
                                imageAsset: p.primaryImageUrl,
                                qty: qty,
                                unitPrice: p.vendorPricing.vendorSellingPrice
                                    .toDouble(),
                                sellerCode: 'STORE',
                                vendorProductId: p.addToCartProductId,
                              ),
                              newQty: qty,
                            ),
                          );
                    },
                    onNotifyTap: (_) async {},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
