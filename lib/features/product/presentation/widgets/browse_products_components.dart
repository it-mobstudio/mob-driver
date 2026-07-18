import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/item_card.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class BrowseProductsHeader extends StatelessWidget {
  const BrowseProductsHeader({
    super.key,
    required this.category,
    required this.onBack,
    required this.onSearch,
  });

  final String category;
  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const SizedBox(
              width: 28,
              height: 44,
              child: Center(child: AppBackIcon()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 22 / 15,
              ),
            ),
          ),
          IconButton(
              onPressed: onSearch,
              icon: SvgPicture.asset(
                'assets/images/Searchicon.svg',
                width: 16,
                height: 16,
              )),
        ],
      ),
    );
  }
}

class BrowseFilterRow extends StatelessWidget {
  const BrowseFilterRow({
    super.key,
    required this.onFilterTap,
    required this.onSortTap,
    required this.filterSections,
    required this.selectedValuesByKey,
    required this.onSectionTap,
    required this.selectedFilterCount,
    required this.onClearFilters,
  });

  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final List<BrowseFilterSection> filterSections;
  final Map<String, Set<String>> selectedValuesByKey;
  final void Function(BrowseFilterSection section) onSectionTap;
  final int selectedFilterCount;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        children: [
          _FilterChip(
            label: 'Filters',
            leadingAsset: 'assets/images/filter.svg',
            onTap: onFilterTap,
            selectedCount: selectedFilterCount,
            onClear: onClearFilters,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sort by',
            trailingAsset: 'assets/images/downicon.svg',
            onTap: onSortTap,
          ),
          ...filterSections.expand((section) {
            final selectedCount = selectedValuesByKey[section.key]?.length ?? 0;
            return <Widget>[
              const SizedBox(width: 8),
              _FilterChip(
                label: section.label.isNotEmpty ? section.label : section.key,
                trailingAsset: 'assets/images/downicon.svg',
                onTap: () => onSectionTap(section),
                selectedCount: selectedCount,
              ),
            ];
          }),
        ],
      ),
    );
  }
}

class SideSubCategoryRail extends StatelessWidget {
  const SideSubCategoryRail({
    super.key,
    required this.category,
    required this.categorySlug,
    required this.subCategories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String category;
  final String categorySlug;
  final List<SubCategoryModel> subCategories;
  final int selectedIndex;
  final void Function(int index, SubCategoryModel subCategory) onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleSubs = <SubCategoryModel>[
      SubCategoryModel(
        name: 'All $category',
        image: '',
        slug: '',
      ),
      ...subCategories,
    ];

    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Color(0xFFE7EAF0),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        itemCount: visibleSubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _SubCategoryTile(
            sub: visibleSubs[index],
            isSelected: index == selectedIndex,
            onTap: () => onSelected(index, visibleSubs[index]),
          );
        },
      ),
    );
  }
}

class BrowseProductFeed extends StatelessWidget {
  const BrowseProductFeed({
    super.key,
    required this.scrollController,
    required this.products,
    required this.subCategories,
    required this.brandOptions,
    required this.productTypeOptions,
    required this.selectedProductTypeOptions,
    required this.category,
    required this.categorySlug,
    required this.hasMore,
    required this.isLoading,
    required this.loadMoreFailed,
    required this.cartQtyByProductId,
    required this.cartUpdatingProductId,
    required this.onRetryLoadMore,
    required this.onProductTap,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
    required this.onProductTypeTap,
    required this.onRequestTap,
    this.crossAxisCount = 2,
    this.requestCardIndex,
    this.requestCardFullWidth = false,
  });

  final ScrollController scrollController;
  final List<ProductModel> products;
  final List<SubCategoryModel> subCategories;
  final List<String> brandOptions;
  final List<String> productTypeOptions;
  final Set<String> selectedProductTypeOptions;
  final String category;
  final String categorySlug;
  final int crossAxisCount;
  // Flat grid-cell position for the "Can't find the brand/product?" quote
  // card. Defaults to right after the last real result (see below); pass a
  // fixed value to pin it at a specific cell instead (e.g. brand search
  // results pin it at row 2 regardless of how many products load).
  final int? requestCardIndex;
  final bool requestCardFullWidth;
  final bool hasMore;
  final bool isLoading;
  final bool loadMoreFailed;
  final Map<String, int> cartQtyByProductId;
  final String? cartUpdatingProductId;
  final VoidCallback onRetryLoadMore;
  final void Function(ProductModel product) onProductTap;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;
  final ValueChanged<String> onProductTypeTap;
  final VoidCallback onRequestTap;

  @override
  Widget build(BuildContext context) {
    final tileCount = products.length + (requestCardFullWidth ? 0 : 1);
    final rowCount = (tileCount / crossAxisCount).ceil();
    // Defaults to the last slot in the grid — after every real result, not
    // interrupting them. A fixed index is clamped so it never sits past the
    // last loaded product (which would otherwise leave a gap once more
    // results actually load).
    final requestCardIndex =
        (this.requestCardIndex ?? products.length).clamp(0, products.length);
    final productTypeLabels = _productTypeLabels();
    final brands = brandOptions
        .where((option) => option.trim().isNotEmpty)
        .map((option) => _BrowseBrandItem(name: option.trim()))
        .toList();
    final showProductType = productTypeLabels.isNotEmpty;
    final showBrands = brands.isNotEmpty;
    final extraSections = (showProductType ? 1 : 0) + (showBrands ? 1 : 0);
    final requestBannerSectionIndex =
        requestCardFullWidth ? (rowCount >= 2 ? 2 : rowCount) : -1;
    final itemCount = rowCount +
        extraSections +
        (requestCardFullWidth ? 1 : 0) +
        (hasMore ? 1 : 0);
    final productTypeSectionIndex = showProductType
        ? (rowCount >= 2 ? 2 : rowCount) + (requestCardFullWidth ? 1 : 0)
        : -1;
    final brandSectionIndex = showBrands
        ? rowCount + extraSections + (requestCardFullWidth ? 1 : 0)
        : -1;
    final loadMoreIndex =
        rowCount + extraSections + (requestCardFullWidth ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      // Lets pull-to-refresh arm even when there aren't enough products to
      // fill the viewport (otherwise a short/filtered result list can't be
      // overscrolled at all, so the gesture never triggers).
      physics: const AlwaysScrollableScrollPhysics(),
      // Horizontal padding lives on each row individually now (see below)
      // rather than here, so the product-type rail can bleed to the true
      // screen edges while everything else keeps a 10px inset. A shared
      // negative Padding on that one row used to fake the same effect, but
      // negative padding inside a sliver's tight cross-axis constraints is
      // invalid and threw a RenderSliverMultiBoxAdaptor assertion.
      //
      // Worst case: ViewCartBar pill AND the bottom nav bar both visible
      // at once — anything less and the last row's text ends up hidden
      // behind them. Was a static 96 with no safe-area awareness at all.
      padding: EdgeInsets.fromLTRB(
        0,
        14,
        0,
        kScrollBottomClearance + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showProductType && index == productTypeSectionIndex) {
          return _ProductTypeRail(
            title: 'Product type',
            filters: productTypeLabels,
            selectedValues: selectedProductTypeOptions,
            onTap: onProductTypeTap,
          );
        }

        // if (showBrands && index == brandSectionIndex) {
        //   return _BrandRail(brands: brands);
        // }

        if (requestCardFullWidth && index == requestBannerSectionIndex) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 34),
            child: BrowseRequestBanner(onTap: onRequestTap),
          );
        }

        var productRowIndex = index;
        if (requestCardFullWidth && index > requestBannerSectionIndex) {
          productRowIndex -= 1;
        }
        if (showProductType && index > productTypeSectionIndex) {
          productRowIndex -= 1;
        }
        if (showBrands && index > brandSectionIndex) {
          productRowIndex -= 1;
        }

        if (productRowIndex < rowCount) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _ProductGridRow(
              products: products,
              startIndex: productRowIndex * crossAxisCount,
              requestCardIndex: requestCardIndex,
              showRequestCard: !requestCardFullWidth,
              crossAxisCount: crossAxisCount,
              cartQtyByProductId: cartQtyByProductId,
              cartUpdatingProductId: cartUpdatingProductId,
              onProductTap: onProductTap,
              onCartQuantityChanged: onCartQuantityChanged,
              onNotifyTap: onNotifyTap,
              onRequestTap: onRequestTap,
            ),
          );
        }

        if (hasMore && index == loadMoreIndex) {
          if (isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (loadMoreFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: onRetryLoadMore,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry loading more'),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return const SizedBox.shrink();
      },
    );
  }

  List<String> _productTypeLabels() {
    return productTypeOptions.take(8).toList();
  }
}

class FloatingCartSummary extends StatelessWidget {
  const FloatingCartSummary({
    super.key,
    required this.products,
    required this.cartQtyByProductId,
    required this.onTap,
  });

  final List<ProductModel> products;
  final Map<String, int> cartQtyByProductId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalItems = cartQtyByProductId.values.fold<int>(
      0,
      (sum, quantity) => sum + quantity,
    );
    final cartImages = products
        .where((product) =>
            (cartQtyByProductId[product.addToCartProductId] ?? 0) > 0)
        .take(3)
        .toList();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 240,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0360E5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 32,
                  child: Stack(
                    children: List.generate(3, (index) {
                      final imageUrl = index < cartImages.length
                          ? cartImages[index].primaryImageUrl
                          : '';
                      return Positioned(
                        left: index * 20,
                        child: _MiniCartImage(imageUrl: imageUrl),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View cart',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 20 / 14,
                        ),
                      ),
                      Text(
                        '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrowseRequestCard extends StatelessWidget {
  const BrowseRequestCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF022E0F), Color(0xFF007736)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                Text(
                  "Can't find the\nBrand/ Product?",
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 20 / 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Don't worry! Tell us\nwhat you need, and\nwe'll be in touch!",
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Expanded(
                  child: Image.asset(
                    'assets/images/Handwithphn.webp',
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Container(
                  height: 32,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Quote request',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 16 / 11,
                      color: const Color(0xFF053961),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BrowseRequestBanner extends StatelessWidget {
  const BrowseRequestBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 136,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF022E0F),
              Color(0xFF007736),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Can't find the Brand/ Product?",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 22 / 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Don't worry! Tell us what you need, and\nwe'll be in touch!",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 18 / 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE600),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'Quote request',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF053961),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 16 / 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/Handwithphn.webp',
                  width: 117,
                  height: 117,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(width: 86, height: 108);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridRow extends StatelessWidget {
  const _ProductGridRow({
    required this.products,
    required this.startIndex,
    required this.requestCardIndex,
    required this.showRequestCard,
    required this.cartQtyByProductId,
    required this.cartUpdatingProductId,
    required this.onProductTap,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
    required this.onRequestTap,
    this.crossAxisCount = 2,
  });

  static const double _columnGap = 10;

  final List<ProductModel> products;
  final int startIndex;
  // Absolute grid slot the "can't find it?" card is inserted at; every
  // product from here on shifts one slot later to make room for it.
  final int requestCardIndex;
  final bool showRequestCard;
  final int crossAxisCount;
  final Map<String, int> cartQtyByProductId;
  final String? cartUpdatingProductId;
  final void Function(ProductModel product) onProductTap;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;
  final VoidCallback onRequestTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalGap = _columnGap * (crossAxisCount - 1);
          final cardWidth = (constraints.maxWidth - totalGap) / crossAxisCount;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < crossAxisCount; column++) ...[
                if (column > 0) const SizedBox(width: _columnGap),
                SizedBox(
                  width: cardWidth,
                  child: _tileForIndex(startIndex + column, cardWidth),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tileForIndex(int index, double width) {
    if (showRequestCard && index == requestCardIndex) {
      return SizedBox(
        height: width + 140,
        child: BrowseRequestCard(onTap: onRequestTap),
      );
    }
    // Slots before the request card map straight to the product list;
    // slots after it shift back by one, since the card took up a slot
    // that would otherwise have held a product.
    final productIndex =
        showRequestCard && index > requestCardIndex ? index - 1 : index;
    if (productIndex < products.length) {
      return _cardForProduct(products[productIndex], width);
    }
    return SizedBox(height: width + 140);
  }

  Widget _cardForProduct(ProductModel product, double width) {
    return Center(
      child: ItemCard(
        product: product,
        width: width,
        onTap: () => onProductTap(product),
        quantityResolver: (productId) => cartQtyByProductId[productId] ?? 0,
        isUpdatingResolver: (productId) => cartUpdatingProductId == productId,
        onCartQuantityChanged: onCartQuantityChanged,
        onNotifyTap: onNotifyTap,
      ),
    );
  }
}

class _ProductTypeRail extends StatelessWidget {
  const _ProductTypeRail({
    required this.title,
    required this.filters,
    required this.selectedValues,
    required this.onTap,
  });

  final String title;
  final List<String> filters;
  final Set<String> selectedValues;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return _BrowseRailSection(
      title: title,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final label = filters[index];
            final isSelected = selectedValues.contains(label);
            return GestureDetector(
              onTap: () => onTap(label),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0A243F).withValues(alpha: 0.08)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0A243F)
                        : const Color(0xFFDFE4EC),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Hidden for now (see the commented-out call site above) — kept ready for a
// one-line uncomment rather than a rebuild.
// ignore: unused_element
class _BrandRail extends StatelessWidget {
  const _BrandRail({required this.brands});

  final List<_BrowseBrandItem> brands;

  @override
  Widget build(BuildContext context) {
    return _BrowseRailSection(
      title: 'Shop by brands',
      child: SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: brands.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            return _BrandTile(brand: brands[index]);
          },
        ),
      ),
    );
  }
}

class _BrowseRailSection extends StatelessWidget {
  const _BrowseRailSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 34),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
      color: const Color(0xFFE8F2EF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand});

  final _BrowseBrandItem brand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDFE4EC)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _BrandLogo(brandName: brand.name),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            brand.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 14 / 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  const _SubCategoryTile({
    required this.sub,
    required this.isSelected,
    required this.onTap,
  });

  final SubCategoryModel sub;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        // Label sits at top:69 with height:28 (bottom edge at 97) — Stack
        // clips by default, so a shorter box here was silently cutting off
        // the second line of longer names instead of wrapping to it.
        width: 65,
        height: 98,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE8F2EF), Color(0xFFBFE3ED)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: SizedBox(
                width: 53,
                height: 53,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: sub.image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sub.image,
                          fit: BoxFit.cover,
                          memCacheWidth: 106,
                          errorWidget: (_, __, ___) =>
                              _SubCategoryPlaceholder(isSelected: isSelected),
                        )
                      : _SubCategoryPlaceholder(isSelected: isSelected),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 69,
              child: SizedBox(
                width: 65,
                height: 28,
                child: Text(
                  sub.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? const Color(0xFF0A243F)
                        : const Color(0xFF57627A),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.27,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubCategoryPlaceholder extends StatelessWidget {
  const _SubCategoryPlaceholder({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isSelected ? const Color(0xFF0360E5) : const Color(0xFFB8C2D1);

    return Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List<Widget>.generate(
            4,
            (_) => Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCartImage extends StatelessWidget {
  const _MiniCartImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0360E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 64,
              errorWidget: (_, __, ___) => const ProductImagePlaceholder(),
            )
          : const ProductImagePlaceholder(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.leadingAsset,
    this.trailingAsset,
    this.onTap,
    this.selectedCount = 0,
    this.onClear,
  });

  final String label;
  final String? leadingAsset;
  final String? trailingAsset;
  final VoidCallback? onTap;
  final int selectedCount;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F8FF) : Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0360E5) : const Color(0xFFDEDEDE),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingAsset != null) ...[
              SvgPicture.asset(
                leadingAsset!,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0A243F),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isSelected ? '$label ($selectedCount)' : label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
              ),
            ),
            if (isSelected && onClear != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEDEDE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 14 / 10,
                      color: const Color(0xFF0360E5),
                    ),
                  ),
                ),
              ),
            ],
            if (trailingAsset != null) ...[
              const SizedBox(width: 8),
              SvgPicture.asset(
                trailingAsset!,
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0A243F),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brandName});

  final String brandName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(brandName),
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _BrowseBrandItem {
  const _BrowseBrandItem({required this.name});

  final String name;
}
