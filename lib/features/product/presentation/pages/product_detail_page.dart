import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/shared/product_cart_action_button.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/product/domain/entities/product_entity.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/widgets/product_detail_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
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
  final Map<String, String?> _selectedVariants = {};

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductBloc>(
      create: (_) => sl<ProductBloc>()
        ..add(ProductDetailRequested(slug: widget.slug)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (context, state) {
              return switch (state) {
                ProductInitial() || ProductLoading() =>
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
                  Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 108),
                              children: [
                                ProductImagesCarousel(images: product.images),
                                const SizedBox(height: 12),
                                ProductInfoBlock(
                                  product: product,
                                  selectedVariants: _selectedVariants,
                                  onVariantSelect: (key, option) =>
                                      setState(() =>
                                          _selectedVariants[key] = option.value),
                                ),
                                DeliveryInfoCard(product: product),
                                const MobCreditBannerSection(),
                                ProductAssuranceSection(),
                                ProductLongDetailsSection(
                                  description: product.productDescription,
                                  features: product.features,
                                  bulletPoints: product.productBulletPoints,
                                ),
                                SimilarProductsSection(
                                  products: similarProducts,
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
                        child:
                            _ProductDetailHeader(onBack: () => _goBack(context)),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ProductDetailBottomBar(product: product),
                      ),
                    ],
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
  const ProductDetailBottomBar({super.key, required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final price = product.vendorPricing.vendorSellingPrice;
    final mrp = product.maximumRetailPrice;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${price.round()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 24 / 18,
                    ),
                  ),
                  if (mrp > 0)
                    Text(
                      'MRP ₹ ${mrp.round()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7E868A),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 14 / 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ProductCartActionButton(
                product: product,
                showAddText: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
