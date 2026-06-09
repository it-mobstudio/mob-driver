import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/components/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';

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
  static const ProductsRepository _productsRepository = ProductsRepository();

  final Map<String, int> _localQuantities = <String, int>{};
  List<_VariantRowData> _variantRows = <_VariantRowData>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVariants();
    });
  }

  Future<void> _loadVariants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      ProductModel sourceProduct = widget.product;
      if (sourceProduct.childProducts.isEmpty && sourceProduct.variants.isEmpty) {
        final result = await _productsRepository.getProductDetails(
          slug: widget.product.slug,
          mobSku: widget.product.mobSku.isNotEmpty ? widget.product.mobSku : null,
        );
        sourceProduct = result.product;
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
            try {
              final result = await _productsRepository.getProductDetails(
                slug: widget.product.slug,
                mobSku: entry.key,
              );
              rows.add(
                _VariantRowData(
                  label: entry.value.value,
                  product: result.product,
                ),
              );
            } catch (_) {
              // Skip failed variant details and continue.
            }
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
      }
    }
  }

  int _quantityFor(ProductModel product) {
    final resolver = widget.quantityResolver;
    if (resolver != null) {
      return resolver(product.addToCartProductId);
    }
    return _localQuantities[product.addToCartProductId] ?? 0;
  }

  bool _isUpdating(ProductModel product) {
    final resolver = widget.isUpdatingResolver;
    return resolver?.call(product.addToCartProductId) ?? false;
  }

  Future<void> _changeQuantity(ProductModel product, int quantity) async {
    final callback = widget.onCartQuantityChanged;
    if (callback != null) {
      await callback(product, quantity);
      return;
    }
    if (!mounted) return;
    setState(() {
      if (quantity > 0) {
        _localQuantities[product.addToCartProductId] = quantity;
      } else {
        _localQuantities.remove(product.addToCartProductId);
      }
    });
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
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      itemCount: _variantRows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
