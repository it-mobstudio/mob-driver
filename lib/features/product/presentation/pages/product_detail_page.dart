import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/shared/variant_selection_sheet.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/product_detail_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/similar_products_section.dart';
import 'package:m_o_b_demand_side/shared/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const double _bottomBarBaseReservedHeight = 88;

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

  String _shareUrl(ProductModel product) {
    final base = AppConfig.webAppBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final slug =
        product.slug.trim().isNotEmpty ? product.slug.trim() : widget.slug;
    return '$base/home/product-details/$slug';
  }

  Future<void> _showShareSheet(
    BuildContext context,
    ProductModel product,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ProductShareSheet(
        productTitle: product.title,
        url: _shareUrl(product),
      ),
    );
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
                      final cartItemCount = cartQtyByProductId.values
                          .fold<int>(0, (sum, qty) => sum + qty);
                      final bottomBarReservedHeight =
                          _bottomBarBaseReservedHeight +
                              MediaQuery.paddingOf(context).bottom;
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: PullToRefresh(
                                  onRefresh: () async {
                                    final bloc = context.read<ProductBloc>();
                                    bloc.add(
                                      ProductDetailRefreshRequested(
                                        slug: widget.slug,
                                      ),
                                    );
                                    await bloc.stream.firstWhere(
                                      (s) =>
                                          s is ProductDetailLoaded ||
                                          s is ProductError,
                                    );
                                  },
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      bottom: bottomBarReservedHeight,
                                    ),
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
                                            _selectVariant(
                                                context, key, option),
                                        onMoreOptions:
                                            product.variantOptionCount > 8 ||
                                                    product.childProducts
                                                        .isNotEmpty
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
                                        bulletPoints:
                                            product.productBulletPoints,
                                      ),
                                      SimilarProductsSection(
                                        products: similarProducts,
                                        quantityResolver: (productId) =>
                                            cartQtyByProductId[productId] ?? 0,
                                        isUpdatingResolver: (productId) =>
                                            cartUpdatingKey == productId,
                                        onCartQuantityChanged:
                                            _changeProductQuantity,
                                        onNotifyTap: _handleNotifyTap,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: _ProductDetailHeader(
                              onBack: () => _goBack(context),
                              onShare: () =>
                                  _showShareSheet(context, displayProduct),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ProductDetailBottomBar(
                              product: displayProduct,
                              cartItemCount: cartItemCount,
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
  const _ProductDetailHeader({
    required this.onBack,
    this.onShare,
  });

  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.white.withValues(alpha: 0.10),
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
                onTap: onShare ?? () {},
              ),
            ],
          ),
        ),
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
      onTap: () {
        AppHaptics.lightTap();
        onTap();
      },
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
        },
      ),
    );
  }
}

enum _HeaderActionIcon { back, favorite, share }

class _ProductShareSheet extends StatelessWidget {
  const _ProductShareSheet({
    required this.productTitle,
    required this.url,
  });

  final String productTitle;
  final String url;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open share option.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareText = '$productTitle\n$url';
    final encodedText = Uri.encodeComponent(shareText);
    final encodedUrl = Uri.encodeComponent(url);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.48,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Share the product details',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      AppHaptics.lightTap();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF0A243F),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 18),
              Row(
                children: [
                  _ShareOptionButton(
                    label: 'WhatsApp',
                    iconAsset: 'assets/images/whatsapp-plain.svg',
                    onTap: () => _launch(
                      context,
                      Uri.parse('https://wa.me/?text=$encodedText'),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _ShareOptionButton(
                    label: 'Facebook',
                    iconSize: 24,
                    iconAsset: 'assets/images/facebook-logo.svg',
                    onTap: () => _launch(
                      context,
                      Uri.parse(
                        'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _ShareOptionButton(
                    label: 'Twitter',
                    iconAsset: 'assets/images/twitter.svg',
                    onTap: () => _launch(
                      context,
                      Uri.parse(
                        'https://twitter.com/intent/tweet?text=$encodedText',
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _ShareOptionButton(
                    label: 'Email',
                    iconAsset: 'assets/images/gmail.svg',
                    onTap: () => _launch(
                      context,
                      Uri(
                        scheme: 'mailto',
                        queryParameters: {
                          'subject': productTitle,
                          'body': url,
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Or copy link',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 18 / 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.only(left: 14, right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFB9C0CB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _CopyLinkButton(url: url),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOptionButton extends StatelessWidget {
  const _ShareOptionButton({
    required this.label,
    required this.iconAsset,
    this.iconSize = 24,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () {
          AppHaptics.lightTap();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F8F8),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            iconAsset,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CopyLinkButton extends StatefulWidget {
  const _CopyLinkButton({required this.url});

  final String url;

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _justCopied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    AppHaptics.lightTap();
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    setState(() => _justCopied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _justCopied ? null : _copy,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _justCopied
              ? Row(
                  key: const ValueKey('copied'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1FA855),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Copied',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1FA855),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : const Icon(
                  key: ValueKey('copy'),
                  Icons.copy_rounded,
                  color: Color(0xFF0A243F),
                  size: 22,
                ),
        ),
      ),
    );
  }
}

class ProductDetailBottomBar extends StatelessWidget {
  const ProductDetailBottomBar({
    super.key,
    required this.product,
    required this.cartItemCount,
    required this.quantity,
    required this.isUpdating,
    required this.onCartQuantityChanged,
    required this.onNotifyTap,
    required this.onVariantsTap,
  });

  final ProductEntity product;
  final int cartItemCount;
  final int quantity;
  final bool isUpdating;
  final Future<void> Function(ProductModel product, int quantity)
      onCartQuantityChanged;
  final Future<void> Function(ProductModel product) onNotifyTap;
  final VoidCallback onVariantsTap;

  @override
  Widget build(BuildContext context) {
    final inCart = !product.shouldShowNotify && quantity > 0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 16, 24 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
          ),
        ],
      ),
      child: inCart ? _buildInCartRow(context) : _buildAddRow(context),
    );
  }

  Widget _buildInCartRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/cart');
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E6ED)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF0A243F),
                        size: 22,
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            '$cartItemCount',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'View cart',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: ProductCartActionButton(
              product: product,
              style: ProductCartActionButtonStyle.rail,
              showCounter: true,
              quantity: quantity,
              isFetchingCart: isUpdating,
              openVariantsOnAdd: false,
              height: 48,
              onQuantityChanged: (nextQuantity) =>
                  onCartQuantityChanged(product, nextQuantity),
              onNotify: () => onNotifyTap(product),
              onVariantsTap: onVariantsTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 48,
          child: GestureDetector(
            onTap: () {
              AppHaptics.lightTap();
              context.push('/cart');
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE1E6ED)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF0A243F),
                    size: 24,
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      top: -9,
                      right: -9,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          '$cartItemCount',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: SizedBox(
            height: 48,
            child: _buildPrimaryActionButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton() {
    final shouldNotify = product.shouldShowNotify;
    final canAddToCart =
        product.hasVariants || product.vendorPricing.vendorSellingPrice > 0;
    final label = shouldNotify
        ? 'Notify'
        : canAddToCart
            ? 'Add to cart'
            : 'Add for quote';

    return ElevatedButton(
      onPressed: isUpdating
          ? null
          : () {
              if (shouldNotify) {
                onNotifyTap(product);
                return;
              }
              onCartQuantityChanged(product, 1);
            },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF0360E5),
        disabledBackgroundColor: const Color(0xFF8EB8F6),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: isUpdating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
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
                    onPressed: () {
                      AppHaptics.lightTap();
                      Navigator.of(context).pop();
                    },
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
                    onTap: () {
                      AppHaptics.lightTap();
                      Navigator.of(context).pop(seller);
                    },
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
