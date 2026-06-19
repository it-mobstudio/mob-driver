import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';

/// Floating "View cart" bar. Drop inside a [Stack] and it positions itself
/// at the bottom-center. Hides itself when the cart is empty.
class ViewCartBar extends StatelessWidget {
  const ViewCartBar({
    super.key,
    this.bottomOffset = 0,
  });

  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (prev, next) {
        // Only rebuild when item count or items list changes
        if (prev is CartLoaded && next is CartLoaded) {
          return prev.summary.itemCount != next.summary.itemCount;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! CartLoaded || state.summary.itemCount == 0) {
          return const SizedBox.shrink();
        }

        final summary = state.summary;
        final itemCount = summary.itemCount;
        final miniImages = summary.items
            .where((i) => i.imageAsset.isNotEmpty)
            .take(3)
            .map((i) => i.imageAsset)
            .toList();

        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return Positioned(
          bottom: bottomOffset + bottomInset + 16,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                AppHaptics.lightTap();
                context.push('/cart');
              },
              child: Container(
                width: 240,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0360E5).withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 240,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0360E5).withValues(alpha: 0.92),
                            const Color(0xFF034FC0).withValues(alpha: 0.86),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            height: 32,
                            child: Stack(
                              children: List.generate(3, (i) {
                                final url =
                                    i < miniImages.length ? miniImages[i] : '';
                                return Positioned(
                                  left: i * 20.0,
                                  child: _MiniImage(url: url),
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
                                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.82),
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniImage extends StatelessWidget {
  const _MiniImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _Placeholder(),
              )
            : const _Placeholder(),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8EDF2),
      child: const Icon(Icons.shopping_bag_outlined,
          size: 16, color: Color(0xFF8D9BB0)),
    );
  }
}
