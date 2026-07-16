import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/home/data/models/home_models.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_listing_page.dart';

class HomeCategoryGrid extends StatelessWidget {
  const HomeCategoryGrid({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.hasError,
  });

  final List<HomeCategoryModel> categories;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 164,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('Failed to load categories'),
      );
    }
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No categories found'),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 13,
          childAspectRatio: 76 / 114,
        ),
        itemBuilder: (context, index) {
          return Center(
            child: HomeCategoryTile(category: categories[index]),
          );
        },
      ),
    );
  }
}

class HomeCategoryTile extends StatelessWidget {
  const HomeCategoryTile({super.key, required this.category});

  final HomeCategoryModel category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        AnalyticsService.instance.logCategoryOpened(
          category: category.name,
          slug: category.slug,
        );
        context.push(
          ProductListingPage.routePath,
          extra: {'category': category.name, 'slug': category.slug},
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
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
              child: category.imageUrl.isEmpty
                  ? const Icon(
                      Icons.category,
                      color: Color(0xFF0A243F),
                      size: 32,
                    )
                  : SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: category.imageUrl,
                        fit: BoxFit.contain,
                        memCacheWidth: 120,
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: Duration.zero,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.category,
                          color: Color(0xFF0A243F),
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          // Fixed height so image box is identical across all tiles
          SizedBox(
            height: 30,
            child: AutoSizeText(
              category.name,
              maxLines: 2,
              minFontSize: 8,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
