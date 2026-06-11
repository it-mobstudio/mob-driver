import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_brand_grid.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_category_grid.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_header.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_reward_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_savings_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_why_choose_card.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/product_rail_section.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/section_title.dart';
import 'package:m_o_b_demand_side/shared/main_scaffold.dart';

class HomepageWidget extends StatelessWidget {
  const HomepageWidget({super.key});

  static const String routeName = 'Homepage';
  static const String routePath = '/homepage';

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      showTopSearchBar: false,
      showLocationheader: false,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return switch (state) {
            HomeLoaded(:final data) => RefreshIndicator(
                onRefresh: () async =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
                child: CustomScrollView(
                  slivers: [
                    // Location header — scrolls away with content
                    const SliverToBoxAdapter(child: HomeHeader()),
                    // Search bar — stays pinned with frosted glass when scrolled
                    const SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickySearchDelegate(),
                    ),
                    const SliverToBoxAdapter(child: HomePromoBanner()),
                    const SliverToBoxAdapter(
                      child: SectionTitle(
                          title: 'Explore by categories', topPadding: 24),
                    ),
                    SliverToBoxAdapter(
                      child: HomeCategoryGrid(
                        categories: data.categories,
                        isLoading: false,
                        hasError: false,
                      ),
                    ),
                    const SliverToBoxAdapter(
                        child: SectionTitle(title: 'Top brands for you')),
                    const SliverToBoxAdapter(child: HomeBrandGrid()),
                    const SliverToBoxAdapter(child: HomeSavingsCard()),
                    ...data.productSections.asMap().entries.map((entry) {
                      return SliverToBoxAdapter(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProductRailSection(
                              title: entry.value.title,
                              products: entry.value.products,
                            ),
                            if (entry.key == 0) const HomeWhyChooseCard(),
                          ],
                        ),
                      );
                    }),
                    const SliverToBoxAdapter(child: HomeRewardCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            HomeLoading() || HomeInitial() => const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: HomeHeader()),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickySearchDelegate(),
                  ),
                  SliverToBoxAdapter(child: HomePromoBanner()),
                  SliverToBoxAdapter(
                    child: SectionTitle(
                        title: 'Explore by categories', topPadding: 24),
                  ),
                  SliverToBoxAdapter(
                    child: HomeCategoryGrid(
                      categories: [],
                      isLoading: true,
                      hasError: false,
                    ),
                  ),
                ],
              ),
            HomeError(:final message) => RefreshIndicator(
                onRefresh: () async =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: HomeHeader()),
                    const SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickySearchDelegate(),
                    ),
                    SliverFillRemaining(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 40, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(message),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<HomeBloc>()
                                    .add(HomeRefreshRequested()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          };
        },
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
            Text(
              'Search "Fevicol"',
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    if (isPinned) {
      // Frosted glass: blur content behind + semi-transparent dark overlay
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: const Color(0xFF121212).withValues(alpha: 0.65),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: searchBox,
          ),
        ),
      );
    }

    // Natural position — solid dark, seamlessly blends with HomeHeader above
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: searchBox,
    );
  }

  @override
  bool shouldRebuild(_StickySearchDelegate oldDelegate) => false;
}
