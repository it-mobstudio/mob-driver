import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/shared/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';

class VariantSelectionSheet extends StatefulWidget {
  const VariantSelectionSheet({
    super.key,
    required this.product,
    this.quantityResolver,
    this.isUpdatingResolver,
    this.onCartQuantityChanged,
    this.onNotifyTap,
  });

  final ProductModel product;
  final int Function(String productId)? quantityResolver;
  final bool Function(String productId)? isUpdatingResolver;
  final Future<void> Function(ProductModel product, int quantity)?
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product)? onNotifyTap;

  @override
  State<VariantSelectionSheet> createState() => _VariantSelectionSheetState();
}

class _VariantSelectionSheetState extends State<VariantSelectionSheet> {

  final Map<String, int> _localQuantities = <String, int>{};
  List<_VariantRowData> _variantRows = <_VariantRowData>[];
  bool _isLoading = true;

  final _sheetController = DraggableScrollableController();
  static const double _minFraction = 0.28;
  static const double _maxFraction = 0.92;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVariants();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  // Rough content-height estimate so the sheet opens at roughly the right
  // size for 2-3 variants vs. 40-50 of them, instead of either wasting empty
  // space or always defaulting to a fixed fraction of the screen. Anything
  // taller than ~5 rows worth is left to maxChildSize + the internal
  // scrollable rather than growing the initial size further.
  double _fractionForRowCount(int rowCount) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0) return 0.4;
    const chromeHeight = 96.0; // drag handle + title row + divider
    const listPadding = 36.0; // ListView top/bottom padding
    const rowHeight = 88.0; // row content (76) + separator (12)
    final visibleRows = rowCount.clamp(1, 5);
    final contentHeight =
        chromeHeight + listPadding + (visibleRows * rowHeight);
    return (contentHeight / screenHeight).clamp(_minFraction, _maxFraction);
  }

  Future<void> _loadVariants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      ProductModel sourceProduct = widget.product;
      if (sourceProduct.childProducts.isEmpty && sourceProduct.variants.isEmpty) {
        final (detail, _) = await sl<ProductRepository>().getProductDetail(
          slug: widget.product.slug,
          mobSku: widget.product.mobSku.isNotEmpty ? widget.product.mobSku : null,
        );
        if (detail != null) sourceProduct = detail.product;
      }

      if (sourceProduct.childProducts.isNotEmpty) {
        _variantRows = sourceProduct.childProducts
            .map(
              (child) => _VariantRowData(
                label: child.label,
                product: child.toProductModel(sourceProduct),
              ),
            )
            .toList();
      } else {
        final optionsBySku = <String, ProductVariantOption>{};
        for (final options in sourceProduct.variants.values) {
          for (final option in options) {
            if (option.mobSku.isNotEmpty) {
              optionsBySku.putIfAbsent(option.mobSku, () => option);
            }
          }
        }

        if (optionsBySku.isEmpty) {
          _variantRows = <_VariantRowData>[
            _VariantRowData(label: sourceProduct.title, product: sourceProduct),
          ];
        } else {
          final rows = <_VariantRowData>[];
          for (final entry in optionsBySku.entries) {
            final (detail, failure) = await sl<ProductRepository>().getProductDetail(
              slug: widget.product.slug,
              mobSku: entry.key,
            );
            if (failure != null || detail == null) continue;
            rows.add(
              _VariantRowData(
                label: entry.value.value,
                product: detail.product,
              ),
            );
          }
          _variantRows = rows;
        }
      }
    } catch (_) {
      _variantRows = <_VariantRowData>[
        _VariantRowData(label: widget.product.title, product: widget.product),
      ];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final target = _fractionForRowCount(_variantRows.length);
        if (_sheetController.isAttached) {
          _sheetController.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  int _quantityFor(ProductModel product) {
    final id = product.addToCartProductId;
    // A local edit always wins: quantityResolver closes over a snapshot of
    // the cart taken when this sheet was opened (it's a modal route, not a
    // descendant of whatever BlocBuilder keeps the grid's resolver fresh),
    // so it never updates again for the lifetime of this sheet.
    if (_localQuantities.containsKey(id)) {
      return _localQuantities[id]!;
    }
    final resolver = widget.quantityResolver;
    if (resolver != null) {
      return resolver(id);
    }
    return 0;
  }

  bool _isUpdating(ProductModel product) {
    final resolver = widget.isUpdatingResolver;
    return resolver?.call(product.addToCartProductId) ?? false;
  }

  Future<void> _changeQuantity(ProductModel product, int quantity) async {
    if (!mounted) return;
    setState(() {
      if (quantity > 0) {
        _localQuantities[product.addToCartProductId] = quantity;
      } else {
        _localQuantities.remove(product.addToCartProductId);
      }
    });
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      await callback(product, quantity);
    }
  }

  Future<void> _notify(ProductModel product) async {
    final callback = widget.onNotifyTap;
    if (callback != null) {
      await callback(product);
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

  @override
  Widget build(BuildContext context) {
    final initialFraction =
        _isLoading ? 0.4 : _fractionForRowCount(_variantRows.length);
    final minFraction =
        (initialFraction - 0.12).clamp(_minFraction, initialFraction);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: initialFraction,
      minChildSize: minFraction,
      maxChildSize: _maxFraction,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1E6ED),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                            itemCount: _variantRows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final row = _variantRows[index];
                              return _VariantListRow(
                                product: row.product,
                                label: row.label,
                                quantity: _quantityFor(row.product),
                                isUpdating: _isUpdating(row.product),
                                onChanged: (quantity) =>
                                    _changeQuantity(row.product, quantity),
                                onNotify: () => _notify(row.product),
                              );
                            },
                          ),
                  ),
                ],
                ),
              ),
            ),
            Positioned(
              top: -48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF0A243F),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VariantRowData {
  const _VariantRowData({
    required this.label,
    required this.product,
  });

  final String label;
  final ProductModel product;
}

class _VariantListRow extends StatelessWidget {
  const _VariantListRow({
    required this.product,
    required this.label,
    required this.quantity,
    required this.isUpdating,
    required this.onChanged,
    required this.onNotify,
  });

  final ProductModel product;
  final String label;
  final int quantity;
  final bool isUpdating;
  final Future<void> Function(int quantity) onChanged;
  final Future<void> Function() onNotify;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final mrp = product.maximumRetailPrice;
    final rowLabel = label.isNotEmpty ? label : product.title;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.primaryImageUrl.isEmpty
                  ? Image.asset(
                      'assets/images/Image-coming-soon.png',
                      fit: BoxFit.contain,
                    )
                  : CachedNetworkImage(
                      imageUrl: product.primaryImageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 120,
                      errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/Image-coming-soon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rowLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 18 / 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹ ${price.round()}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (mrp > 0) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '₹ ${mrp.round()}',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB5B5B5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: ProductCartActionButton(
              product: product,
              style: ProductCartActionButtonStyle.rail,
              showCounter: !product.shouldShowNotify && quantity > 0,
              quantity: quantity > 0 ? quantity : 1,
              isFetchingCart: isUpdating,
              onAdd: (quantity) => onChanged(quantity),
              onAddForQuote: (quantity) => onChanged(quantity),
              onQuantityChanged: onChanged,
              onNotify: onNotify,
            ),
          ),
        ],
      ),
    );
  }
}
