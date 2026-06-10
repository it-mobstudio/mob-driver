import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/shared/variant_selection_sheet.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/product_detail_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/similar_products_section.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';

class ProductDetailPage extends StatefulWidget {
  static const String routeName = 'ProductDetailPage';
  static const String routePath = '/product-detail';

  final String slug;

  const ProductDetailPage({super.key, required this.slug});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Map<String, String?> _selectedVariants = <String, String?>{};
  ProductSellerOffer? _selectedSeller;

  Future<void> _changeProductQuantity(
    ProductModel product,
    int quantity,
  ) async {
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

  Future<void> _showVariantSheet(
    BuildContext context,
    ProductModel product,
    Map<String, int> cartQtyByProductId,
    String? cartUpdatingKey,
  ) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => VariantSelectionSheet(
        product: product,
        quantityResolver: (productId) => cartQtyByProductId[productId] ?? 0,
        isUpdatingResolver: (productId) => cartUpdatingKey == productId,
        onCartQuantityChanged: _changeProductQuantity,
        onNotifyTap: _handleNotifyTap,
      ),
    );
  }

  void _selectVariant(
    BuildContext context,
    String key,
    ProductVariantOption option,
  ) {
    setState(() {
      _selectedVariants[key] = option.value;
    });
    context.read<ProductBloc>().add(
          ProductDetailRequested(
            slug: widget.slug,
            mobSku: option.mobSku.isNotEmpty ? option.mobSku : null,
          ),
        );
  }

  ProductModel _productForSeller(ProductModel product) {
    final seller = _selectedSeller;
    if (seller == null) return product;

    return ProductModel(
      id: product.id,
      slug: product.slug,
      title: product.title,
      mobSku: product.mobSku,
      maximumRetailPrice: product.maximumRetailPrice,
      rating: product.rating,
      reviewCount: product.reviewCount,
      productDescription: product.productDescription,
      productBulletPoints: product.productBulletPoints,
      vendorPricing: VendorPricing(
        vendorSellingPrice: seller.vendorSellingPrice,
        discount: seller.discount,
        fullfillmentLatency: seller.fullfillmentLatency,
        vendorProductId: seller.vendorProductId,
        bmpId: seller.bmpId,
        quickEcommerceEnabled: seller.quickEcommerceEnabled,
      ),
      images: product.images,
      features: product.features,
      variants: product.variants,
      variantAttributes: product.variantAttributes,
      availableOptions: product.availableOptions,
      activeVariantSelections: product.activeVariantSelections,
      variantCombinations: product.variantCombinations,
      sellers: product.sellers,
      brandName: product.brandName,
      brandLogoUrl: product.brandLogoUrl,
      brandSegmentName: product.brandSegmentName,
      quickCommerceCategoryName: product.quickCommerceCategoryName,
      badgeOption: product.badgeOption,
      stock: seller.stock,
      stockDetailsStock: seller.stock,
      quickEcommerceEnabled:
          seller.quickEcommerceEnabled || product.quickEcommerceEnabled,
      childProducts: product.childProducts,
    );
  }

  void _syncSelectedSeller(ProductModel product) {
    if (product.sellers.isEmpty) {
      _selectedSeller = null;
      return;
    }

    final currentVendorProductId = _selectedSeller?.vendorProductId;
    final matchingSeller =
        product.sellers.cast<ProductSellerOffer?>().firstWhere(
              (seller) =>
                  seller?.vendorProductId.isNotEmpty == true &&
                  seller!.vendorProductId == currentVendorProductId,
              orElse: () => null,
            );
    _selectedSeller = matchingSeller ?? product.sellers.first;
  }

  Future<void> _showSellerSheet(
      BuildContext context, ProductModel product) async {
    if (product.sellers.length <= 1 || !mounted) return;
    final seller = await showModalBottomSheet<ProductSellerOffer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SellerSelectionSheet(
        sellers: product.sellers,
        selectedSeller: _selectedSeller,
      ),
    );

    if (seller != null && mounted) {
      setState(() {
        _selectedSeller = seller;
      });
    }
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

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

    return BlocProvider<ProductBloc>(
      create: (_) =>
          sl<ProductBloc>()..add(ProductDetailRequested(slug: widget.slug)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return switch (state) {
                ProductInitial() ||
                ProductLoading() =>
                  const ProductDetailSkeleton(),
                ProductError(:final message) => Column(
                    children: [
                      _ProductDetailHeader(onBack: () => _goBack(context)),
                      Expanded(
                        child: ErrorStateView(
                          message: message,
                          onRetry: () => context.read<ProductBloc>().add(
                                ProductDetailRequested(slug: widget.slug),
                              ),
                        ),
                      ),
                    ],
                  ),
                ProductDetailLoaded(:final product, :final similarProducts) =>
                  Builder(
                    builder: (context) {
                      _syncSelectedSeller(product);
                      final displayProduct = _productForSeller(product);
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.only(bottom: 108),
                                  children: [
                                    ProductImagesCarousel(
                                        images: product.images),
                                    const SizedBox(height: 12),
                                    ProductInfoBlock(
                                      product: displayProduct,
                                    ),
                                    VariantOptionsSection(
                                      product: product,
                                      variants: product.variants,
                                      selectedVariants: _selectedVariants,
                                      onSelect: (key, option) =>
                                          _selectVariant(context, key, option),
                                      onMoreOptions:
                                          product.variantOptionCount > 8 ||
                                                  product
                                                      .childProducts.isNotEmpty
                                              ? () => _showVariantSheet(
                                                    context,
                                                    product,
                                                    cartQtyByProductId,
                                                    cartUpdatingKey,
                                                  )
                                              : null,
                                    ),
                                    ProductDeliverySection(
                                      product: displayProduct,
                                      onViewOtherSellers:
                                          product.sellers.length > 1
                                              ? () => _showSellerSheet(
                                                    context,
                                                    product,
                                                  )
                                              : null,
                                    ),
                                    const MobCreditBannerSection(),
                                    const ProductAssuranceSection(),
                                    ProductLongDetailsSection(
                                      description: product.productDescription,
                                      features: product.features,
                                      bulletPoints: product.productBulletPoints,
                                    ),
                                    SimilarProductsSection(
                                      products: similarProducts,
                                      onCartQuantityChanged:
                                          _changeProductQuantity,
                                      onNotifyTap: _handleNotifyTap,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: _ProductDetailHeader(
                                onBack: () => _goBack(context)),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ProductDetailBottomBar(
                              product: displayProduct,
                              quantity: cartQtyByProductId[
                                      displayProduct.addToCartProductId] ??
                                  0,
                              isUpdating: cartUpdatingKey ==
                                  displayProduct.addToCartProductId,
                              onCartQuantityChanged: _changeProductQuantity,
                              onNotifyTap: _handleNotifyTap,
                              onVariantsTap: () => _showVariantSheet(
                                context,
                                product,
                                cartQtyByProductId,
                                cartUpdatingKey,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ProductListLoaded() ||
                ProductSearchLoaded() =>
                  const ProductDetailSkeleton(),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ProductDetailHeader extends StatelessWidget {
  const _ProductDetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: _HeaderActionIcon.back,
            onTap: onBack,
          ),
          const Spacer(),
          _HeaderIconButton(
            icon: _HeaderActionIcon.favorite,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(
            icon: _HeaderActionIcon.share,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final _HeaderActionIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(10),
        decoration: ShapeDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: Color(0xFFD0D4DC),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: switch (icon) {
          _HeaderActionIcon.back => SvgPicture.asset(
              'assets/images/Back.svg',
              width: 16,
              height: 16,
            ),
          _HeaderActionIcon.share => SvgPicture.asset(
              'assets/images/share.svg',
              width: 16,
              height: 16,
            ),
          _HeaderActionIcon.favorite => SvgPicture.asset(
              'assets/images/Search.svg',
              width: 16,
              height: 16,
            ),
          _ => CustomPaint(
              painter: _HeaderActionIconPainter(icon),
              size: const Size.square(16),
            ),
        },
      ),
    );
  }
}

enum _HeaderActionIcon { back, favorite, share }

class _HeaderActionIconPainter extends CustomPainter {
  const _HeaderActionIconPainter(this.icon);

  final _HeaderActionIcon icon;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A243F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (icon) {
      case _HeaderActionIcon.back:
        final path = Path()
          ..moveTo(size.width * 0.62, size.height * 0.18)
          ..lineTo(size.width * 0.28, size.height * 0.50)
          ..lineTo(size.width * 0.62, size.height * 0.82);
        canvas.drawPath(path, paint);
        break;
      case _HeaderActionIcon.favorite:
        final path = Path()
          ..moveTo(size.width * 0.50, size.height * 0.84)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.62,
            size.width * 0.08,
            size.height * 0.45,
            size.width * 0.14,
            size.height * 0.28,
          )
          ..cubicTo(
            size.width * 0.20,
            size.height * 0.10,
            size.width * 0.40,
            size.height * 0.12,
            size.width * 0.50,
            size.height * 0.30,
          )
          ..cubicTo(
            size.width * 0.60,
            size.height * 0.12,
            size.width * 0.80,
            size.height * 0.10,
            size.width * 0.86,
            size.height * 0.28,
          )
          ..cubicTo(
            size.width * 0.92,
            size.height * 0.45,
            size.width * 0.82,
            size.height * 0.62,
            size.width * 0.50,
            size.height * 0.84,
          );
        canvas.drawPath(path, paint);
        break;
      case _HeaderActionIcon.share:
        final left = Offset(size.width * 0.25, size.height * 0.55);
        final topRight = Offset(size.width * 0.72, size.height * 0.26);
        final bottomRight = Offset(size.width * 0.72, size.height * 0.76);
        canvas.drawLine(left, topRight, paint);
        canvas.drawLine(left, bottomRight, paint);
        canvas.drawCircle(left, 2.1, paint);
        canvas.drawCircle(topRight, 2.1, paint);
        canvas.drawCircle(bottomRight, 2.1, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderActionIconPainter oldDelegate) {
    return oldDelegate.icon != icon;
  }
}

class ProductDetailBottomBar extends StatelessWidget {
  const ProductDetailBottomBar({
    super.key,
    required this.product,
    required this.quantity,
    required this.isUpdating,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
    required this.onVariantsTap,
  });

  final ProductEntity product;
  final int quantity;
  final bool isUpdating;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;
  final VoidCallback onVariantsTap;

  @override
  Widget build(BuildContext context) {
    final inCart = !product.shouldShowNotify && quantity > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE7EAF0)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: inCart ? _buildInCartRow(context) : _buildAddRow(context),
      ),
    );
  }

  Widget _buildInCartRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.go('/cart'),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0360E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View cart',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 22 / 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ProductCartActionButton(
          product: product,
          showCounter: true,
          quantity: quantity,
          isFetchingCart: isUpdating,
          onQuantityChanged: (nextQuantity) =>
              onCartQuantityChanged(product, nextQuantity),
          onNotify: () => onNotifyTap(product),
          onVariantsTap: onVariantsTap,
        ),
      ],
    );
  }

  Widget _buildAddRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ProductCartActionButton(
            product: product,
            showCounter: false,
            quantity: 1,
            isFetchingCart: isUpdating,
            showAddText: true,
            onAdd: (nextQuantity) =>
                onCartQuantityChanged(product, nextQuantity),
            onAddForQuote: (nextQuantity) =>
                onCartQuantityChanged(product, nextQuantity),
            onNotify: () => onNotifyTap(product),
            onVariantsTap: onVariantsTap,
          ),
        ),
      ],
    );
  }
}

class _SellerSelectionSheet extends StatelessWidget {
  const _SellerSelectionSheet({
    required this.sellers,
    required this.selectedSeller,
  });

  final List<ProductSellerOffer> sellers;
  final ProductSellerOffer? selectedSeller;

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
                children: [
                  Expanded(
                    child: Text(
                      'Select partner',
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
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                itemCount: sellers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final seller = sellers[index];
                  final isSelected =
                      selectedSeller?.vendorProductId == seller.vendorProductId;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(seller),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0A243F)
                                    : const Color(0xFFAAB3C2),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Color(0xFF0A243F),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'By ${seller.bmpId.isNotEmpty ? seller.bmpId : 'MOB Partner'}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF0A243F),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 18 / 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/car.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        seller.fullfillmentLatency.isNotEmpty
                                            ? seller.fullfillmentLatency
                                            : 'Next day delivery',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF57627A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 18 / 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '₹ ${seller.vendorSellingPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 24 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
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
