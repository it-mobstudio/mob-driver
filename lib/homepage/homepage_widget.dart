import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/features/home/models/home_models.dart';
import 'package:m_o_b_demand_side/features/home/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_brand_grid.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_category_grid.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_header.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_promo_banner.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_reward_card.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_savings_card.dart';
import 'package:m_o_b_demand_side/homepage/widgets/home_why_choose_card.dart';
import 'package:m_o_b_demand_side/homepage/widgets/product_rail_section.dart';
import 'package:m_o_b_demand_side/homepage/widgets/section_title.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

class HomepageWidget extends StatefulWidget {
  const HomepageWidget({super.key});

  static const String routeName = 'Homepage';
  static const String routePath = '/homepage';

  @override
  State<HomepageWidget> createState() => _HomepageWidgetState();
}

class _HomepageWidgetState extends State<HomepageWidget> {
  static const HomeRepository _homeRepository = HomeRepository();
  late Future<HomeDataModel> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _homeRepository.getHomeData();
  }

  Future<void> _refreshHomeData() async {
    final future = _homeRepository.getHomeData();
    setState(() {
      _homeDataFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      showTopSearchBar: false,
      showLocationheader: false,
      child: FutureBuilder<HomeDataModel>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          final homeData = snapshot.data ?? HomeDataModel.empty;
          return RefreshIndicator(
            onRefresh: _refreshHomeData,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const HomeHeader(),
                const HomePromoBanner(),
                const SectionTitle(
                  title: 'Explore by categories',
                  topPadding: 24,
                ),
                HomeCategoryGrid(
                  categories: homeData.categories,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                  hasError: snapshot.hasError,
                ),
                const SectionTitle(title: 'Top brands for you'),
                const HomeBrandGrid(),
                const HomeSavingsCard(),
                ...homeData.productSections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProductRailSection(
                        title: section.title,
                        products: section.products,
                      ),
                      if (index == 0) const HomeWhyChooseCard(),
                    ],
                  );
                }),
                const HomeRewardCard(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
