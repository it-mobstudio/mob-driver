import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/network/app_error.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';
import 'package:m_o_b_demand_side/homepage/homepage_widget.dart';
import 'package:m_o_b_demand_side/loginpage/loginpage_widget.dart';
import 'package:m_o_b_demand_side/productdetails/product_detail_page.dart';
import 'package:m_o_b_demand_side/productlisting/filter_bottom_sheet.dart';
import 'package:m_o_b_demand_side/productlisting/sort_bottom_sheet.dart';
import 'package:m_o_b_demand_side/productlisting/widgets/browse_products_components.dart';
import 'package:m_o_b_demand_side/rfq/rfq_form_page.dart';
import 'package:m_o_b_demand_side/widgets/error_state_view.dart';
import 'package:m_o_b_demand_side/widgets/skeleton_loader.dart';

class ProductListingPage extends StatefulWidget {
  const ProductListingPage({
    super.key,
    required this.category,
    required this.slug,
  });

  final String category;
  final String slug;

  static const String routeName = '/ProductListingPage';
  static const String routePath = '/productlisting';

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  final ProductsRepository _productsRepository = const ProductsRepository();
  final ScrollController _scrollController = ScrollController();
  final List<ProductModel> _products = [];
  final List<ProductModel> _loadedProducts = [];
  final List<ProductModel> _baseCategoryProducts = [];
  final Map<String, int> _cartQtyByProductId = <String, int>{};
  final Map<String, Set<String>> _selectedFilterValuesByKey =
      <String, Set<String>>{};

  List<SubCategoryModel> _subCategories = [];
  List<BrowseFilterSection> _filterSections = [];
  int _currentPage = 1;
  int _selectedSubCategoryIndex = 0;
  String? _selectedCategorySlug;
  String? _selectedCategoryName;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _loadMoreFailed = false;
  bool _isLoadingFilters = false;
  String? _error;
  String? _cartUpdatingProductId;
  ProductSortOption _selectedSortOption = ProductSortOption.priceLowToHigh;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchProductFilters(widget.category);
    _fetchCartSnapshot();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_loadMoreFailed &&
        _hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _productsRepository.browseProducts(
        categorySlug: _selectedCategorySlug ?? widget.slug,
        page: _currentPage,
      );
      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _products.clear();
          _loadedProducts.clear();
          if (_selectedCategorySlug == null) {
            _baseCategoryProducts.clear();
          }
        }
        _loadedProducts.addAll(response.products);
        if (_selectedCategorySlug == null) {
          _baseCategoryProducts.addAll(response.products);
        }
        _rebuildVisibleProducts();

        if (response.subCategories.isNotEmpty && _selectedCategorySlug == null) {
          _subCategories = response.subCategories;
        }

        _hasMore = response.pagination.isNextPage;
        if (_hasMore) {
          _currentPage = response.pagination.nextPage > 0
              ? response.pagination.nextPage
              : _currentPage + 1;
        }
        _loadMoreFailed = false;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (_selectedCategorySlug != null && _baseCategoryProducts.isNotEmpty) {
        final fallbackProducts = _filterProductsForSubCategory(
          _baseCategoryProducts,
          _selectedCategoryName ?? _selectedCategorySlug ?? '',
        );
        setState(() {
          _loadedProducts
            ..clear()
            ..addAll(fallbackProducts);
          _rebuildVisibleProducts();
          _hasMore = false;
          _loadMoreFailed = false;
          _isLoading = false;
          _error = null;
        });
        return;
      }

      if (_products.isEmpty) {
        setState(() {
          _error = userMessageFromError(
            e,
            fallbackMessage: 'Unable to load products. Please try again.',
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadMoreFailed = true;
        });
      }
    }
  }

  Future<void> _fetchProductFilters(String search) async {
    if (!mounted || _isLoadingFilters) return;
    setState(() {
      _isLoadingFilters = true;
    });
    try {
      final filters = await _productsRepository.browseProductFilters(
        search: search,
      );
      if (!mounted) return;
      setState(() {
        _filterSections = filters;
        _isLoadingFilters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _filterSections = const <BrowseFilterSection>[];
        _isLoadingFilters = false;
      });
    }
  }

  List<ProductModel> _filterProductsForSubCategory(
    List<ProductModel> products,
    String subCategory,
  ) {
    final key = subCategory.toLowerCase();
    final matched = products.where((product) {
      final haystack = [
        product.title,
        product.slug,
        product.brandSegmentName,
        product.quickCommerceCategoryName,
      ].join(' ').toLowerCase();

      if (key.contains('cement')) {
        return haystack.contains('cement') ||
            haystack.contains('ppc') ||
            haystack.contains('opc');
      }
      if (key.contains('waterproof')) {
        return haystack.contains('waterproof') ||
            haystack.contains('damp') ||
            haystack.contains('crack') ||
            haystack.contains('roof');
      }
      if (key.contains('concrete') || key.contains('admixture')) {
        return haystack.contains('concrete') ||
            haystack.contains('admixture') ||
            haystack.contains('chemical');
      }
      if (key.contains('paint')) {
        return haystack.contains('paint') ||
            haystack.contains('putty') ||
            haystack.contains('primer');
      }

      return haystack.contains(key);
    }).toList();

    return matched.isEmpty ? products : matched;
  }

  Future<void> _selectSubCategory(
    int index,
    SubCategoryModel subCategory,
  ) async {
    final nextSlug = subCategory.browseSlug;
    final isSameSelection =
        _selectedSubCategoryIndex == index && _selectedCategorySlug == nextSlug;
    if (nextSlug.isEmpty || isSameSelection) return;
    if (!mounted) return;

    setState(() {
      _selectedSubCategoryIndex = index;
      _selectedCategorySlug = nextSlug;
      _selectedCategoryName = subCategory.name;
      _products.clear();
      _loadedProducts.clear();
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
      _error = null;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    await Future.wait([
      _fetchProducts(),
      _fetchProductFilters(subCategory.name),
    ]);
  }

  Future<void> _retryInitialLoad() async {
    if (!mounted) return;

    setState(() {
      _products.clear();
      _loadedProducts.clear();
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
      _error = null;
    });
    await _fetchProducts();
    await _fetchCartSnapshot();
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
      // Non-blocking: listing can still render even when cart snapshot fails.
    }
  }

  Future<void> _changeProductQuantity(
    ProductModel product,
    int quantity,
  ) async {
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
      const SnackBar(
        content: Text('Notify feature will be enabled soon.'),
        duration: Duration(seconds: 2),
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

    if (data['items'] is List) {
      for (final item in data['items'] as List) {
        addItem(item);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(child: Text('No category selected.')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                BrowseProductsHeader(
                  category: widget.category,
                  onBack: _goBack,
                  onSearch: () => context.push('/search'),
                ),
                BrowseFilterRow(
                  onFilterTap: () => _showFilters(),
                  onSortTap: () => _showSortOptions(),
                  onBrandTap: () => _showBrandFilters(),
                  onPriceTap: () => _showPriceFilters(),
                  selectedFilterCount: _selectedFilterCount,
                  onClearFilters: _clearSelectedFilters,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
            if (_cartQtyByProductId.isNotEmpty)
              FloatingCartSummary(
                products: _products,
                cartQtyByProductId: _cartQtyByProductId,
                onTap: () => context.go('/cart'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_subCategories.isEmpty && _error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: _retryInitialLoad,
      );
    }

    if (_subCategories.isEmpty && _products.isEmpty && _isLoading) {
      return const ProductGridSkeleton();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SideSubCategoryRail(
          category: widget.category,
          categorySlug: widget.slug,
          subCategories: _subCategories,
          selectedIndex: _selectedSubCategoryIndex,
          onSelected: _selectSubCategory,
        ),
        Expanded(
          child: _buildProductPane(),
        ),
      ],
    );
  }

  Widget _buildProductPane() {
    if (_error != null) {
      return ErrorStateView(
        message: _error!,
        onRetry: _retryInitialLoad,
      );
    }

    return BrowseProductFeed(
      scrollController: _scrollController,
      products: _products,
      subCategories: _subCategories,
      brandOptions: _filterOptionLabels('brand'),
      productTypeOptions: _filterOptionLabels('brand_segment'),
      category: _selectedCategoryName ?? widget.category,
      categorySlug: _selectedCategorySlug ?? widget.slug,
      hasMore: _hasMore,
      isLoading: _isLoading,
      loadMoreFailed: _loadMoreFailed,
      cartQtyByProductId: _cartQtyByProductId,
      cartUpdatingProductId: _cartUpdatingProductId,
      onRetryLoadMore: _fetchProducts,
      onProductTap: (product) {
        context.go('${ProductDetailPage.routePath}/${product.slug}');
      },
      onCartQuantityChanged: _changeProductQuantity,
      onNotifyTap: _handleNotifyTap,
      onRequestTap: () => context.go(RfqFormPage.routePath),
    );
  }

  List<String> _filterOptionLabels(String key) {
    for (final section in _filterSections) {
      if (section.key == key) {
        return section.options.map((option) => option.label).toList();
      }
    }
    return const <String>[];
  }

  void _updateSelectedFilters(Map<String, Set<String>> selectedValuesByKey) {
    setState(() {
      _selectedFilterValuesByKey
        ..clear()
        ..addAll(
          selectedValuesByKey.map(
            (key, value) => MapEntry(key, Set<String>.from(value)),
          ),
        );
      _rebuildVisibleProducts();
    });
  }

  void _clearSelectedFilters() {
    setState(() {
      _selectedFilterValuesByKey.clear();
      _rebuildVisibleProducts();
    });
  }

  int get _selectedFilterCount {
    return _selectedFilterValuesByKey.values.fold<int>(
      0,
      (count, values) => count + values.length,
    );
  }

  void _rebuildVisibleProducts() {
    _products
      ..clear()
      ..addAll(_filteredProducts(_loadedProducts));
    _applySelectedSort();
  }

  List<ProductModel> _filteredProducts(List<ProductModel> products) {
    final activeFilters = _selectedFilterValuesByKey.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();
    if (activeFilters.isEmpty) return List<ProductModel>.from(products);

    return products.where((product) {
      for (final entry in activeFilters) {
        if (!_productMatchesFilter(product, entry.key, entry.value)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _productMatchesFilter(
    ProductModel product,
    String key,
    Set<String> selectedValues,
  ) {
    if (key == 'brand') {
      return _matchesSelectedTokens(
        product.brandName,
        key,
        selectedValues,
      );
    }

    if (key == 'brand_segment') {
      return _matchesSelectedTokens(
        product.brandSegmentName,
        key,
        selectedValues,
      );
    }

    if (_isPriceFilterKey(key)) {
      return _matchesSelectedPrice(product, key, selectedValues);
    }

    final haystack = [
      product.title,
      product.slug,
      product.brandName,
      product.brandSegmentName,
      product.quickCommerceCategoryName,
      product.badgeOption,
      product.features.values.join(' '),
    ].join(' ');

    return _matchesSelectedTokens(haystack, key, selectedValues);
  }

  bool _matchesSelectedTokens(
    String value,
    String key,
    Set<String> selectedValues,
  ) {
    final normalizedValue = value.toLowerCase();
    final tokens = _selectedFilterTokens(key, selectedValues);
    return tokens.any(
      (token) => token.isNotEmpty && normalizedValue.contains(token),
    );
  }

  bool _matchesSelectedPrice(
    ProductModel product,
    String key,
    Set<String> selectedValues,
  ) {
    final price = product.vendorPricing.vendorSellingPrice;
    final section = _filterSectionForKey(key);

    for (final selectedValue in selectedValues) {
      final option = section == null
          ? null
          : _filterOptionForValue(section, selectedValue);
      final range = _priceRangeFromText(
        [
          selectedValue,
          if (option != null) option.label,
        ].join(' '),
      );
      if (range == null) continue;

      final min = range.min;
      final max = range.max;
      if ((min == null || price >= min) && (max == null || price <= max)) {
        return true;
      }
    }

    return false;
  }

  Set<String> _selectedFilterTokens(String key, Set<String> selectedValues) {
    final section = _filterSectionForKey(key);
    final tokens = <String>{};

    for (final selectedValue in selectedValues) {
      tokens.add(selectedValue.toLowerCase());
      final option = section == null
          ? null
          : _filterOptionForValue(section, selectedValue);
      if (option != null) {
        tokens.add(option.label.toLowerCase());
      }
    }

    return tokens;
  }

  BrowseFilterSection? _filterSectionForKey(String key) {
    for (final section in _filterSections) {
      if (section.key == key) return section;
    }
    return null;
  }

  bool _isPriceFilterKey(String key) {
    final normalizedKey = key.toLowerCase();
    if (normalizedKey == 'price' || normalizedKey.contains('price')) {
      return true;
    }
    final section = _filterSectionForKey(key);
    final label = section?.label.toLowerCase() ?? '';
    return label == 'price' || label.contains('price');
  }

  BrowseFilterOption? _filterOptionForValue(
    BrowseFilterSection section,
    String value,
  ) {
    for (final option in section.options) {
      if (option.value == value) return option;
    }
    return null;
  }

  _PriceRange? _priceRangeFromText(String value) {
    final numbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(value.replaceAll(',', ''))
        .map((match) => num.tryParse(match.group(0) ?? ''))
        .whereType<num>()
        .toList();
    if (numbers.isEmpty) return null;

    final lowerValue = value.toLowerCase();
    if (numbers.length == 1) {
      if (lowerValue.contains('above') ||
          lowerValue.contains('over') ||
          lowerValue.contains('+')) {
        return _PriceRange(min: numbers.first);
      }
      if (lowerValue.contains('below') ||
          lowerValue.contains('under') ||
          lowerValue.contains('less')) {
        return _PriceRange(max: numbers.first);
      }
      return _PriceRange(min: numbers.first, max: numbers.first);
    }

    numbers.sort();
    return _PriceRange(min: numbers.first, max: numbers.last);
  }

  void _applySelectedSort() {
    switch (_selectedSortOption) {
      case ProductSortOption.popularity:
        _products.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case ProductSortOption.priceLowToHigh:
        _products.sort(
          (a, b) => a.vendorPricing.vendorSellingPrice.compareTo(
            b.vendorPricing.vendorSellingPrice,
          ),
        );
        break;
      case ProductSortOption.priceHighToLow:
        _products.sort(
          (a, b) => b.vendorPricing.vendorSellingPrice.compareTo(
            a.vendorPricing.vendorSellingPrice,
          ),
        );
        break;
      case ProductSortOption.ratings:
        _products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomepageWidget.routePath);
    }
  }

  Future<void> _showFilters({String? initialSectionKey}) async {
    if (_filterSections.isEmpty) {
      await _fetchProductFilters(_selectedCategoryName ?? widget.category);
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FilterBottomSheet(
        sections: _filterSections,
        initialSectionKey: initialSectionKey,
        selectedValuesByKey: _selectedFilterValuesByKey,
        onSelectionChanged: _updateSelectedFilters,
      ),
    );
  }

  Future<void> _showBrandFilters() async {
    await _showSingleFilterSheet(
      sectionKey: 'brand',
      title: 'Brands',
    );
  }

  Future<void> _showPriceFilters() async {
    if (_filterSections.isEmpty) {
      await _fetchProductFilters(_selectedCategoryName ?? widget.category);
    }
    if (!mounted) return;

    await _showSingleFilterSheet(
      sectionKey: _priceFilterKey(),
      title: 'Price',
    );
  }

  Future<void> _showSingleFilterSheet({
    required String sectionKey,
    required String title,
  }) async {
    if (_filterSections.isEmpty) {
      await _fetchProductFilters(_selectedCategoryName ?? widget.category);
    }
    if (!mounted) return;

    final sections = _filterSections
        .where((section) => section.key == sectionKey)
        .toList(growable: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FilterBottomSheet(
        sections: sections,
        title: title,
        showSidebar: false,
        selectedValuesByKey: _selectedFilterValuesByKey,
        onSelectionChanged: _updateSelectedFilters,
      ),
    );
  }

  String _priceFilterKey() {
    for (final section in _filterSections) {
      final key = section.key.toLowerCase();
      final label = section.label.toLowerCase();
      if (key == 'price' ||
          key.contains('price') ||
          label == 'price' ||
          label.contains('price')) {
        return section.key;
      }
    }
    return 'price';
  }

  Future<void> _showSortOptions() async {
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      backgroundColor: Colors.transparent,
      builder: (_) => SortBottomSheet(
        selectedOption: _selectedSortOption,
        onOptionSelected: (option) {
          if (!mounted) return;
          setState(() {
            _selectedSortOption = option;
            _applySelectedSort();
          });
        },
      ),
    );
  }
}

class _PriceRange {
  const _PriceRange({this.min, this.max});

  final num? min;
  final num? max;
}
