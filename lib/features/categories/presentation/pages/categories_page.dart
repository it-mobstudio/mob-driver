import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/home/data/models/home_models.dart';
import 'package:m_o_b_demand_side/features/home/presentation/pages/homepage_widget.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_listing_page.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';

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
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF0A243F),
                size: 24,
              ),
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        itemCount: visibleCategories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final category = visibleCategories[index];
          final tiles = _tilesFor(category);
          if (tiles.isEmpty) return const SizedBox.shrink();

          return _CategorySection(
            title: category.name,
            tiles: tiles,
          );
        },
      ),
    );
  }

  List<_CategoryTileData> _tilesFor(HomeCategoryModel category) {
    final subCategories = category.subCategories
        .where((item) => item.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    if (subCategories.isEmpty) {
      return [
        _CategoryTileData(
          name: category.name,
          categoryName: category.name,
          categorySlug: category.slug,
          subCategorySlug: '',
          imageUrl: category.imageUrl,
        ),
      ];
    }

    return subCategories.map((item) {
      return _CategoryTileData(
        name: item.name,
        categoryName: category.name,
        categorySlug: category.slug,
        subCategorySlug: item.slug,
        imageUrl: item.imageUrl.isNotEmpty ? item.imageUrl : category.imageUrl,
      );
    }).toList();
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.tiles,
  });

  final String title;
  final List<_CategoryTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 22 / 16,
            ),
          ),
        ),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 13,
            childAspectRatio: 76 / 106,
          ),
          itemBuilder: (context, index) {
            return _CategoryTile(tile: tiles[index]);
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.tile});

  final _CategoryTileData tile;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        context.push(
          ProductListingPage.routePath,
          extra: {
            'category': tile.categoryName,
            'slug': tile.categorySlug,
            if (tile.subCategorySlug.isNotEmpty)
              'subCategorySlug': tile.subCategorySlug,
            if (tile.subCategorySlug.isNotEmpty)
              'subCategoryName': tile.name,
          },
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment(0.07, 0.07),
                  end: Alignment(0.91, 1),
                  colors: [
                    Color(0xFFFFF2EE),
                    Color(0xFFFFE4B0),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: tile.imageUrl.isEmpty
                  ? const Icon(
                      Icons.category_outlined,
                      color: Color(0xFF0A243F),
                      size: 30,
                    )
                  : CachedNetworkImage(
                      imageUrl: tile.imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 140,
                      fadeInDuration: const Duration(milliseconds: 180),
                      fadeOutDuration: Duration.zero,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.category_outlined,
                        color: Color(0xFF0A243F),
                        size: 30,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: AutoSizeText(
              tile.name,
              maxLines: 2,
              minFontSize: 8,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ),
        ],
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 13,
                childAspectRatio: 76 / 106,
              ),
              itemBuilder: (_, __) => Column(
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
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryTileData {
  const _CategoryTileData({
    required this.name,
    required this.categoryName,
    required this.categorySlug,
    required this.subCategorySlug,
    required this.imageUrl,
  });

  final String name;
  final String categoryName;
  final String categorySlug;
  final String subCategorySlug;
  final String imageUrl;
}
