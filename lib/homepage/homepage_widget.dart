import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/main_scaffold.dart';

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
            _infoCard(),
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
    final categories = [
      "Sustainable",
      "Building material",
      "Bathroom & plumbing",
      "Hardware",
      "Living & decor",
      "Paints & wallpapers",
      "Electric & lights",
      "Tools & machines",
      "Kitchen",
      "Doors & windows",
      "Flooring",
      "Heating & cooling",
      "Tiles",
      "Cleaning",
      "Garden",
      "Automotive",
    ];
    final icons = [
      Icons.eco,
      Icons.apartment,
      Icons.shower,
      Icons.build,
      Icons.chair,
      Icons.format_paint,
      Icons.lightbulb,
      Icons.construction,
      Icons.kitchen,
      Icons.door_front_door,
      Icons.layers,
      Icons.ac_unit,
      Icons.grid_on,
      Icons.cleaning_services,
      Icons.grass,
      Icons.directions_car,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
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
          return _categoryItem(context, categories[i], icons[i]);
        },
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String label, IconData icon) {
    return InkWell(
      onTap: () => GoRouter.of(context).go('/productlisting'),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF2F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Color(0xFF0A243F), size: 28),
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
    final brands = [
      "Fixit",
      "Pidilite",
      "Ultratech",
      "Kajaria",
      "Bosch",
      "Jaquar"
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: brands.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, i) {
          return Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(brands[i],
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF3B5998),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
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
}
