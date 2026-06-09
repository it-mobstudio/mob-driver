import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/components/item_card.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';

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
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF0A243F),
              ),
            ),
          ),
          const SizedBox(width: 2),
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
            icon: const Icon(
              Icons.search,
              size: 20,
              color: Color(0xFF0A243F),
            ),
          ),
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
    required this.onBrandTap,
    required this.onPriceTap,
    required this.selectedFilterCount,
    required this.onClearFilters,
  });

  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final VoidCallback onBrandTap;
  final VoidCallback onPriceTap;
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
        padding: const EdgeInsets.fromLTRB(83, 10, 16, 10),
        children: [
          _FilterChip(
            label: 'Filters',
            leadingIcon: Icons.tune_rounded,
            onTap: onFilterTap,
            selectedCount: selectedFilterCount,
            onClear: onClearFilters,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Sort by',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onTap: onSortTap,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Brands',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onTap: onBrandTap,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Price',
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            onTap: onPriceTap,
          ),
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
    final visibleSubs = subCategories.isEmpty
        ? <SubCategoryModel>[
            SubCategoryModel(
              name: category,
              image: '',
              slug: categorySlug,
            ),
          ]
        : subCategories;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 24),
        itemCount: visibleSubs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 34),
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
    required this.onRequestTap,
  });

  final ScrollController scrollController;
  final List<ProductModel> products;
  final List<SubCategoryModel> subCategories;
  final List<String> brandOptions;
  final List<String> productTypeOptions;
  final String category;
  final String categorySlug;
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
  final VoidCallback onRequestTap;

  @override
  Widget build(BuildContext context) {
    final rowCount = (products.length / 2).ceil();
    final brands = brandOptions
        .where((option) => option.trim().isNotEmpty)
        .map((option) => _BrowseBrandItem(name: option.trim()))
        .toList();
    final showProductType = products.length >= 4;
    final showBrands = products.length >= 8 && brands.isNotEmpty;
    final extraSections = (showProductType ? 1 : 0) + (showBrands ? 1 : 0);
    final itemCount = rowCount + extraSections + (hasMore ? 1 : 0) + 1;

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 96),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        var productRowIndex = index;

        if (showProductType) {
          if (index == 2) {
            return _ProductTypeRail(filters: _productTypeLabels());
          }
          if (index > 2) productRowIndex -= 1;
        }

        if (showBrands) {
          final brandSectionIndex = showProductType ? 5 : 4;
          if (index == brandSectionIndex) {
            return _BrandRail(brands: brands);
          }
          if (index > brandSectionIndex) productRowIndex -= 1;
        }

        if (productRowIndex < rowCount) {
          return _ProductGridRow(
            products: products,
            startIndex: productRowIndex * 2,
            cartQtyByProductId: cartQtyByProductId,
            cartUpdatingProductId: cartUpdatingProductId,
            onProductTap: onProductTap,
            onCartQuantityChanged: onCartQuantityChanged,
            onNotifyTap: onNotifyTap,
          );
        }

        if (hasMore && productRowIndex == rowCount) {
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

        return BrowseRequestCard(onTap: onRequestTap);
      },
    );
  }

  List<String> _productTypeLabels() {
    if (productTypeOptions.isNotEmpty) {
      return productTypeOptions.take(8).toList();
    }
    return subCategories
        .map((sub) => sub.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .take(8)
        .toList();
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
                  color: Colors.black.withOpacity(0.18),
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
                          color: Colors.white.withOpacity(0.8),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      height: 138,
      decoration: BoxDecoration(
        color: const Color(0xFFF8E6B6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Can't find what you're looking for?",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suggest the item you want and we will try to add it.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A243F).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF0A243F)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Send a request',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridRow extends StatelessWidget {
  const _ProductGridRow({
    required this.products,
    required this.startIndex,
    required this.cartQtyByProductId,
    required this.cartUpdatingProductId,
    required this.onProductTap,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
  });

  final List<ProductModel> products;
  final int startIndex;
  final Map<String, int> cartQtyByProductId;
  final String? cartUpdatingProductId;
  final void Function(ProductModel product) onProductTap;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _cardForProduct(products[startIndex])),
          const SizedBox(width: 10),
          Expanded(
            child: startIndex + 1 < products.length
                ? _cardForProduct(products[startIndex + 1])
                : const SizedBox(height: 276),
          ),
        ],
      ),
    );
  }

  Widget _cardForProduct(ProductModel product) {
    return Center(
      child: ItemCard(
        product: product,
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
  const _ProductTypeRail({required this.filters});

  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return _BrowseRailSection(
      title: 'Product type',
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDFE4EC)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              filters[index],
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 18 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
        width: 65,
        height: 83,
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
                              const Icon(Icons.category_outlined, size: 24),
                        )
                      : const Icon(Icons.category_outlined, size: 24),
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
                    fontWeight: FontWeight.w400,
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
              errorWidget: (_, __, ___) => Image.asset(
                'assets/images/Image-coming-soon.png',
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              'assets/images/Image-coming-soon.png',
              fit: BoxFit.cover,
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
    this.selectedCount = 0,
    this.onClear,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
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
            color: isSelected ? const Color(0xFF0360E5) : const Color(0xFFDEDEDE),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 12, color: const Color(0xFF0A243F)),
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
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 14, color: const Color(0xFF0A243F)),
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
