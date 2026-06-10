import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/filter_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/sort_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/browse_products_components.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_form_page.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';

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
  late final ProductBloc _productBloc;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Set<String>> _selectedFilterValuesByKey =
      <String, Set<String>>{};

  List<SubCategoryModel> _subCategories = const [];
  List<BrowseFilterSection> _filterSections = const [];
  int _selectedSubCategoryIndex = 0;
  String? _selectedCategorySlug;
  String? _selectedCategoryName;
  String? _filterSearchTerm;
  ProductSortOption _selectedSortOption = ProductSortOption.priceLowToHigh;

  @override
  void initState() {
    super.initState();
    _productBloc = sl<ProductBloc>()
      ..add(ProductListRequested(categoryName: widget.slug));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _productBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = _productBloc.state;
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        state is ProductListLoaded &&
        !state.isLoadingMore &&
        state.pagination.isNextPage) {
      _productBloc.add(ProductListNextPageRequested());
    }
  }

  void _selectSubCategory(int index, SubCategoryModel subCategory) {
    final nextSlug = subCategory.browseSlug;
    final isSameSelection =
        _selectedSubCategoryIndex == index && _selectedCategorySlug == nextSlug;
    if (nextSlug.isEmpty || isSameSelection) return;

    setState(() {
      _selectedSubCategoryIndex = index;
      _selectedCategorySlug = nextSlug;
      _selectedCategoryName = subCategory.name;
      _filterSearchTerm = subCategory.name;
      _filterSections = const [];
      _selectedFilterValuesByKey.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _productBloc.add(ProductListRequested(categoryName: nextSlug));
  }

  void _retryInitialLoad() {
    setState(() {
      _filterSections = const [];
      _selectedFilterValuesByKey.clear();
    });
    _productBloc.add(
      ProductListRequested(
        categoryName: _selectedCategorySlug ?? widget.slug,
      ),
    );
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
      const SnackBar(
        content: Text('Notify feature will be enabled soon.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Filter / sort helpers ──────────────────────────────────────────────────

  List<ProductModel> _computeVisibleProducts(List<ProductModel> raw) {
    return _sorted(_filteredProducts(raw));
  }

  List<ProductModel> _sorted(List<ProductModel> products) {
    final list = List<ProductModel>.from(products);
    switch (_selectedSortOption) {
      case ProductSortOption.popularity:
        list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case ProductSortOption.priceLowToHigh:
        list.sort((a, b) => a.vendorPricing.vendorSellingPrice
            .compareTo(b.vendorPricing.vendorSellingPrice));
      case ProductSortOption.priceHighToLow:
        list.sort((a, b) => b.vendorPricing.vendorSellingPrice
            .compareTo(a.vendorPricing.vendorSellingPrice));
      case ProductSortOption.ratings:
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
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
      return _matchesSelectedTokens(product.brandName, key, selectedValues);
    }
    if (key == 'brand_segment') {
      return _matchesSelectedTokens(
          product.brandSegmentName, key, selectedValues);
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
      final option =
          section == null ? null : _filterOptionForValue(section, selectedValue);
      final range = _priceRangeFromText(
        [selectedValue, if (option != null) option.label].join(' '),
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
      final option =
          section == null ? null : _filterOptionForValue(section, selectedValue);
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
    });
  }

  void _clearSelectedFilters() {
    setState(() => _selectedFilterValuesByKey.clear());
  }

  int get _selectedFilterCount {
    return _selectedFilterValuesByKey.values
        .fold<int>(0, (count, values) => count + values.length);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(HomepageWidget.routePath);
    }
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  Future<void> _showFilters({String? initialSectionKey}) async {
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
    await _showSingleFilterSheet(sectionKey: 'brand', title: 'Brands');
  }

  Future<void> _showPriceFilters() async {
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
      barrierColor: Colors.black.withValues(alpha: 0.6),
      backgroundColor: Colors.transparent,
      builder: (_) => SortBottomSheet(
        selectedOption: _selectedSortOption,
        onOptionSelected: (option) {
          if (!mounted) return;
          setState(() => _selectedSortOption = option);
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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

    final cartState = context.watch<CartBloc>().state;
    final cartQtyByProductId = cartState is CartLoaded
        ? {
            for (final item in cartState.summary.items)
              item.vendorProductId: item.qty
          }
        : const <String, int>{};
    final cartUpdatingKey =
        cartState is CartLoaded ? cartState.updatingItemKey : null;

    return BlocProvider<ProductBloc>.value(
      value: _productBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<ProductBloc, ProductState>(
            listenWhen: (previous, current) {
              if (current is! ProductListLoaded) return false;
              if (previous is! ProductListLoaded) return true;
              if (current.filters.isNotEmpty && previous.filters.isEmpty) {
                return true;
              }
              if (current.subCategories.length != previous.subCategories.length) {
                return true;
              }
              return false;
            },
            listener: (context, state) {
              if (state is! ProductListLoaded) return;
              setState(() {
                if (state.subCategories.isNotEmpty) {
                  _subCategories = state.subCategories;
                }
                if (state.filters.isNotEmpty) {
                  _filterSections = state.filters;
                }
              });
              if (state.filters.isEmpty) {
                _productBloc.add(ProductFiltersRequested(
                  search: _filterSearchTerm ?? widget.category,
                ));
              }
            },
            builder: (context, productState) {
              final rawProducts = productState is ProductListLoaded
                  ? productState.products
                  : <ProductModel>[];
              final visibleProducts = _computeVisibleProducts(rawProducts);
              final isInitialLoading = productState is ProductLoading;
              final isLoadingMore = productState is ProductListLoaded &&
                  productState.isLoadingMore;
              final hasMore = productState is ProductListLoaded &&
                  productState.pagination.isNextPage;
              final errorMessage = switch (productState) {
                ProductError(:final message) => message,
                _ => null,
              };
              final hasError = errorMessage != null;

              return Stack(
                children: [
                  Column(
                    children: [
                      BrowseProductsHeader(
                        category: widget.category,
                        onBack: _goBack,
                        onSearch: () => context.push('/search'),
                      ),
                      BrowseFilterRow(
                        onFilterTap: _showFilters,
                        onSortTap: _showSortOptions,
                        onBrandTap: _showBrandFilters,
                        onPriceTap: _showPriceFilters,
                        selectedFilterCount: _selectedFilterCount,
                        onClearFilters: _clearSelectedFilters,
                      ),
                      Expanded(
                        child: _buildBody(
                          visibleProducts: visibleProducts,
                          isInitialLoading: isInitialLoading,
                          isLoadingMore: isLoadingMore,
                          hasMore: hasMore,
                          hasError: hasError,
                          errorMessage: errorMessage,
                          cartQtyByProductId: cartQtyByProductId,
                          cartUpdatingKey: cartUpdatingKey,
                        ),
                      ),
                    ],
                  ),
                  if (cartQtyByProductId.isNotEmpty)
                    FloatingCartSummary(
                      products: visibleProducts,
                      cartQtyByProductId: cartQtyByProductId,
                      onTap: () => context.go('/cart'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<ProductModel> visibleProducts,
    required bool isInitialLoading,
    required bool isLoadingMore,
    required bool hasMore,
    required bool hasError,
    String? errorMessage,
    required Map<String, int> cartQtyByProductId,
    required String? cartUpdatingKey,
  }) {
    if (_subCategories.isEmpty && hasError) {
      return ErrorStateView(
        message: errorMessage!,
        onRetry: _retryInitialLoad,
      );
    }

    if (_subCategories.isEmpty && visibleProducts.isEmpty && isInitialLoading) {
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
        Expanded(child: _buildProductPane(
          visibleProducts: visibleProducts,
          isLoadingMore: isLoadingMore,
          hasMore: hasMore,
          hasError: hasError,
          errorMessage: errorMessage,
          cartQtyByProductId: cartQtyByProductId,
          cartUpdatingKey: cartUpdatingKey,
        )),
      ],
    );
  }

  Widget _buildProductPane({
    required List<ProductModel> visibleProducts,
    required bool isLoadingMore,
    required bool hasMore,
    required bool hasError,
    String? errorMessage,
    required Map<String, int> cartQtyByProductId,
    required String? cartUpdatingKey,
  }) {
    if (hasError) {
      return ErrorStateView(
        message: errorMessage!,
        onRetry: _retryInitialLoad,
      );
    }

    return BrowseProductFeed(
      scrollController: _scrollController,
      products: visibleProducts,
      subCategories: _subCategories,
      brandOptions: _filterOptionLabels('brand'),
      productTypeOptions: _filterOptionLabels('brand_segment'),
      category: _selectedCategoryName ?? widget.category,
      categorySlug: _selectedCategorySlug ?? widget.slug,
      hasMore: hasMore,
      isLoading: isLoadingMore,
      loadMoreFailed: false,
      cartQtyByProductId: cartQtyByProductId,
      cartUpdatingProductId: cartUpdatingKey,
      onRetryLoadMore: () => _productBloc.add(ProductListNextPageRequested()),
      onProductTap: (product) {
        context.go('${ProductDetailPage.routePath}/${product.slug}');
      },
      onCartQuantityChanged: _changeProductQuantity,
      onNotifyTap: _handleNotifyTap,
      onRequestTap: () => context.go(RfqFormPage.routePath),
    );
  }
}

class _PriceRange {
  const _PriceRange({this.min, this.max});

  final num? min;
  final num? max;
}
