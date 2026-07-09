import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/filter_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/sort_bottom_sheet.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/browse_products_components.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_page.dart';
import 'package:m_o_b_demand_side/shared/back_to_top_button.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';
import 'package:m_o_b_demand_side/shared/view_cart_bar.dart';

class ProductListingPage extends StatefulWidget {
  const ProductListingPage({
    super.key,
    required this.category,
    required this.slug,
    this.initialSubCategorySlug,
    this.initialSubCategoryName,
  });

  final String category;
  final String slug;
  final String? initialSubCategorySlug;
  final String? initialSubCategoryName;

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
  String? _selectedSubCategorySlug;
  String? _selectedSubCategoryName;
  ProductSortOption _selectedSortOption = ProductSortOption.priceLowToHigh;
  bool _hasExplicitSortSelection = false;
  bool _showBackToTop = false;

  static const double _scrollThreshold = 400;

  @override
  void initState() {
    super.initState();
    _selectedSubCategorySlug = widget.initialSubCategorySlug;
    _selectedSubCategoryName = widget.initialSubCategoryName;
    _productBloc = sl<ProductBloc>()
      ..add(
        ProductListRequested(
          categorySlug: widget.slug,
          subCategory: _selectedSubCategorySlug,
        ),
      );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _productBloc.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pixels = _scrollController.position.pixels;
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      navBarVisible.value = false;
    } else if (direction == ScrollDirection.forward) {
      navBarVisible.value = true;
    }
    // Hide while user is actively scrolling up (toward top)
    final show =
        pixels > _scrollThreshold && direction != ScrollDirection.forward;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);

    final state = _productBloc.state;
    if (pixels >= _scrollController.position.maxScrollExtent - 200 &&
        state is ProductListLoaded &&
        !state.isLoadingMore &&
        state.pagination.isNextPage) {
      _productBloc.add(ProductListNextPageRequested());
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectSubCategory(int index, SubCategoryModel subCategory) {
    final isAllSelection = index == 0;
    final nextSlug = isAllSelection ? null : subCategory.browseSlug;
    final isSameSelection = _selectedSubCategoryIndex == index &&
        _selectedSubCategorySlug == nextSlug;
    if (isSameSelection) return;

    setState(() {
      _selectedSubCategoryIndex = index;
      _selectedSubCategorySlug = nextSlug;
      _selectedSubCategoryName = isAllSelection ? null : subCategory.name;
      _selectedFilterValuesByKey.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _requestProducts();
  }

  void _retryInitialLoad() {
    setState(() {
      _selectedFilterValuesByKey.clear();
    });
    _requestProducts();
  }

  Future<void> _changeProductQuantity(
    ProductModel product,
    int quantity,
  ) async {
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

  // ── Filter / sort helpers ──────────────────────────────────────────────────

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
      case ProductSortOption.ratings:
        return 'ratings';
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

  void _requestProducts() {
    _productBloc.add(
      ProductListRequested(
        categorySlug: widget.slug,
        subCategory: _selectedSubCategorySlug,
        sortBy: _hasExplicitSortSelection
            ? _sortByQueryValue(_selectedSortOption)
            : null,
        queryParameters: _activeBrowseQueryParameters(),
      ),
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

  List<String> _filterOptionLabelsForKeys(List<String> keys) {
    final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();
    final labels = <String>[];

    for (final section in _filterSections) {
      final sectionKey = section.key.toLowerCase();
      final sectionLabel = section.label.toLowerCase();
      final matchesKnownKey = normalizedKeys.contains(sectionKey);
      final matchesSemanticLabel = normalizedKeys.contains('brand_segment') &&
          (sectionLabel == 'product type' ||
              sectionLabel.contains('product type'));

      if (matchesKnownKey || matchesSemanticLabel) {
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

  void _toggleInlineFilterValue({
    required String label,
    required List<String> candidateKeys,
  }) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) return;

    final targetSection = _filterSections.firstWhere(
      (section) {
        final key = section.key.toLowerCase();
        final title = section.label.toLowerCase();
        final matchesKey =
            candidateKeys.any((candidate) => key == candidate.toLowerCase());
        final matchesTypeLabel = candidateKeys.contains('brand_segment') &&
            (title == 'product type' || title.contains('product type'));
        final matchesSubTypeLabel =
            candidateKeys.contains('brand_sub_segment') &&
                (title == 'product sub type' ||
                    title.contains('product sub type') ||
                    title.contains('sub type'));
        return matchesKey || matchesTypeLabel || matchesSubTypeLabel;
      },
      orElse: () => const BrowseFilterSection(
        key: '',
        label: '',
        searchable: false,
        options: <BrowseFilterOption>[],
        meta: <String, dynamic>{},
      ),
    );

    if (targetSection.key.isEmpty) {
      return;
    }

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
        _selectedFilterValuesByKey[targetSection.key] ?? <String>{});
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

  void _toggleInlineProductType(String label) {
    _toggleInlineFilterValue(
      label: label,
      candidateKeys: const ['brand_segment'],
    );
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
              if (current.subCategories.length !=
                  previous.subCategories.length) {
                return true;
              }
              return false;
            },
            listener: (context, state) {
              if (state is! ProductListLoaded) return;
              setState(() {
                if (state.subCategories.isNotEmpty) {
                  _subCategories = state.subCategories;
                  _syncSelectedSubCategoryIndex();
                }
                if (state.filters.isNotEmpty) {
                  _filterSections = state.filters;
                }
              });
              if (state.filters.isEmpty && _filterSections.isEmpty) {
                _productBloc.add(ProductFiltersRequested(
                  category: widget.slug,
                ));
              }
            },
            builder: (context, productState) {
              if (productState is ProductLoading) {
                return _ProductListingPageSkeleton(
                  showFloatingCart: cartQtyByProductId.isNotEmpty,
                );
              }

              final rawProducts = productState is ProductListLoaded
                  ? productState.products
                  : <ProductModel>[];
              final visibleProducts = rawProducts;
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
                      Expanded(
                        child: _buildBody(
                          visibleProducts: visibleProducts,
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
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: BackToTopButton(
                        visible: _showBackToTop,
                        onTap: _scrollToTop,
                      ),
                    ),
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

  Widget _buildBody({
    required List<ProductModel> visibleProducts,
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
          child: Column(
            children: [
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
                child: _buildProductPane(
                  visibleProducts: visibleProducts,
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
        ),
      ],
    );
  }

  void _syncSelectedSubCategoryIndex() {
    final selectedSlug = _selectedSubCategorySlug?.trim();
    if (selectedSlug == null || selectedSlug.isEmpty) {
      _selectedSubCategoryIndex = 0;
      return;
    }

    final matchedIndex = _subCategories.indexWhere(
      (item) => item.browseSlug == selectedSlug || item.slug == selectedSlug,
    );
    _selectedSubCategoryIndex = matchedIndex < 0 ? 0 : matchedIndex + 1;
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

    return PullToRefresh(
      onRefresh: () async {
        _productBloc.add(ProductListRefreshRequested());
        await _productBloc.stream.firstWhere(
          (s) => s is ProductListLoaded || s is ProductError,
        );
      },
      child: BrowseProductFeed(
        scrollController: _scrollController,
        products: visibleProducts,
        subCategories: _subCategories,
        brandOptions: _filterOptionLabels('brand'),
        productTypeOptions: _filterOptionLabelsForKeys(const ['brand_segment']),
        selectedProductTypeOptions: _selectedValuesForKeys(
          const ['brand_segment'],
        ),
        category: _selectedSubCategoryName ?? widget.category,
        categorySlug: widget.slug,
        hasMore: hasMore,
        isLoading: isLoadingMore,
        loadMoreFailed: false,
        cartQtyByProductId: cartQtyByProductId,
        cartUpdatingProductId: cartUpdatingKey,
        onRetryLoadMore: () => _productBloc.add(ProductListNextPageRequested()),
        onProductTap: (product) {
          context.push('${ProductDetailPage.routePath}/${product.slug}');
        },
        onCartQuantityChanged: _changeProductQuantity,
        onNotifyTap: _handleNotifyTap,
        onProductTypeTap: _toggleInlineProductType,
        onRequestTap: () => context.push(MagicAiQuotePage.routePath),
      ),
    );
  }
}

class _ProductListingPageSkeleton extends StatelessWidget {
  const _ProductListingPageSkeleton({required this.showFloatingCart});

  final bool showFloatingCart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Column(
          children: [
            _ProductListingHeaderSkeleton(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductListingSideRailSkeleton(),
                  Expanded(child: _ProductListingRightPaneSkeleton()),
                ],
              ),
            ),
          ],
        ),
        if (showFloatingCart)
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Center(
              child: Container(
                width: 240,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SkeletonBox(height: 56, borderRadius: 16),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductListingHeaderSkeleton extends StatelessWidget {
  const _ProductListingHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: const Row(
        children: [
          SkeletonBox(width: 24, height: 24, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(child: SkeletonBox(height: 18, borderRadius: 8)),
          SizedBox(width: 12),
          SkeletonBox(width: 20, height: 20, borderRadius: 10),
        ],
      ),
    );
  }
}

class _ProductListingSideRailSkeleton extends StatelessWidget {
  const _ProductListingSideRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
      child: Column(
        children: List<Widget>.generate(
          4,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 28),
            child: Column(
              children: [
                SkeletonBox(width: 64, height: 64, borderRadius: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 56, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductListingRightPaneSkeleton extends StatelessWidget {
  const _ProductListingRightPaneSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProductListingFilterRowSkeleton(),
        Expanded(child: _ProductListingFeedSkeleton()),
      ],
    );
  }
}

class _ProductListingFilterRowSkeleton extends StatelessWidget {
  const _ProductListingFilterRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      child: const Row(
        children: [
          SkeletonBox(width: 86, height: 36, borderRadius: 8),
          SizedBox(width: 8),
          SkeletonBox(width: 92, height: 36, borderRadius: 8),
          SizedBox(width: 8),
          SkeletonBox(width: 78, height: 36, borderRadius: 8),
          SizedBox(width: 8),
          Expanded(child: SkeletonBox(height: 36, borderRadius: 8)),
        ],
      ),
    );
  }
}

class _ProductListingFeedSkeleton extends StatelessWidget {
  const _ProductListingFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 96),
      children: const [
        _ProductListingGridSkeletonRow(),
        SizedBox(height: 24),
        _ProductListingGridSkeletonRow(),
        SizedBox(height: 24),
        _ProductListingInlineRailSkeleton(),
        SizedBox(height: 24),
        _ProductListingGridSkeletonRow(),
      ],
    );
  }
}

class _ProductListingGridSkeletonRow extends StatelessWidget {
  const _ProductListingGridSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ProductListingCardSkeleton()),
        SizedBox(width: 10),
        Expanded(child: _ProductListingCardSkeleton()),
      ],
    );
  }
}

class _ProductListingCardSkeleton extends StatelessWidget {
  const _ProductListingCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 132, borderRadius: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 12, borderRadius: 6),
        SizedBox(height: 8),
        SkeletonBox(width: 120, height: 12, borderRadius: 6),
        SizedBox(height: 12),
        SkeletonBox(width: 62, height: 18, borderRadius: 9),
        SizedBox(height: 10),
        SkeletonBox(width: 82, height: 16, borderRadius: 8),
      ],
    );
  }
}

class _ProductListingInlineRailSkeleton extends StatelessWidget {
  const _ProductListingInlineRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 18),
      color: const Color(0xFFE8F2EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 110, height: 16, borderRadius: 8),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) =>
                  const SkeletonBox(width: 88, height: 40, borderRadius: 12),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemCount: 4,
            ),
          ),
        ],
      ),
    );
  }
}
