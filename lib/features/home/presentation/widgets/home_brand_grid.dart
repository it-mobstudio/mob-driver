import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/brand_product_search_page.dart';

class HomeBrandGrid extends StatelessWidget {
  const HomeBrandGrid({super.key});

  static const List<_HomeBrandItem> _brands = [
    _HomeBrandItem(
      name: 'Pidilite',
      titleImage: 'assets/images/Brands/Pidilitelogo.svg',
      productImage: 'assets/images/Brands/Fevicol.webp',
    ),
    _HomeBrandItem(
      name: 'UltraTech',
      titleImage: 'assets/images/Brands/Ultratechlogo.svg',
      productImage: 'assets/images/Brands/Ultratech.webp',
    ),
    _HomeBrandItem(
      name: 'Dr Fixit',
      titleImage: 'assets/images/Brands/Drfixitlogo.png',
      productImage: 'assets/images/Brands/Drfixit.webp',
    ),
    _HomeBrandItem(
      name: 'Birla Opus',
      titleImage: 'assets/images/Brands/Birla opus logo.svg',
      productImage: 'assets/images/Brands/opus.webp',
    ),
    _HomeBrandItem(
      name: 'CenturyPly',
      titleImage: 'assets/images/Brands/Centuryplylogo.svg',
      productImage: 'assets/images/Brands/century.webp',
    ),
    _HomeBrandItem(
      name: 'Roff',
      titleImage: 'assets/images/Brands/Rofflogo.png',
      productImage: 'assets/images/Brands/Roff.webp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _brands.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 104 / 160,
        ),
        itemBuilder: (context, index) {
          return HomeBrandTile(
            brand: _brands[index],
          );
        },
      ),
    );
  }
}

class HomeBrandTile extends StatelessWidget {
  const HomeBrandTile({
    super.key,
    required this.brand,
  });

  final _HomeBrandItem brand;

  bool isSvg(String path) {
    return path.toLowerCase().endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '${BrandProductSearchPage.routePath}/${brand.slug}?brand=${Uri.encodeComponent(brand.name)}',
        extra: <String, dynamic>{
          'brandName': brand.name,
        },
      ),
      child: Container(
        width: 104,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD1F6FF),
              Color(0xFFD1F6FF),
              Color(0xFF4DA8CC),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              height: 30,
              child: isSvg(brand.titleImage)
                  ? SvgPicture.asset(
                      brand.titleImage,
                      fit: BoxFit.contain,
                    )
                  : Image.asset(
                      brand.titleImage,
                      fit: BoxFit.contain,
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 112,
              child: isSvg(brand.productImage)
                  ? SvgPicture.asset(
                      brand.productImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    )
                  : Image.asset(
                      brand.productImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBrandItem {
  const _HomeBrandItem({
    required this.name,
    required this.titleImage,
    required this.productImage,
  });

  final String name;
  final String titleImage;
  final String productImage;

  String get slug => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
