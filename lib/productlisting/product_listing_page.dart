import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/RFQ/RfqFormPage.dart';
import '../widgets/main_scaffold.dart';
import 'filter_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import '../components/product_card.dart';
import '../backend/api_requests/api_calls.dart';

class ProductListingPage extends StatefulWidget {
  final String category;
  final String slug;
  static const String routeName = '/ProductListingPage';
  static const String routePath = '/productlisting';

  const ProductListingPage(
      {super.key, required this.category, required this.slug});

  @override
  State<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends State<ProductListingPage> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _products = [];
  List<dynamic> _subCategories = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await BrowseProductsCall.call(
          categoryName: widget.slug, page: _currentPage);
      final json = response.jsonBody;
      final data = json['data'] ?? {};
      final List<dynamic> newProducts = data['results'] ?? [];
      final pagination = data['pagination'] ?? {};
      final subCategories = data['sub_categories'] ?? [];
      setState(() {
        _products.addAll(newProducts);
        _subCategories = subCategories;
        _hasMore = pagination['is_next_page'] == true;
        if (_hasMore)
          _currentPage = pagination['next_page'] ?? _currentPage + 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category.isEmpty) {
      return MainScaffold(
        currentIndex: 0,
        child: const Center(child: Text('No category selected.')),
      );
    }

    // Use sub_categories from API
    return MainScaffold(
      currentIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _subCategoryList(_subCategories),
          _filterRow(context),
          Expanded(
            child: _error != null
                ? Center(child: Text('Error: $_error'))
                : _products.isEmpty && _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: (_products.length / 2).ceil() +
                            (_hasMore
                                ? 2
                                : 1), // +1 for bottom card, +1 for loader if hasMore
                        itemBuilder: (context, index) {
                          if (_hasMore &&
                              index == (_products.length / 2).ceil()) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ));
                          }
                          if (index ==
                              (_products.length / 2).ceil() +
                                  (_hasMore ? 1 : 0)) {
                            return _bottomCard(context);
                          }
                          int i = index * 2;
                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: ProductCard(
                                  product: _products[i] as Map<String, dynamic>,
                                  onTap: () {
                                    final slug = (_products[i]
                                            as Map<String, dynamic>)['slug'] ??
                                        '';
                                    GoRouter.of(context)
                                        .go('/ProductDetailPage/$slug');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (i + 1 < _products.length)
                                Expanded(
                                  child: ProductCard(
                                    product: _products[i + 1]
                                        as Map<String, dynamic>,
                                    onTap: () {
                                      final slug = (_products[i + 1] as Map<
                                              String, dynamic>)['slug'] ??
                                          '';
                                      GoRouter.of(context)
                                          .go('/ProductDetailPage/$slug');
                                    },
                                  ),
                                )
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _subCategoryList(List<dynamic> subs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final sub = subs[index];
            final name = sub['sub_category_name'];
            final image = sub['image'];
            return Column(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: (image != null && image.toString().isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(image, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.chair_outlined, size: 28),
                ),
                const SizedBox(height: 6),
                Text(name,
                    style: GoogleFonts.inter(fontSize: 11),
                    textAlign: TextAlign.center)
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _filterChip("Filter", Icons.tune, onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => const FilterBottomSheet(),
            );
          }),
          _filterChip("Sort by", Icons.swap_vert),
          _filterChip("Same day delivery", Icons.flash_on),
        ],
      ),
    );
  }

  Widget _filterChip(String label, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F6F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0A243F)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // Widget _productCard(Map<String, dynamic> product, BuildContext context) {
  //   // Map API fields to UI fields
  //   final vendorPricing = product['vendorPricings'] ?? {};
  //   final name = product['item_name_title'] ?? '';
  //   final price = vendorPricing['vendor_selling_price'] ?? 0;
  //   final oldPrice = product['maximum_retail_price'] ?? 0;
  //   final priceStr = double.tryParse(price.toString())?.toStringAsFixed(2) ??
  //       price.toString();
  //   final oldPriceStr =
  //       double.tryParse(oldPrice.toString())?.toStringAsFixed(2) ??
  //           oldPrice.toString();
  //   final discount = vendorPricing['discount'] ?? 0;
  //   final delivery = vendorPricing['fullfillment_latency'] ?? '';
  //   final imageUrl = (product['images'] != null && product['images'].isNotEmpty)
  //       ? product['images'][0]['image']
  //       : null;

  //   return GestureDetector(
  //     onTap: () {
  //       GoRouter.of(context).go('/ProductDetailPage');
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         border: Border.all(color: const Color(0xFFE0E0E0)),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Container(
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF1DC37A),
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //                 child: Text(
  //                     discount != null && discount != 0
  //                         ? '${discount}% OFF'
  //                         : '',
  //                     style: GoogleFonts.inter(
  //                         color: Colors.white,
  //                         fontSize: 10,
  //                         fontWeight: FontWeight.bold)),
  //               ),
  //               const Spacer(),
  //               // No rating in API, so skip rating UI
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           Center(
  //             child: imageUrl != null && imageUrl.isNotEmpty
  //                 ? Image.network(imageUrl, height: 70, fit: BoxFit.contain)
  //                 : Image.asset('assets/images/Image-coming-soon.png',
  //                     height: 70, fit: BoxFit.contain),
  //           ),
  //           const SizedBox(height: 12),
  //           Text(name,
  //               maxLines: 2,
  //               overflow: TextOverflow.ellipsis,
  //               style: GoogleFonts.inter(
  //                   fontWeight: FontWeight.w600, fontSize: 13)),
  //           const SizedBox(height: 6),
  //           Row(
  //             children: [
  //               Text('₹$priceStr',
  //                   style: GoogleFonts.inter(
  //                       fontWeight: FontWeight.bold, fontSize: 15)),
  //               const SizedBox(width: 6),
  //               if (oldPrice != null && oldPrice != 0)
  //                 Text('₹$oldPriceStr',
  //                     style: GoogleFonts.inter(
  //                         fontSize: 12,
  //                         color: Colors.grey,
  //                         decoration: TextDecoration.lineThrough)),
  //             ],
  //           ),
  //           const SizedBox(height: 4),
  //           Row(
  //             children: [
  //               const Icon(Icons.flash_on, size: 12, color: Colors.amber),
  //               const SizedBox(width: 4),
  //               Text(delivery,
  //                   style: GoogleFonts.inter(
  //                       fontSize: 10, color: const Color(0xFF6C7C8C))),
  //             ],
  //           ),
  //           const SizedBox(height: 10),
  //           Center(
  //             child: const Icon(Icons.add_circle_outline,
  //                 color: Color(0xFF0A243F), size: 24),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _bottomCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 32, color: Color(0xFFFA6332)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Can’t find a product?",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text("Suggest the item you want and we will try to add it.",
                    style: GoogleFonts.inter(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA6332),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              GoRouter.of(context).go(RfqFormPage.routePath);
            },
            child: Text("Send a request",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
