import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';

/// Floating "View cart" bar. Drop inside a [Stack] and it positions itself
/// at the bottom-center. Hides itself when the cart is empty.
class ViewCartBar extends StatelessWidget {
  const ViewCartBar({
    super.key,
    this.bottomOffset = 0,
    this.trackNavBarVisibility = true,
  });

  final double bottomOffset;

  /// Whether to factor the shell's persistent bottom nav bar into this
  /// bar's vertical position. [navBarVisible] is a single global flag shared
  /// by every page, but only pages inside the bottom-tab shell actually have
  /// a nav bar to float above — set this to false on full-screen/pushed
  /// pages (no nav bar present) so a stale flag value from whatever shell
  /// page was visited last can't shove this bar off-screen.
  final bool trackNavBarVisibility;

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
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final hasCart = state is CartLoaded && state.summary.itemCount > 0;
        final summary = hasCart ? state.summary : null;
        final itemCount = summary?.itemCount ?? 0;
        final miniImages = summary == null
            ? const <String>[]
            : summary.items
                .where((i) => i.imageAsset.isNotEmpty)
                .take(3)
                .map((i) => i.imageAsset)
                .toList();

        final content = IgnorePointer(
          ignoring: !hasCart,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 1.2),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offset,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1).animate(
                      animation,
                    ),
                    child: child,
                  ),
                ),
              );
            },
            child: hasCart
                ? _ViewCartBarContent(
                    key: const ValueKey<String>('view-cart-bar'),
                    itemCount: itemCount,
                    miniImages: miniImages,
                  )
                : const SizedBox(
                    key: ValueKey<String>('view-cart-empty'),
                    width: 240,
                    height: kViewCartBarHeight,
                  ),
          ),
        );

        if (!trackNavBarVisibility) {
          return Positioned(
            bottom: bottomOffset + bottomInset + kViewCartBarGap,
            left: 0,
            right: 0,
            child: content,
          );
        }

        // The body extends behind the (now overlay-style) bottom nav bar,
        // so this needs to actively track its visibility: float just above
        // it while it's showing, and drop down near the true screen edge
        // once it slides away — otherwise it either sits hidden underneath
        // the nav bar or leaves a large gap where the nav bar used to
        // reserve space. Synced to the nav bar's own slide duration/curve.
        return ValueListenableBuilder<bool>(
          valueListenable: navBarVisible,
          builder: (context, isNavBarVisible, child) {
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              bottom: bottomOffset +
                  bottomInset +
                  kViewCartBarGap -
                  (isNavBarVisible ? 0 : kBottomNavBarHeight),
              left: 0,
              right: 0,
              child: child!,
            );
          },
          child: content,
        );
      },
    );
  }
}

class _ViewCartBarContent extends StatelessWidget {
  const _ViewCartBarContent({
    super.key,
    required this.itemCount,
    required this.miniImages,
  });

  final int itemCount;
  final List<String> miniImages;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          AppHaptics.lightTap();
          context.push('/cart');
        },
        child: Container(
          width: 240,
          height: kViewCartBarHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 240,
                height: kViewCartBarHeight,
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    if (miniImages.isNotEmpty) ...[
                      SizedBox(
                        width: 32 + ((miniImages.length - 1) * 20),
                        height: 32,
                        child: Stack(
                          children: List.generate(miniImages.length, (i) {
                            return Positioned(
                              left: i * 20.0,
                              child: _MiniImage(url: miniImages[i]),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
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
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 64,
                placeholder: (_, __) => const _Placeholder(),
                errorWidget: (_, __, ___) => const _Placeholder(),
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
