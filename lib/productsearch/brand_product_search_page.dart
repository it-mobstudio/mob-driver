import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/network/app_error.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';
import 'package:m_o_b_demand_side/components/item_card.dart';
import 'package:m_o_b_demand_side/loginpage/loginpage_widget.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';

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
  final ProductsRepository _productsRepository = const ProductsRepository();
  final Map<String, int> _cartQtyByProductId = <String, int>{};
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _products = <ProductModel>[];
  bool _isLoading = true;
  String? _error;
  String? _cartUpdatingProductId;

  String get _initialSearchTerm {
    if ((widget.brandName ?? '').trim().isNotEmpty) {
      return widget.brandName!.trim();
    }
    return widget.searchTerm.trim();
  }

  @override
  void initState() {
    super.initState();
    _searchController.text = _initialSearchTerm;
    _loadSearchResults(_initialSearchTerm);
    _fetchCartSnapshot();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchResults(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _productsRepository.searchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _products = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userMessageFromError(
          e,
          fallbackMessage: 'Unable to load products. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCartSnapshot() async {
    if (!AuthSession.instance.isAuthenticated) {
      if (!mounted) return;
      setState(() {
        _cartQtyByProductId.clear();
      });
      return;
    }

    try {
      final response = await GetCartCall.call(userDetails: true);
      if (!response.succeeded) return;

      final data = _extractDataMap(response.jsonBody);
      final qtyMap = _extractQtyMap(data);
      if (!mounted) return;

      setState(() {
        _cartQtyByProductId
          ..clear()
          ..addAll(qtyMap);
      });
    } catch (_) {
      // Keep search results usable even if cart snapshot fails.
    }
  }

  Future<void> _changeProductQuantity(ProductModel product, int quantity) async {
    if (product.hasVariants && product.mobSku.isEmpty) {
      if (mounted) {
        context.go('${ProductDetailPage.routePath}/${product.slug}');
      }
      return;
    }
    if (quantity < 0) return;

    if (!AuthSession.instance.isAuthenticated) {
      if (mounted) {
        context.go(LoginpageWidget.routePath);
      }
      return;
    }

    final productId = product.addToCartProductId;
    if (!mounted) return;

    setState(() {
      _cartUpdatingProductId = productId;
    });

    try {
      final response = await AddToCartCall.call(
        items: [
          {'product': productId, 'quantity': quantity},
        ],
      );

      if (!response.succeeded) {
        throw appExceptionFromApiResponse(
          response,
          fallbackMessage: 'Unable to update cart item. Please try again.',
        );
      }

      final data = _extractDataMap(response.jsonBody);
      final qtyMap = _extractQtyMap(data);
      if (!mounted) return;

      setState(() {
        if (qtyMap.isNotEmpty) {
          _cartQtyByProductId
            ..clear()
            ..addAll(qtyMap);
        } else if (quantity > 0) {
          _cartQtyByProductId[productId] = quantity;
        } else {
          _cartQtyByProductId.remove(productId);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userMessageFromError(
              e,
              fallbackMessage: 'Unable to update cart item. Please try again.',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _cartUpdatingProductId = null;
      });
    }
  }

  Future<void> _handleNotifyTap(ProductModel product) async {
    if (!AuthSession.instance.isAuthenticated) {
      if (mounted) {
        context.go(LoginpageWidget.routePath);
      }
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

  Map<String, dynamic> _extractDataMap(dynamic responseBody) {
    final body = responseBody is Map
        ? Map<String, dynamic>.from(responseBody as Map)
        : <String, dynamic>{};
    return body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;
  }

  Map<String, int> _extractQtyMap(Map<String, dynamic> data) {
    final result = <String, int>{};

    void addItem(dynamic item) {
      if (item is! Map) return;

      final map = Map<String, dynamic>.from(item);
      final productMap = map['product'] is Map
          ? Map<String, dynamic>.from(map['product'] as Map)
          : <String, dynamic>{};
      final productId = (map['vendor_product_id'] ??
              productMap['vendor_product_id'] ??
              map['product_id'] ??
              map['id'])
          ?.toString();
      final qty = int.tryParse(
            (map['quantity'] ?? map['qty'] ?? map['count'] ?? 0).toString(),
          ) ??
          0;
      if (productId == null || productId.isEmpty || qty <= 0) return;

      result[productId] = qty;
    }

    void addFromSubcart(dynamic subcart) {
      if (subcart is! Map) return;
      final items = subcart['items'];
      if (items is! List) return;
      for (final item in items) {
        addItem(item);
      }
    }

    final subcarts = data['subcarts'];
    if (subcarts is List) {
      for (final subcart in subcarts) {
        addFromSubcart(subcart);
      }
    }

    final quoteCart = data['quote_cart'];
    if (quoteCart is Map && quoteCart['items'] is List) {
      for (final item in quoteCart['items'] as List) {
        addItem(item);
      }
    }

    final quickCommerce = data['quick_commerce'];
    if (quickCommerce is Map) {
      if (quickCommerce['subcarts'] is List) {
        for (final subcart in quickCommerce['subcarts'] as List) {
          addFromSubcart(subcart);
        }
      }
      if (quickCommerce['quick_products'] is List) {
        for (final item in quickCommerce['quick_products'] as List) {
          addItem(item);
        }
      }
    } else if (quickCommerce is List) {
      for (final subcart in quickCommerce) {
        addFromSubcart(subcart);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.brandName ?? widget.searchTerm).trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _searchController,
              title: title,
              onBack: () => context.pop(),
              onSubmitted: _loadSearchResults,
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Text(
          'No products found.',
          style: GoogleFonts.inter(
            color: const Color(0xFF57627A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 136 / 276,
      ),
      itemBuilder: (context, index) {
        final product = _products[index];
        return Center(
          child: ItemCard(
            product: product,
            onTap: () => context.go('${ProductDetailPage.routePath}/${product.slug}'),
            quantityResolver: (productId) => _cartQtyByProductId[productId] ?? 0,
            isUpdatingResolver: (productId) => _cartUpdatingProductId == productId,
            onCartQuantityChanged: _changeProductQuantity,
            onNotifyTap: _handleNotifyTap,
          ),
        );
      },
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
