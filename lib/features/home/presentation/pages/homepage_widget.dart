import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const HomeHeader(),
                    const HomePromoBanner(),
                    const SectionTitle(
                        title: 'Explore by categories', topPadding: 24),
                    HomeCategoryGrid(
                      categories: data.categories,
                      isLoading: false,
                      hasError: false,
                    ),
                    const SectionTitle(title: 'Top brands for you'),
                    const HomeBrandGrid(),
                    const HomeSavingsCard(),
                    ...data.productSections.asMap().entries.map((entry) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProductRailSection(
                            title: entry.value.title,
                            products: entry.value.products,
                          ),
                          if (entry.key == 0) const HomeWhyChooseCard(),
                        ],
                      );
                    }),
                    const HomeRewardCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            HomeLoading() || HomeInitial() => ListView(
                padding: EdgeInsets.zero,
                children: [
                  const HomeHeader(),
                  const HomePromoBanner(),
                  const SectionTitle(
                      title: 'Explore by categories', topPadding: 24),
                  HomeCategoryGrid(
                    categories: const [],
                    isLoading: true,
                    hasError: false,
                  ),
                ],
              ),
            HomeError(:final message) => RefreshIndicator(
                onRefresh: () async =>
                    context.read<HomeBloc>().add(HomeRefreshRequested()),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const HomeHeader(),
                    const HomePromoBanner(),
                    Center(
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
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
