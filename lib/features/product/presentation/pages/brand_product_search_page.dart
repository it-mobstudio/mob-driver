import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/shared/item_card.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/shared/view_cart_bar.dart';

class BrandProductSearchPage extends StatefulWidget {
  const BrandProductSearchPage({
    super.key,
    required this.searchTerm,
    this.brandName,
  });

  static const String routeName = 'BrandProductSearchPage';
  static const String routePath = '/home/product-search';

  final String searchTerm;
  final String? brandName;

  @override
  State<BrandProductSearchPage> createState() => _BrandProductSearchPageState();
}

class _BrandProductSearchPageState extends State<BrandProductSearchPage> {
  late final ProductBloc _productBloc;
  final TextEditingController _searchController = TextEditingController();

  String get _initialSearchTerm {
    if ((widget.brandName ?? '').trim().isNotEmpty) {
      return widget.brandName!.trim();
    }
    return widget.searchTerm.trim();
  }

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>()
      ..add(ProductSearchRequested(query: _initialSearchTerm));
    _searchController.text = _initialSearchTerm;
  }

  @override
  void dispose() {
    _productBloc.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchResults(String query) async {
    _productBloc.add(ProductSearchRequested(query: query));
  }

  Future<void> _changeProductQuantity(ProductModel product, int quantity) async {
    if (product.hasVariants && product.mobSku.isEmpty) {
      if (mounted) context.push('${ProductDetailPage.routePath}/${product.slug}');
      return;
    }
    if (quantity < 0) return;

    if (!AuthSession.instance.isAuthenticated) {
      if (mounted) context.go(LoginpageWidget.routePath);
      return;
    }

    if (!mounted) return;
    final cartItem = CartItem(
      title: product.title,
      imageAsset: product.primaryImageUrl,
      qty: quantity,
      unitPrice: product.vendorPricing.vendorSellingPrice.toDouble(),
      sellerCode: 'STORE',
      vendorProductId: product.addToCartProductId,
    );
    context.read<CartBloc>().add(
      CartQuantityUpdateRequested(item: cartItem, newQty: quantity),
    );
  }

  Future<void> _handleNotifyTap(ProductModel product) async {
    if (!AuthSession.instance.isAuthenticated) {
      if (mounted) context.go(LoginpageWidget.routePath);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.title} notify feature will be enabled soon.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.brandName ?? widget.searchTerm).trim();


    return BlocProvider<ProductBloc>.value(
      value: _productBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _SearchHeader(
                    controller: _searchController,
                    title: title,
                    onBack: () => context.pop(),
                    onSubmitted: _loadSearchResults,
                  ),
                  Expanded(
                    child: BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, state) {
                        return switch (state) {
                          ProductInitial() || ProductLoading() =>
                            const Center(child: CircularProgressIndicator()),
                          ProductError(:final message) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0A243F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ProductSearchLoaded(:final products) when products.isEmpty =>
                            Center(
                              child: Text(
                                'No products found.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF57627A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ProductSearchLoaded(:final products) => GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                              itemCount: products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 20,
                                childAspectRatio: 136 / 276,
                              ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return BlocBuilder<CartBloc, CartState>(
                                  builder: (context, cartState) {
                                    final cart = cartState is CartLoaded
                                        ? cartState
                                        : null;
                                    return Center(
                                      child: ItemCard(
                                        product: product,
                                        onTap: () => context.go(
                                            '${ProductDetailPage.routePath}/${product.slug}'),
                                        quantityResolver: cart != null
                                            ? (id) => cart.quantityFor(id)
                                            : null,
                                        isUpdatingResolver: cart != null
                                            ? (id) => cart.isUpdatingFor(id)
                                            : null,
                                        onCartQuantityChanged: _changeProductQuantity,
                                        onNotifyTap: _handleNotifyTap,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          _ => const Center(child: CircularProgressIndicator()),
                        };
                      },
                    ),
                  ),
                ],
              ),
              const ViewCartBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.title,
    required this.onBack,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String title;
  final VoidCallback onBack;
  final Future<void> Function(String query) onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: title.isEmpty ? 'Search products' : title,
                filled: true,
                fillColor: const Color(0xFFF2F6F9),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
