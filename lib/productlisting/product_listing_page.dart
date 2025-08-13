import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/RFQ/RfqFormPage.dart';
import '../widgets/main_scaffold.dart';
import 'filter_bottom_sheet.dart';
import 'package:go_router/go_router.dart';

class ProductListingPage extends StatelessWidget {
  final String category;
  static const String routeName = '/ProductListingPage';
  static const String routePath = '/productlisting';

  const ProductListingPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final List<String> subcategories = [
      "Garden furniture sets",
      "Lounge furniture",
      "Balcony furniture",
      "Garden tables"
    ];

    final List<Map<String, dynamic>> products = List.generate(8, (index) {
      return {
        'name':
            'Neoseal P-38 Primer - Industrial Grade - clear colour, low VOC - size 237ml',
        'price': '₹2400',
        'oldPrice': '₹3400',
        'discount': '30% OFF',
        'rating': 4.4,
        'delivery': 'Get by today evening',
        'qty': index % 3 == 0 ? 1 : 0, // Some pre-selected quantity
        'image': 'assets/sample_product.png', // Placeholder image
      };
    });

    return MainScaffold(
      currentIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBar(),
          _subCategoryList(subcategories),
          _filterRow(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (products.length / 2).ceil() + 1, // +1 for bottom card
              itemBuilder: (context, index) {
                if (index == (products.length / 2).ceil()) {
                  return _bottomCard(context);
                }
                int i = index * 2;
                return Row(
                  children: [
                    Expanded(child: _productCard(products[i], context)),
                    const SizedBox(width: 12),
                    if (i + 1 < products.length)
                      Expanded(child: _productCard(products[i + 1], context))
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

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for product, category, brand...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.mic),
          fillColor: const Color(0xFFF2F6F9),
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _subCategoryList(List<String> subs) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chair_outlined, size: 28),
              ),
              const SizedBox(height: 6),
              Text(subs[index],
                  style: GoogleFonts.inter(fontSize: 11),
                  textAlign: TextAlign.center)
            ],
          );
        },
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

  Widget _productCard(Map<String, dynamic> product, BuildContext context) {
    final bool hasQty = product['qty'] > 0;

    return GestureDetector(
      onTap: () {
        GoRouter.of(context).go('/ProductDetailPage');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DC37A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(product['discount'],
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(product['rating'].toString(),
                          style: GoogleFonts.inter(
                              fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                product['image'],
                height: 70,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(product['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(product['price'],
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(width: 6),
                Text(product['oldPrice'],
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flash_on, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(product['delivery'],
                    style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFF6C7C8C))),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: hasQty
                  ? Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A243F),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.remove, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text("1", style: TextStyle(color: Colors.white)),
                          SizedBox(width: 10),
                          Icon(Icons.add, color: Colors.white, size: 18),
                        ],
                      ),
                    )
                  : const Icon(Icons.add_circle_outline,
                      color: Color(0xFF0A243F), size: 24),
            )
          ],
        ),
      ),
    );
  }

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
