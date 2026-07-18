import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_brand_grid.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_category_grid.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_header.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_live_orders_tray.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_magicquote_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_reward_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_savings_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_why_choose_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/product_rail_section.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/section_title.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/widgets/referral_success_dialog.dart';
import 'package:m_o_b_demand_side/shared/back_to_top_button.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/rotating_search_hint.dart';
import 'package:m_o_b_demand_side/shared/view_cart_bar.dart';

class HomepageWidget extends StatefulWidget {
  const HomepageWidget({super.key, this.showReferralBonus = false});

  final bool showReferralBonus;

  static const String routeName = 'Homepage';
  static const String routePath = '/homepage';

  @override
  State<HomepageWidget> createState() => _HomepageWidgetState();
}

class _HomepageWidgetState extends State<HomepageWidget> {
  final ScrollController _scrollController = ScrollController();
  late final VoidCallback _homeTabReselectionCallback;
  Future<void>? _homeRefreshFuture;
  bool _showBackToTop = false;
  bool _checkingAddressGate = true;
  bool _addressGateRedirecting = false;
  bool _referralDialogShown = false;

  static const double _scrollThreshold = 400;
  static const double _homeRefreshSpinnerTop = 168;
  static const double _homeRefreshSpinnerSize = 56;
  static const double _homeRefreshRevealExtent = 96;

  @override
  void initState() {
    super.initState();
    _homeTabReselectionCallback = _scrollToTop;
    scrollHomeToTop = _homeTabReselectionCallback;
    _scrollController.addListener(_onScroll);
    _runAddressGate();
  }

  Future<void> _runAddressGate() async {
    final selected = await SelectedAddressStore.read();
    if (!mounted) return;
    if (selected != null) {
      setState(() => _checkingAddressGate = false);
      _showReferralDialogIfNeeded();
      return;
    }

    final (addresses, failure) = await sl<AddressRepository>().getAddresses();
    if (!mounted) return;
    if (failure == null && addresses != null && addresses.isNotEmpty) {
      await SelectedAddressStore.save(addresses.first);
      if (!mounted) return;
      setState(() => _checkingAddressGate = false);
      _showReferralDialogIfNeeded();
      return;
    }

    if (failure != null) {
      setState(() => _checkingAddressGate = false);
      _showReferralDialogIfNeeded();
      return;
    }

    _addressGateRedirecting = true;
    context.go(
      '${AddressSelectionWidget.routePath}?hideBack=true',
      extra: {
        'returnToHome': true,
        'showBackButton': false,
        'autoDetectCurrentLocation': true,
      },
    );
  }

  void _showReferralDialogIfNeeded() {
    if (!widget.showReferralBonus || _referralDialogShown) return;
    _referralDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _addressGateRedirecting) return;
      ReferralSuccessDialog.show(
        context,
        amount: 1000,
        walletBalance: 1000,
        onViewWallet: () => context.push(WalletPointsPage.routePath),
      );
    });
  }

  @override
  void dispose() {
    if (identical(scrollHomeToTop, _homeTabReselectionCallback)) {
      scrollHomeToTop = null;
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      navBarVisible.value = false;
    } else if (direction == ScrollDirection.forward) {
      navBarVisible.value = true;
    }
    // Hide while user is actively scrolling up (toward top)
    final show =
        offset > _scrollThreshold && direction != ScrollDirection.forward;
    if (show != _showBackToTop) setState(() => _showBackToTop = show);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _refreshHome() {
    final activeRefresh = _homeRefreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final refreshFuture = _runHomeRefresh();
    _homeRefreshFuture = refreshFuture;
    void clearActiveRefresh() {
      if (_homeRefreshFuture == refreshFuture) {
        _homeRefreshFuture = null;
      }
    }

    refreshFuture.then(
      (_) => clearActiveRefresh(),
      onError: (_, __) => clearActiveRefresh(),
    );
    return refreshFuture;
  }

  Future<void> _runHomeRefresh() async {
    final bloc = context.read<HomeBloc>();
    bloc.add(HomeRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => state is HomeLoaded || state is HomeError,
    );
  }

  Widget _buildHomeLoadedScroll(HomeEntity data, double revealOffset) {
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: HomeHeader()),
        const SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchDelegate(),
        ),
        _HomeRefreshRevealGap(revealOffset: revealOffset),
        const SliverToBoxAdapter(child: HomePromoBanner()),
        const SliverToBoxAdapter(
          child: SectionTitle(
            title: 'Explore by categories',
            topPadding: 24,
          ),
        ),
        SliverToBoxAdapter(
          child: HomeCategoryGrid(
            categories: data.categories,
            isLoading: false,
            hasError: false,
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionTitle(title: 'Top brands for you'),
        ),
        const SliverToBoxAdapter(child: HomeBrandGrid()),
        const SliverToBoxAdapter(child: HomeSavingsCard()),
        const SliverToBoxAdapter(child: HomeMagicQuoteCard()),
        ...data.productSections.asMap().entries.map((entry) {
          final section = entry.value;
          return SliverToBoxAdapter(
            key: ValueKey(
              section.id.isNotEmpty ? section.id : section.title,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProductRailSection(
                  title: section.title,
                  products: section.products,
                ),
                // if (entry.key == 0)
                //   const HomeWhyChooseCard(),
              ],
            ),
          );
        }),
        const SliverToBoxAdapter(child: HomeRewardCard()),
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                kScrollBottomClearance + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeErrorScroll(String message, double revealOffset) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      slivers: [
        const SliverToBoxAdapter(child: HomeHeader()),
        const SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchDelegate(),
        ),
        _HomeRefreshRevealGap(revealOffset: revealOffset),
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<HomeBloc>().add(HomeRefreshRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    if (_checkingAddressGate || _addressGateRedirecting) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Fixed strip so the dark header extends behind the status bar
          // without the scrolling sticky search bar reserving that same
          // inset again (that double-reservation was the variable-height
          // gap seen above the search box on tall-status-bar devices).
          Container(height: topInset, color: const Color(0xFF0A3C35)),
          Expanded(
            child: Stack(
              children: [
                BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    return switch (state) {
                      HomeLoaded(:final data) => PullToRefresh(
                          playSound: true,
                          showSpinner: true,
                          spinnerTopOffset: _homeRefreshSpinnerTop,
                          spinnerSize: _homeRefreshSpinnerSize,
                          revealContentOnRefresh: true,
                          contentRevealExtent: _homeRefreshRevealExtent,
                          dimContentOnRefresh: false,
                          onRefresh: _refreshHome,
                          revealedChildBuilder: (_, revealOffset) =>
                              _buildHomeLoadedScroll(data, revealOffset),
                          child: _buildHomeLoadedScroll(data, 0),
                        ),
                      HomeLoading() ||
                      HomeInitial() =>
                        const _HomeLoadingSkeleton(),
                      HomeError(:final message) => PullToRefresh(
                          playSound: true,
                          showSpinner: true,
                          spinnerTopOffset: _homeRefreshSpinnerTop,
                          spinnerSize: _homeRefreshSpinnerSize,
                          revealContentOnRefresh: true,
                          contentRevealExtent: _homeRefreshRevealExtent,
                          dimContentOnRefresh: false,
                          onRefresh: _refreshHome,
                          revealedChildBuilder: (_, revealOffset) =>
                              _buildHomeErrorScroll(message, revealOffset),
                          child: _buildHomeErrorScroll(message, 0),
                        ),
                    };
                  },
                ),
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: BackToTopButton(
                      visible: _showBackToTop,
                      onTap: _scrollToTop,
                    ),
                  ),
                ),
                const HomeLiveOrdersTray(),
                const ViewCartBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  const _StickySearchDelegate();

  // 8 top padding + 48 search bar + 8 bottom padding
  static const double _height = 64.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isPinned = shrinkOffset > 1;

    final searchBox = GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD0D4DC), width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/images/Searchicon.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 12),
            const RotatingSearchHint(),
          ],
        ),
      ),
    );

    if (isPinned) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.white.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: searchBox,
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF0A3C35),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: searchBox,
    );
  }

  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) => false;
}

class _HomeRefreshRevealGap extends StatelessWidget {
  const _HomeRefreshRevealGap({required this.revealOffset});

  final double revealOffset;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: revealOffset),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, height, child) {
          return Container(
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A3C35), Color(0xFF0A3C35)],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Home skeleton ─────────────────────────────────────────────────────────────

class _HomeLoadingSkeleton extends StatelessWidget {
  const _HomeLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _HomeHeaderSkeleton()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchDelegate(),
        ),
        SliverToBoxAdapter(child: HomePromoBanner()),
        SliverToBoxAdapter(child: _SkeletonSectionTitle(width: 180)),
        SliverToBoxAdapter(child: _CategoryGridSkeleton()),
        SliverToBoxAdapter(child: _SkeletonSectionTitle(width: 150)),
        SliverToBoxAdapter(child: _BrandGridSkeleton()),
        SliverToBoxAdapter(child: _SavingsCardSkeleton()),
        SliverToBoxAdapter(child: _ProductRailSkeleton()),
        SliverToBoxAdapter(child: _ProductRailSkeleton()),
        SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// Purely visual placeholder for HomeHeader — never mount the real,
// API-fetching HomeHeader here. It used to sit in this skeleton screen
// directly, so every time HomeBloc flipped from HomeLoading to HomeLoaded
// the switch below swapped to a differently-typed widget tree, unmounting
// this one and mounting a brand new HomeHeader from scratch — restarting
// its own address/store-status fetch and re-showing its internal loading
// state a second time (the "text, then loader, then text" flicker).
class _HomeHeaderSkeleton extends StatelessWidget {
  const _HomeHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A3C35),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  height: 18,
                  child: _SkeletonFill(borderRadius: 6),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  height: 14,
                  child: _SkeletonFill(borderRadius: 4),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 72,
            height: 36,
            child: _SkeletonFill(borderRadius: 18),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: _SkeletonFill(borderRadius: 18),
          ),
        ],
      ),
    );
  }
}

/// Shimmer box that fills its parent — use inside Expanded/SizedBox.expand.
class _SkeletonFill extends StatefulWidget {
  const _SkeletonFill({this.borderRadius = 10});
  final double borderRadius;

  @override
  State<_SkeletonFill> createState() => _SkeletonFillState();
}

class _SkeletonFillState extends State<_SkeletonFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final w = rect.width <= 0 ? 1.0 : rect.width;
            final dx = (2 * w * _ctrl.value) - w;
            return LinearGradient(
              colors: const [
                Color(0xFFE9E9E9),
                Color(0xFFF5F5F5),
                Color(0xFFE9E9E9)
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1 + dx / w, 0),
              end: Alignment(1 + dx / w, 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _SkeletonSectionTitle extends StatelessWidget {
  const _SkeletonSectionTitle({this.width = 160});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: SizedBox(
        width: width,
        height: 20,
        child: const _SkeletonFill(borderRadius: 6),
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 13,
          childAspectRatio: 76 / 114,
        ),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _SkeletonFill(borderRadius: 12)),
            SizedBox(height: 6),
            SizedBox(height: 10, child: _SkeletonFill(borderRadius: 4)),
          ],
        ),
      ),
    );
  }
}

class _BrandGridSkeleton extends StatelessWidget {
  const _BrandGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 104 / 160,
        ),
        itemBuilder: (_, __) => const _SkeletonFill(borderRadius: 16),
      ),
    );
  }
}

class _SavingsCardSkeleton extends StatelessWidget {
  const _SavingsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SizedBox(
        height: 181,
        child: _SkeletonFill(borderRadius: 16),
      ),
    );
  }
}

class _ProductRailSkeleton extends StatelessWidget {
  const _ProductRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 140,
          child: _SkeletonSectionTitle(width: 140),
        ),
        SizedBox(
          height: 276,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const SizedBox(
              width: 136,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 170, child: _SkeletonFill(borderRadius: 12)),
                  SizedBox(height: 8),
                  SizedBox(height: 14, child: _SkeletonFill(borderRadius: 6)),
                  SizedBox(height: 6),
                  SizedBox(
                      height: 14,
                      width: 80,
                      child: _SkeletonFill(borderRadius: 6)),
                  SizedBox(height: 10),
                  SizedBox(height: 36, child: _SkeletonFill(borderRadius: 8)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
