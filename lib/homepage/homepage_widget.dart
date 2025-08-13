import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/components/whychoosemob.dart';
import 'package:m_o_b_demand_side/environment_values.dart';
import '../widgets/main_scaffold.dart';
import '../backend/api_requests/api_calls.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomepageWidget extends StatelessWidget {
  const HomepageWidget({super.key});
  static const String routeName = 'Homepage';
  static const String routePath = '/homepage';

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _locationHeader(),
            _searchBar(),
            _banner(),
            SizedBox(height: 16),
            _quickActions(),
            SizedBox(height: 16),
            _sectionTitle("Explore by categories"),
            _categoryGrid(context),
            _sectionTitle("Top brands for you"),
            _brandList(),
            _sectionTitle("Trending in your area"),
            _productCarousel(),
            _sectionTitle("Say no to water leak"),
            _productCarousel(),
            _mobStarPromo(),
            _sectionTitle("Built to last longer"),
            _productCarousel(),
            _sectionTitle("Walls that reflect you"),
            _productCarousel(),
            _infoCard(context),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _locationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.green),
          SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Iris Society",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                Text("D-102, Magarpatta, Hadapsar, Pune",
                    style: GoogleFonts.inter(fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search “Fevicol”",
          prefixIcon: Icon(Icons.search),
          fillColor: Color(0xFFF2F6F9),
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _banner() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            Image.asset('assets/banner_free_delivery.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionCard("Quote request", Icons.description),
          SizedBox(width: 12),
          _actionCard("Line of credit", Icons.credit_card),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF0A243F)),
            SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
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
      child: FutureBuilder<ApiCallResponse>(
        future: HomeDataCall.call(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?.jsonBody == null) {
            return Center(child: Text('Failed to load categories'));
          }
          final data = snapshot.data!.jsonBody; // <-- Use directly, no decode
          final categories = (data['data']?['categories'] as List?) ?? [];
          if (categories.isEmpty) {
            return Center(child: Text('No categories found'));
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, i) {
              final category = categories[i];
              final label = category['name'] ?? '';
              final imageUrl = category['image'] as String?;
              return _categoryItem(context, label, imageUrl);
            },
          );
        },
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String label, String? imageUrl) {
    return InkWell(
      onTap: () => GoRouter.of(context).go('/productlisting'),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF2F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            // padding: EdgeInsets.all(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    // width: 28,
                    // height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.category,
                        color: Color(0xFF0A243F),
                        size: 28),
                  )
                : Icon(Icons.category, color: Color(0xFF0A243F), size: 28),
          ),
          SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _brandList() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: brandLogos.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, i) {
          final brand = brandLogos[i];
          return Container(
            width: double.tryParse(brand['width'] ?? '80') ?? 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  brand['logo'] ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 6),
                Text(
                  brand['name'] ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _productCarousel() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, i) {
          return _productCard();
        },
      ),
    );
  }

  Widget _productCard() {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF1DC37A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text("30% OFF",
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              Spacer(),
              Icon(Icons.add_circle_outline, color: Color(0xFF0A243F)),
            ],
          ),
          SizedBox(height: 12),
          Text("Jaquar Sink Mixer",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text("₹2400",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text("Get by today evening",
              style: GoogleFonts.inter(fontSize: 10, color: Color(0xFF6C7C8C))),
        ],
      ),
    );
  }

  Widget _mobStarPromo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF3B5998),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("mob STAR",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              SizedBox(height: 8),
              Text("Get points on every order you place!",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
              SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF3B5998),
                ),
                onPressed: () {},
                child: Text("Shop now",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    const double cardHeight = 64;
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

Widget _productCarousel() {
  return SizedBox(
    height: 180,
    child: ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(width: 12),
      itemBuilder: (context, i) {
        return _productCard();
      },
    ),
  );
}

Widget _productCard() {
  return Container(
    width: 140,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Color(0xFFE0E0E0)),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFF1DC37A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text("30% OFF",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            Spacer(),
            Icon(Icons.add_circle_outline, color: Color(0xFF0A243F)),
          ],
        ),
        SizedBox(height: 12),
        Text("Jaquar Sink Mixer",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text("₹2400",
            style:
                GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 4),
        Text("Get by today evening",
            style: GoogleFonts.inter(fontSize: 10, color: Color(0xFF6C7C8C))),
      ],
    ),
  );
}

Widget _mobStarPromo() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFF3B5998),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("mob STAR",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            SizedBox(height: 8),
            Text("Get points on every order you place!",
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF3B5998),
              ),
              onPressed: () {},
              child: Text("Shop now",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _infoCard() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFFF2F6F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF0A243F)),
          SizedBox(width: 12),
          Expanded(
            child: Text("Why choose mad over buildings?",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.arrow_forward_ios, color: Color(0xFF0A243F), size: 16),
        ],
      ),
    ),
  );
}
