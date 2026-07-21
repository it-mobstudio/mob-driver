import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/product/data/models/product_models.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

enum ProductCartActionButtonStyle {
  defaultStyle,
  compact,
  rail,
}

const _cartActionAnimationDuration = Duration(milliseconds: 250);
const _cartActionHeight = 40.0;
// Rapid +/- taps update the on-screen number immediately but only send one
// network request for the final settled quantity, instead of racing (and
// mostly dropping) one request per tap.
const _quantityUpdateDebounce = Duration(milliseconds: 500);

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
    this.openVariantsOnAdd = true,
    this.height,
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
  final bool openVariantsOnAdd;
  // Overrides the default 40px height (compact circular buttons are exempt —
  // their size is fixed by design). Used where a page needs a taller button,
  // e.g. the 48px sticky bar on product details.
  final double? height;
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
  Timer? _quantityDebounce;

  bool get _isCompactStyle =>
      widget.style == ProductCartActionButtonStyle.compact || widget.compact;

  bool get _isRailStyle => widget.style == ProductCartActionButtonStyle.rail;

  double get _height => widget.height ?? _cartActionHeight;

  bool get _isBusy =>
      widget.isFetching || widget.isFetchingCart || _isSubmitting;

  bool get _shouldOpenVariantsOnAdd =>
      widget.openVariantsOnAdd && widget.onVariantsTap != null;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity <= 0 ? 1 : widget.quantity;
  }

  @override
  void didUpdateWidget(ProductCartActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.addToCartProductId !=
        widget.product.addToCartProductId) {
      _quantityDebounce?.cancel();
      _quantityDebounce = null;
      _quantity = widget.quantity <= 0 ? 1 : widget.quantity;
      return;
    }
    // Skip while a debounced tap hasn't been sent yet — otherwise a parent
    // rebuild triggered by something unrelated (e.g. redeem points) can
    // clobber taps the user just made with the still-stale server quantity.
    if (_quantityDebounce == null &&
        oldWidget.quantity != widget.quantity &&
        widget.quantity > 0) {
      _quantity = widget.quantity;
    }
  }

  @override
  void dispose() {
    _quantityDebounce?.cancel();
    super.dispose();
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
    AppHaptics.addToCart();
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
    AppHaptics.lightTap();
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
    AppHaptics.lightTap();
    await _runWithBusy(action);
  }

  void _updateQuantity(int next) {
    if (next > _quantity) {
      AppHaptics.addToCart();
    } else {
      AppHaptics.lightTap();
    }
    final clamped = next < 0 ? 0 : next;
    if (clamped == 0) {
      _quantityDebounce?.cancel();
      _quantityDebounce = null;
      // Don't setState(_quantity = 0) here — that would repaint this widget
      // with "0" still inside the counter (showCounter hasn't flipped off
      // yet), then the parent's rebuild swaps in the ADD button a frame
      // later. Skipping straight to notifying the parent avoids that
      // 1 -> 0 -> ADD flash and goes straight to 1 -> ADD.
      widget.onQuantityChanged?.call(0);
      return;
    }
    final stock = _resolvedAvailableStock;
    final capped =
        stock != null && stock > 0 ? clamped.clamp(1, stock) : clamped;
    // The number itself updates immediately (below); the network call is
    // debounced so a burst of taps only sends one request for the final
    // quantity instead of one per tap.
    setState(() => _quantity = capped);
    _quantityDebounce?.cancel();
    _quantityDebounce = Timer(_quantityUpdateDebounce, () {
      // Timer.cancel() doesn't null this out, and it doesn't clear itself
      // once it fires either — leaving it set would permanently disable the
      // didUpdateWidget sync below (it only re-syncs while no debounce is
      // pending), causing this widget's _quantity to get stuck on a stale
      // value forever after the very first debounced tap.
      _quantityDebounce = null;
      widget.onQuantityChanged?.call(capped);
    });
  }

  void _showStockLimitToast() {
    AppHaptics.lightTap();
    final stock = _resolvedAvailableStock;
    final message = stock != null && stock > 0
        ? 'Sorry, we have only $stock pieces available for this item!'
        : 'Sorry, this item is currently out of stock.';
    TopSnackBar.show(
      context,
      message: message,
      type: TopSnackBarType.stock,
    );
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
    final showQuantitySelector = widget.showCounter && !shouldShowNotify;

    Widget child;
    if (showQuantitySelector) {
      if (_isRailStyle) {
        child = _buildRailCounter();
      } else {
        child = _isCompactStyle ? _buildCompactCounter() : _buildCounter();
      }
    } else if (shouldShowNotify) {
      child = _buildNotifyButton();
    } else if (shouldShowAdd) {
      child =
          _buildAddButton(hasVariants: hasVariants, variantCount: variantCount);
    } else {
      child = _buildQuoteButton();
    }

    return _AnimatedCartActionShell(
      isCounter: showQuantitySelector,
      style: widget.style,
      compact: widget.compact,
      height: _height,
      child: KeyedSubtree(
        key: ValueKey<String>(
          showQuantitySelector
              ? 'counter'
              : shouldShowNotify
                  ? 'notify'
                  : shouldShowAdd
                      ? 'add'
                      : 'quote',
        ),
        child: child,
      ),
    );
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
                if (hasVariants && _shouldOpenVariantsOnAdd) {
                  AppHaptics.lightTap();
                  widget.onVariantsTap!.call();
                  return;
                }
                _handleAdd();
              },
        child: Container(
          width: 68,
          height: _height,
          clipBehavior: Clip.antiAlias,
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
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Center(
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
                    if (hasVariants &&
                        variantCount > 0 &&
                        widget.openVariantsOnAdd)
                      Container(
                        width: double.infinity,
                        height: 12,
                        color: const Color(0x1A0360E5),
                        alignment: Alignment.center,
                        child: Text(
                          '$variantCount options',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7E7E7E),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            height: 12 / 8,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    }

    if (_isCompactStyle) {
      return GestureDetector(
        onTap: _isBusy
            ? null
            : () {
                if (hasVariants && _shouldOpenVariantsOnAdd) {
                  AppHaptics.lightTap();
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
      height: _height,
      child: ElevatedButton(
        onPressed: _isBusy
            ? null
            : () {
                if (hasVariants && _shouldOpenVariantsOnAdd) {
                  AppHaptics.lightTap();
                  widget.onVariantsTap!.call();
                  return;
                }
                _handleAdd();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0360E5),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, _height),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ADD',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                  if (hasVariants &&
                      variantCount > 0 &&
                      widget.openVariantsOnAdd) ...[
                    const SizedBox(width: 6),
                    Text(
                      '$variantCount options',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7E7E7E),
                        fontWeight: FontWeight.w500,
                        fontSize: 8,
                        height: 12 / 8,
                      ),
                    ),
                  ],
                ],
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
      height: _height,
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
                  height: widget.showAddText ? 20 / 14 : 16 / 12,
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
          height: _height,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 16 / 12,
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
      height: _height,
      child: OutlinedButton(
        onPressed: _isBusy ? null : _handleNotify,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  height: 16 / 12,
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
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6ED)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityIconButton(
            leading: true,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0A243F),
            disabledColor: Colors.grey,
            width: 40,
            height: _height,
            icon: Icons.remove,
            onPressed: _isBusy ? null : () => _updateQuantity(_quantity - 1),
          ),
          AnimatedSwitcher(
            duration: _cartActionAnimationDuration,
            transitionBuilder: _fadeScaleTransition,
            child: Text(
              '$_quantity',
              key: ValueKey<int>(_quantity),
              style:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          _QuantityIconButton(
            leading: false,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0A243F),
            disabledColor: Colors.grey,
            width: 40,
            height: _height,
            icon: Icons.add,
            onPressed: _isBusy
                ? null
                : canIncrease
                    ? () => _updateQuantity(_quantity + 1)
                    : _showStockLimitToast,
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
      width: double.infinity,
      height: _height,
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
                _QuantityIconButton(
                  leading: true,
                  icon: Icons.remove,
                  onPressed:
                      _isBusy ? null : () => _updateQuantity(_quantity - 1),
                  width: 38,
                  height: _height,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledColor: Colors.white.withValues(alpha: 0.45),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: _cartActionAnimationDuration,
                      transitionBuilder: _fadeScaleTransition,
                      child: Text(
                        '$_quantity',
                        key: ValueKey<int>(_quantity),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ),
                ),
                _QuantityIconButton(
                  leading: false,
                  icon: Icons.add,
                  width: 38,
                  height: _height,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledColor: Colors.white.withValues(alpha: 0.45),
                  onPressed: _isBusy
                      ? null
                      : canIncrease
                          ? () => _updateQuantity(_quantity + 1)
                          : _showStockLimitToast,
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
      height: _cartActionHeight,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
          _QuantityIconButton(
            leading: true,
            icon: Icons.remove,
            onPressed: _isBusy ? null : () => _updateQuantity(_quantity - 1),
            width: 26,
            height: _cartActionHeight,
            iconSize: 14,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0A243F),
            disabledColor: Colors.grey,
          ),
          SizedBox(
            width: 18,
            child: AnimatedSwitcher(
              duration: _cartActionAnimationDuration,
              transitionBuilder: _fadeScaleTransition,
              child: Text(
                '$_quantity',
                key: ValueKey<int>(_quantity),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A243F),
                ),
              ),
            ),
          ),
          _QuantityIconButton(
            leading: false,
            icon: Icons.add,
            onPressed: _isBusy
                ? null
                : canIncrease
                    ? () => _updateQuantity(_quantity + 1)
                    : _showStockLimitToast,
            width: 26,
            height: _cartActionHeight,
            iconSize: 14,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0A243F),
            disabledColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _compactCircle({required Widget child}) {
    return Container(
      width: _cartActionHeight,
      height: _cartActionHeight,
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

class _AnimatedCartActionShell extends StatelessWidget {
  const _AnimatedCartActionShell({
    required this.isCounter,
    required this.style,
    required this.compact,
    required this.height,
    required this.child,
  });

  final bool isCounter;
  final ProductCartActionButtonStyle style;
  final bool compact;
  // Ignored for the compact circular style, whose size is fixed by design.
  final double height;
  final Widget child;

  bool get _isCompact =>
      style == ProductCartActionButtonStyle.compact || compact;

  bool get _isRail => style == ProductCartActionButtonStyle.rail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedWidth = constraints.hasBoundedWidth &&
            constraints.maxWidth.isFinite &&
            constraints.maxWidth > 0;
        final double width = switch ((_isRail, _isCompact, isCounter)) {
          (true, _, true) => hasBoundedWidth ? constraints.maxWidth : 96,
          (true, _, false) => 68,
          (_, true, true) => 78,
          (_, true, false) => _cartActionHeight,
          (_, _, true) => hasBoundedWidth ? constraints.maxWidth : 104,
          (_, _, false) => hasBoundedWidth ? constraints.maxWidth : 88,
        };
        final double effectiveHeight = _isCompact ? _cartActionHeight : height;

        return AnimatedContainer(
          duration: _cartActionAnimationDuration,
          curve: Curves.easeOutCubic,
          width: width,
          height: effectiveHeight,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: AnimatedSwitcher(
            duration: _cartActionAnimationDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: child,
          ),
        );
      },
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  const _QuantityIconButton({
    required this.icon,
    required this.onPressed,
    required this.leading,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.disabledColor,
    required this.width,
    required this.height,
    this.iconSize = 16,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledColor;
  final double width;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isEnabled ? foregroundColor : disabledColor,
          ),
        ),
      ),
    );
  }
}

Widget _fadeScaleTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: animation, child: child),
  );
}
