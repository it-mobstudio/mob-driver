import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/filter_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/sort_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/browse_products_components.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/rotating_search_hint.dart';
import 'package:m_o_b_demand_side/shared/view_cart_bar.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<String, Set<String>> _selectedFilterValuesByKey =
      <String, Set<String>>{};

  String _query = '';
  List<BrowseFilterSection> _filterSections = const [];
  ProductSortOption _selectedSortOption = ProductSortOption.priceLowToHigh;
  bool _hasExplicitSortSelection = false;

  String get _initialSearchTerm {
    if ((widget.brandName ?? '').trim().isNotEmpty) {
      return widget.brandName!.trim();
    }
    return widget.searchTerm.trim();
  }

  @override
  void initState() {
    super.initState();
    _query = _initialSearchTerm;
    _searchController.text = _query;
    _productBloc = sl<ProductBloc>()
      ..add(ProductListRequested(searchQuery: _query));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _productBloc.close();
    _searchController.dispose();
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

  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == _query) return;
    setState(() {
      _query = trimmed;
      _selectedFilterValuesByKey.clear();
      _filterSections = const [];
      _hasExplicitSortSelection = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _requestProducts();
  }

  void _requestProducts() {
    _productBloc.add(
      ProductListRequested(
        searchQuery: _query,
        sortBy: _hasExplicitSortSelection
            ? _sortByQueryValue(_selectedSortOption)
            : null,
        queryParameters: _activeBrowseQueryParameters(),
      ),
    );
  }

  Future<void> _changeProductQuantity(
      ProductModel product, int quantity) async {
    if (product.hasVariants && product.mobSku.isEmpty) {
      if (mounted) {
        context.push('${ProductDetailPage.routePath}/${product.slug}');
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
    final productId = int.tryParse(product.id);
    final phoneNumber = AuthSession.instance.phoneNumber;
    if (productId == null || phoneNumber == null) return;
    final (success, failure) = await sl<ProductRepository>().notifyOutOfStock(
      productId: productId,
      phoneNumber: phoneNumber,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "We'll notify you when this is back in stock."
              : failure?.message ?? 'Unable to set up notification.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Filter / sort helpers (mirrors ProductListingPage) ──────────────────────

  BrowseFilterSection? _filterSectionForKey(String key) {
    for (final section in _filterSections) {
      if (section.key == key) return section;
    }
    return null;
  }

  String? _sortByQueryValue(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.popularity:
        return 'popularity';
      case ProductSortOption.priceLowToHigh:
        return 'low_price';
      case ProductSortOption.priceHighToLow:
        return 'high_price';
    }
  }

  List<String> _queryKeysForSection(BrowseFilterSection section) {
    final raw = section.meta['query_keys'];
    if (raw is List) {
      final keys = raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
      if (keys.isNotEmpty) return keys;
    }
    return <String>[section.key];
  }

  Map<String, dynamic> _activeBrowseQueryParameters() {
    final params = <String, dynamic>{};

    _selectedFilterValuesByKey.forEach((sectionKey, selectedValues) {
      if (selectedValues.isEmpty) return;
      final section = _filterSectionForKey(sectionKey);
      if (section == null) return;

      final normalizedValues = selectedValues
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (normalizedValues.isEmpty) return;

      final queryValue = normalizedValues.join(',');
      for (final queryKey in _queryKeysForSection(section)) {
        params[queryKey] = queryValue;
      }
    });

    return params;
  }

  List<String> _filterOptionLabels(String key) {
    for (final section in _filterSections) {
      if (section.key == key) {
        return section.options.map((option) => option.label).toList();
      }
    }
    return const <String>[];
  }

  List<String> _filterOptionLabelsForKeys(List<String> keys) {
    final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();
    final labels = <String>[];

    for (final section in _filterSections) {
      final sectionKey = section.key.toLowerCase();
      if (normalizedKeys.contains(sectionKey)) {
        labels.addAll(
          section.options
              .map((option) => option.label.trim())
              .where((label) => label.isNotEmpty),
        );
      }
    }

    return labels.toSet().take(12).toList();
  }

  Set<String> _selectedValuesForKeys(List<String> keys) {
    final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();
    final values = <String>{};

    _selectedFilterValuesByKey.forEach((key, selectedValues) {
      if (normalizedKeys.contains(key.toLowerCase())) {
        values.addAll(selectedValues);
      }
    });

    return values;
  }

  void _toggleInlineProductType(String label) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) return;

    final targetSection = _filterSectionForKey('brand_segment');
    if (targetSection == null) return;

    final matchingOption = targetSection.options.firstWhere(
      (option) =>
          option.label.trim().toLowerCase() == normalizedLabel.toLowerCase(),
      orElse: () => BrowseFilterOption(
        value: normalizedLabel,
        label: normalizedLabel,
        count: 0,
      ),
    );

    final selectedValues = Set<String>.from(
      _selectedFilterValuesByKey[targetSection.key] ?? <String>{},
    );
    final optionValue = matchingOption.value.trim().isNotEmpty
        ? matchingOption.value.trim()
        : matchingOption.label.trim();

    setState(() {
      if (selectedValues.contains(optionValue)) {
        selectedValues.remove(optionValue);
      } else {
        selectedValues.add(optionValue);
      }
      if (selectedValues.isEmpty) {
        _selectedFilterValuesByKey.remove(targetSection.key);
      } else {
        _selectedFilterValuesByKey[targetSection.key] = selectedValues;
      }
    });
    _requestProducts();
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
    _requestProducts();
  }

  void _clearSelectedFilters() {
    setState(() => _selectedFilterValuesByKey.clear());
    _requestProducts();
  }

  int get _selectedFilterCount {
    return _selectedFilterValuesByKey.values
        .fold<int>(0, (count, values) => count + values.length);
  }

  // ── Bottom sheets ────────────────────────────────────────────────────────

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

  Future<void> _showFilterSection(BrowseFilterSection section) async {
    await _showFilters(initialSectionKey: section.key);
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
          setState(() {
            _selectedSortOption = option;
            _hasExplicitSortSelection = true;
          });
          _requestProducts();
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
              return current.filters.isNotEmpty && previous.filters.isEmpty;
            },
            listener: (context, state) {
              if (state is! ProductListLoaded) return;
              if (state.filters.isNotEmpty) {
                setState(() => _filterSections = state.filters);
              } else if (_filterSections.isEmpty) {
                _productBloc.add(ProductFiltersRequested(searchQuery: _query));
              }
            },
            builder: (context, productState) {
              final isInitialLoading = productState is ProductLoading;
              final products = productState is ProductListLoaded
                  ? productState.products
                  : <ProductModel>[];
              final isLoadingMore = productState is ProductListLoaded &&
                  productState.isLoadingMore;
              final hasMore = productState is ProductListLoaded &&
                  productState.pagination.isNextPage;
              final totalEntries = productState is ProductListLoaded
                  ? productState.pagination.totalEntries
                  : 0;
              final errorMessage = switch (productState) {
                ProductError(:final message) => message,
                _ => null,
              };
              final hasError = errorMessage != null;

              return Stack(
                children: [
                  Column(
                    children: [
                      _SearchHeader(
                        controller: _searchController,
                        onBack: () => context.pop(),
                        onSubmitted: _onSearchSubmitted,
                      ),
                      if (!isInitialLoading && !hasError)
                        _ResultsCountHeader(
                          count:
                              totalEntries > 0 ? totalEntries : products.length,
                          query: _query,
                        ),
                      if (!isInitialLoading && !hasError)
                        BrowseFilterRow(
                          onFilterTap: _showFilters,
                          onSortTap: _showSortOptions,
                          filterSections: _filterSections,
                          selectedValuesByKey: _selectedFilterValuesByKey,
                          onSectionTap: _showFilterSection,
                          selectedFilterCount: _selectedFilterCount,
                          onClearFilters: _clearSelectedFilters,
                        ),
                      Expanded(
                        child: isInitialLoading
                            ? const Center(child: CircularProgressIndicator())
                            : hasError
                                ? ErrorStateView(
                                    message: errorMessage,
                                    onRetry: _requestProducts,
                                  )
                                : products.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No products found for "$_query".',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF57627A),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : BrowseProductFeed(
                                        scrollController: _scrollController,
                                        products: products,
                                        subCategories: const [],
                                        crossAxisCount: 3,
                                        // Full-width quote banner after row 2
                                        // so it stays visible near the top
                                        // instead of trailing every result.
                                        requestCardIndex: 5,
                                        requestCardFullWidth: true,
                                        brandOptions:
                                            _filterOptionLabels('brand'),
                                        productTypeOptions:
                                            _filterOptionLabelsForKeys(
                                                const ['brand_segment']),
                                        selectedProductTypeOptions:
                                            _selectedValuesForKeys(
                                                const ['brand_segment']),
                                        category: _query,
                                        categorySlug: _query,
                                        hasMore: hasMore,
                                        isLoading: isLoadingMore,
                                        loadMoreFailed: false,
                                        cartQtyByProductId: cartQtyByProductId,
                                        cartUpdatingProductId: cartUpdatingKey,
                                        onRetryLoadMore: () => _productBloc.add(
                                            ProductListNextPageRequested()),
                                        onProductTap: (product) => context.push(
                                            '${ProductDetailPage.routePath}/${product.slug}'),
                                        onCartQuantityChanged:
                                            _changeProductQuantity,
                                        onNotifyTap: _handleNotifyTap,
                                        onProductTypeTap:
                                            _toggleInlineProductType,
                                        onRequestTap: () => context
                                            .push(MagicAiQuotePage.routePath),
                                      ),
                      ),
                    ],
                  ),
                  const ViewCartBar(trackNavBarVisibility: false),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onBack,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const AppBackIcon(),
          ),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    // The rotating hint can't live in TextField.hintText
                    // (that only accepts a plain String), so it's laid
                    // over an otherwise-identical, borderless field and
                    // hidden the instant there's real text.
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          if (value.text.isEmpty) const RotatingSearchHint(),
                          TextField(
                            controller: controller,
                            textInputAction: TextInputAction.search,
                            onSubmitted: onSubmitted,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              isCollapsed: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.mic_none),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsCountHeader extends StatelessWidget {
  const _ResultsCountHeader({required this.count, required this.query});

  final int count;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text.rich(
        TextSpan(
          text: '$count results for ',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: '"$query"',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
