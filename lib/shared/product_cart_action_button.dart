import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';

enum ProductCartActionButtonStyle {
  defaultStyle,
  compact,
  rail,
}

class ProductCartActionButton extends StatefulWidget {
  const ProductCartActionButton({
    super.key,
    required this.product,
    this.showCounter = false,
    this.quantity = 1,
    this.isFetching = false,
    this.isFetchingCart = false,
    this.isSoldOut = false,
    this.availableStock,
    this.compact = false,
    this.style = ProductCartActionButtonStyle.defaultStyle,
    this.showAddText = false,
    this.onAdd,
    this.onAddForQuote,
    this.onNotify,
    this.onVariantsTap,
    this.onQuantityChanged,
  });

  final ProductModel product;
  final bool showCounter;
  final int quantity;
  final bool isFetching;
  final bool isFetchingCart;
  final bool isSoldOut;
  final int? availableStock;
  final bool compact;
  final ProductCartActionButtonStyle style;
  final bool showAddText;
  final Future<void> Function(int quantity)? onAdd;
  final Future<void> Function(int quantity)? onAddForQuote;
  final Future<void> Function()? onNotify;
  final VoidCallback? onVariantsTap;
  final ValueChanged<int>? onQuantityChanged;

  @override
  State<ProductCartActionButton> createState() =>
      _ProductCartActionButtonState();
}

class _ProductCartActionButtonState extends State<ProductCartActionButton> {
  late int _quantity;
  bool _isSubmitting = false;

  bool get _isCompactStyle =>
      widget.style == ProductCartActionButtonStyle.compact || widget.compact;

  bool get _isRailStyle =>
      widget.style == ProductCartActionButtonStyle.rail;

  bool get _isBusy =>
      widget.isFetching || widget.isFetchingCart || _isSubmitting;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity <= 0 ? 1 : widget.quantity;
  }

  @override
  void didUpdateWidget(ProductCartActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity && widget.quantity > 0) {
      _quantity = widget.quantity;
    }
  }

  Future<void> _runWithBusy(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _defaultAddToCart({required int quantity}) async {
    if (!mounted) return;
    final cartItem = CartItem(
      title: widget.product.title,
      imageAsset: widget.product.primaryImageUrl,
      qty: quantity,
      unitPrice: widget.product.vendorPricing.vendorSellingPrice.toDouble(),
      sellerCode: 'STORE',
      vendorProductId: widget.product.addToCartProductId,
    );
    context.read<CartBloc>().add(
      CartQuantityUpdateRequested(item: cartItem, newQty: quantity),
    );
    AnalyticsService.instance.logAddToCart(
      productId: widget.product.addToCartProductId,
      slug: widget.product.slug,
      price: widget.product.vendorPricing.vendorSellingPrice.toDouble(),
      success: true,
    );
  }

  Future<void> _handleAdd() async {
    final action = widget.onAdd;
    await _runWithBusy(() async {
      if (action != null) {
        await action(_quantity);
      } else {
        await _defaultAddToCart(quantity: _quantity);
      }
    });
  }

  Future<void> _handleQuote() async {
    final action = widget.onAddForQuote;
    await _runWithBusy(() async {
      if (action != null) {
        await action(_quantity);
      } else {
        await _defaultAddToCart(quantity: _quantity);
      }
    });
  }

  Future<void> _handleNotify() async {
    final action = widget.onNotify;
    if (action == null) {
      return;
    }
    await _runWithBusy(action);
  }

  void _updateQuantity(int next) {
    final clamped = next < 0 ? 0 : next;
    if (clamped == 0) {
      setState(() => _quantity = 0);
      widget.onQuantityChanged?.call(0);
      return;
    }
    final stock = _resolvedAvailableStock;
    final capped =
        stock != null && stock > 0 ? clamped.clamp(1, stock) : clamped;
    setState(() => _quantity = capped);
    widget.onQuantityChanged?.call(capped);
  }

  int? get _resolvedAvailableStock {
    if (widget.availableStock != null) {
      return widget.availableStock;
    }
    return widget.product.availableStock > 0
        ? widget.product.availableStock
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final hasVariants = widget.product.hasVariants;
    final variantCount = widget.product.variantOptionCount;
    final hasSellingPrice = widget.product.vendorPricing.vendorSellingPrice > 0;
    final shouldShowNotify =
        widget.isSoldOut || widget.product.shouldShowNotify;
    final shouldShowAdd = hasVariants || hasSellingPrice;

    if (widget.showCounter && !shouldShowNotify) {
      if (_isRailStyle) return _buildRailCounter();
      return _isCompactStyle ? _buildCompactCounter() : _buildCounter();
    }

    if (shouldShowNotify) {
      return _buildNotifyButton();
    }

    if (shouldShowAdd) {
      return _buildAddButton(
          hasVariants: hasVariants, variantCount: variantCount);
    }

    return _buildQuoteButton();
  }

  Widget _buildAddButton({
    required bool hasVariants,
    required int variantCount,
  }) {
    if (_isRailStyle) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isBusy
            ? null
            : () {
                if (hasVariants && widget.onVariantsTap != null) {
                  widget.onVariantsTap!.call();
                  return;
                }
                _handleAdd();
              },
        child: Container(
          width: 68,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0360E5)),
          ),
          child: _isSubmitting
              ? const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Center(
                  child: Text(
                    'ADD',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0360E5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                    ),
                  ),
                ),
        ),
      );
    }

    if (_isCompactStyle) {
      return GestureDetector(
        onTap: _isBusy
            ? null
            : () {
                if (hasVariants && widget.onVariantsTap != null) {
                  widget.onVariantsTap!.call();
                  return;
                }
                _handleAdd();
              },
        child: _compactCircle(
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : hasVariants
                  ? Text(
                      'ADD',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A243F),
                      ),
                    )
                  : const Icon(
                      Icons.add,
                      size: 20,
                      color: Color(0xFF0A243F),
                    ),
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isBusy
            ? null
            : () {
                if (hasVariants && widget.onVariantsTap != null) {
                  widget.onVariantsTap!.call();
                  return;
                }
                _handleAdd();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0360E5),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'ADD',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildQuoteButton() {
    if (_isCompactStyle) {
      return GestureDetector(
        onTap: _isBusy ? null : _handleQuote,
        child: _compactCircle(
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'QUOTE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                  ),
                ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: _isBusy ? null : _handleQuote,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF0360E5)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'ADD FOR QUOTE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: widget.showAddText ? 14 : 12,
                  color: const Color(0xFF0360E5),
                ),
              ),
      ),
    );
  }

  Widget _buildNotifyButton() {
    if (_isRailStyle) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isBusy ? null : _handleNotify,
        child: Container(
          width: 68,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0360E5)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'NOTIFY',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0360E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 16 / 10,
                  ),
                ),
        ),
      );
    }

    if (_isCompactStyle) {
      return GestureDetector(
        onTap: _isBusy ? null : _handleNotify,
        child: _compactCircle(
          child: _isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.notifications_outlined,
                  size: 18,
                  color: Color(0xFF0A243F),
                ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: _isBusy ? null : _handleNotify,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: Color(0xFF0A243F)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Notify',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF0A243F),
                ),
              ),
      ),
    );
  }

  Widget _buildCounter() {
    final stock = _resolvedAvailableStock;
    final hasStockLimit =
        widget.product.isQuickEcommerceEnabled && stock != null && stock > 0;
    final maxAllowedQuantity = hasStockLimit ? stock : null;
    final canIncrease =
        maxAllowedQuantity == null || _quantity < maxAllowedQuantity;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6ED)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _isBusy ? null : () => _updateQuantity(_quantity - 1),
            icon: const Icon(Icons.remove, size: 16),
            constraints: const BoxConstraints(minWidth: 30),
            padding: EdgeInsets.zero,
          ),
          Text(
            '$_quantity',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: _isBusy || !canIncrease
                ? null
                : () => _updateQuantity(_quantity + 1),
            icon: const Icon(Icons.add, size: 16),
            constraints: const BoxConstraints(minWidth: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildRailCounter() {
    final stock = _resolvedAvailableStock;
    final hasStockLimit =
        widget.product.isQuickEcommerceEnabled && stock != null && stock > 0;
    final maxAllowedQuantity = hasStockLimit ? stock : null;
    final canIncrease =
        maxAllowedQuantity == null || _quantity < maxAllowedQuantity;

    return Container(
      width: 91,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0360E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isSubmitting
          ? const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RailQuantityControlTapTarget(
                  icon: Icons.remove,
                  onTap: _isBusy ? null : () => _updateQuantity(_quantity - 1),
                ),
                Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                _RailQuantityControlTapTarget(
                  icon: Icons.add,
                  onTap: _isBusy || !canIncrease
                      ? null
                      : () => _updateQuantity(_quantity + 1),
                ),
              ],
            ),
    );
  }

  Widget _buildCompactCounter() {
    final stock = _resolvedAvailableStock;
    final hasStockLimit =
        widget.product.isQuickEcommerceEnabled && stock != null && stock > 0;
    final maxAllowedQuantity = hasStockLimit ? stock : null;
    final canIncrease =
        maxAllowedQuantity == null || _quantity < maxAllowedQuantity;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1E6ED)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _isBusy ? null : () => _updateQuantity(_quantity - 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 14,
                color: _isBusy ? Colors.grey : const Color(0xFF0A243F),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A243F),
              ),
            ),
          ),
          InkWell(
            onTap:
                _isBusy || !canIncrease ? null : () => _updateQuantity(_quantity + 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 14,
                color: _isBusy || !canIncrease
                    ? Colors.grey
                    : const Color(0xFF0A243F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactCircle({required Widget child}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _RailQuantityControlTapTarget extends StatelessWidget {
  const _RailQuantityControlTapTarget({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 40,
        child: Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
