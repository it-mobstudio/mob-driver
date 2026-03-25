import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/components/why_choose_mob.dart';
import 'package:m_o_b_demand_side/environment_values.dart';
import 'package:m_o_b_demand_side/features/home/models/home_models.dart';
import 'package:m_o_b_demand_side/features/home/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/productlisting/product_listing_page.dart';
import '../widgets/main_scaffold.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/rfq/rfq_form_page.dart';

class HomepageWidget extends StatelessWidget {
  const HomepageWidget({super.key});
  static const String routeName = 'Homepage';
  static const String routePath = '/homepage';
  static const HomeRepository _homeRepository = HomeRepository();

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _banner(),
            const SizedBox(height: 24),
            _quickActions(context),
            const SizedBox(height: 24),
            _sectionTitle("Explore by categories"),
            _categoryGrid(context),
            const SizedBox(height: 24),
            _sectionTitle("Top brands for you"),
            _brandList(context),
            // _sectionTitle("Trending in your area"),
            // _productCarousel(),
            // _sectionTitle("Say no to water leak"),
            // _productCarousel(),
            // _mobStarPromo(),
            // _sectionTitle("Built to last longer"),
            // _productCarousel(),
            // _sectionTitle("Walls that reflect you"),
            // _productCarousel(),
            const SizedBox(height: 24),
            _infoCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            Image.asset('assets/images/PromotionBanner.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _actionCard(
              "Quote request",
              "Share your handwritten or typed quote",
              "assets/images/delivery_box.png",
              () {
                GoRouter.of(context).go(RfqFormPage.routePath);
              },
            ),
            const SizedBox(width: 12),
            _actionCard(
              "Line of credit",
              "Get credit upto 50 lakhs anywhere in India",
              "assets/images/3d-hands-holding.png",
              () {
                GoRouter.of(context).go(RfqFormPage.routePath);
              },
            ),
          ],
        ));
  }

  Widget _actionCard(
      String title, String subtitle, String imagePath, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            height: 163,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Stack(
                children: [
                  // Centered text
                  // Align(
                  //   alignment: Alignment.centerLeft,

                  //   child: Column(
                  //     mainAxisSize: MainAxisSize.min,
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         title,
                  //         textAlign: TextAlign.left,
                  //         style: GoogleFonts.inter(
                  //           fontWeight: FontWeight.w700,
                  //           fontSize: 15,
                  //         ),
                  //       ),
                  //       SizedBox(height: 6),

                  //       Text(
                  //         subtitle,
                  //         textAlign: TextAlign.left,
                  //         style: GoogleFonts.inter(
                  //           fontWeight: FontWeight.w400,
                  //           fontSize: 12,
                  //           color: Colors.black54,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16), // <-- Added padding here
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: const Color(0xFF0A243F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Icon/image at bottom right
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      imagePath,
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  Widget _categoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<HomeCategoryModel>>(
        future: _homeRepository.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load categories'));
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, i) {
              final category = categories[i];
              final label = category.name;
              final imageUrl = category.imageUrl;
              final slug = category.slug;
              return _categoryItem(context, label, imageUrl, slug);
            },
          );
        },
      ),
    );
  }

  Widget _categoryItem(
      BuildContext context, String label, String? imageUrl, String? slug) {
    return InkWell(
      onTap: () => GoRouter.of(context)
          .go(ProductListingPage.routePath, extra: {'category': label, 'slug': slug}),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            // padding: EdgeInsets.all(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    // width: 28,
                    // height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.category,
                        color: Color(0xFF0A243F),
                        size: 28),
                  )
                : const Icon(Icons.category, color: Color(0xFF0A243F), size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _brandList(BuildContext context) {
    const crossCount = 3;
    const gap = 16.0;
    const pagePad = 0.0;
    const minTile = 0.0;

    final w = MediaQuery.of(context).size.width;
    // final tile = (w - (pagePad * 2) - gap * (crossCount - 1)) / crossCount;
    final tile = ((w - (pagePad * 2) - gap * (crossCount - 1)) / crossCount)
        .clamp(minTile, double.infinity);
    final rows = (brandLogos.length / crossCount).ceil();
    final gridH = (rows * tile + (rows - 1) * gap);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: pagePad),
      child: SizedBox(
        height: gridH,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: 1, // square tiles
          ),
          itemCount: brandLogos.length,
          itemBuilder: (context, i) {
            final img = brandLogos[i]['logo'] ?? '';
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFFffffff),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.96,
                    heightFactor: 0.96,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child:
                          Image.asset(img, filterQuality: FilterQuality.high),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget _brandList() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: SizedBox(
  //       // let the grid decide the item height; no fixed 300 if you want it to grow
  //       child: GridView.builder(
  //         physics: const NeverScrollableScrollPhysics(),
  //         shrinkWrap: true,
  //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 3,
  //           mainAxisSpacing: 16,
  //           crossAxisSpacing: 16,
  //           childAspectRatio: 1, // square cards
  //         ),
  //         itemCount: brandLogos.length,
  //         itemBuilder: (context, i) {
  //           final brand = brandLogos[i];
  //           final String path = brand['logo'] ?? '';
  //           final bool isLogoOnly = (brand['isLogo'] == true) ||
  //               path.toLowerCase().contains('logo'); // simple heuristic

  //           return ClipRRect(
  //             borderRadius: BorderRadius.circular(12),
  //             child: ColoredBox(
  //               color: const Color(0xFFF4F7FB), // light bluish bg like the mock
  //               child: Stack(
  //                 fit: StackFit.expand,
  //                 children: [
  //                   // Image fills the entire tile; no AspectRatio wrapper.
  //                   Padding(
  //                     padding: const EdgeInsets.all(8),
  //                     child: isLogoOnly
  //                         // Logos: keep proportions but use up most of the tile.
  //                         ? FractionallySizedBox(
  //                             widthFactor: 0.9,
  //                             heightFactor: 0.9,
  //                             child: FittedBox(
  //                               fit: BoxFit.contain,
  //                               alignment: Alignment.center,
  //                               child: Image.asset(path),
  //                             ),
  //                           )
  //                         // Pack/product shots: fill the card (no empty gaps).
  //                         : FittedBox(
  //                             fit: BoxFit.cover,
  //                             alignment: Alignment.center,
  //                             child: Image.asset(path),
  //                           ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }


  Widget _infoCard(BuildContext context) {
    const double cardHeight = 76;
    const BorderRadius radius = BorderRadius.all(Radius.circular(18));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _showPromiseSheet(context),
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background image with rounded corners
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Image.asset(
                      'images/mobStar_bg.png', // gradient bg
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Content row
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(
                            width: 36), // spacing for the left-floating icon
                        Expanded(
                          child: Text(
                            'Why choose mad over\nbuildings?',
                            maxLines: 2,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right arrow in white circular chip
                        Container(
                          height: 36,
                          width: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'images/Arrow.svg',
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Left “badge/gear” icon peeking out of the card
                Positioned(
                  left: -8, // negative to let it stick out like the design
                  top: (cardHeight - 36) / 2,
                  child: SizedBox(
                    height: 36,
                    width: 36,
                    child: SvgPicture.asset('images/mobstar_Tick.svg'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPromiseSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (ctx) => const PromiseSheet(), // Use public PromiseSheet
    );
  }
}

