import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/home/data/models/home_models.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/features/home/presentation/widgets/home_category_grid.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class CategoriesPage extends StatefulWidget {
  static const String routeName = 'Categories';
  static const String routePath = '/categories';

  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const _CategoriesHeader(),
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoaded) {
                  return _CategoriesContent(categories: state.data.categories);
                }
                if (state is HomeError) {
                  return _CategoriesError(message: state.message);
                }
                return const _CategoriesSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  const _CategoriesHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE7EAF0), width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(HomepageWidget.routePath);
                }
              },
              icon: const AppBackIcon(),
              tooltip: 'Back',
            ),
            Expanded(
              child: Text(
                'Categories',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({required this.categories});

  final List<HomeCategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories
        .where((category) => category.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (visibleCategories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    return PullToRefresh(
      onRefresh: () async {
        context.read<HomeBloc>().add(HomeRefreshRequested());
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        itemCount: visibleCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 13,
          childAspectRatio: 76 / 114,
        ),
        itemBuilder: (context, index) {
          return Center(
            child: HomeCategoryTile(category: visibleCategories[index]),
          );
        },
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFD32F2F),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF596378),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(HomeRefreshRequested());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 13,
        childAspectRatio: 76 / 114,
      ),
      itemBuilder: (_, __) {
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}
