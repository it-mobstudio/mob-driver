import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';

class ProductDetailPage extends StatelessWidget {
  static const String routeName = '/ProductDetailPage';
  static const String routePath = '/ProductDetailPage';
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _topHeader(context),
              const SizedBox(height: 16),
              _productImagesCarousel(),
              const SizedBox(height: 16),
              _productInfoBlock(),
              const SizedBox(height: 16),
              _flowRateSelector(),
              const SizedBox(height: 16),
              _colorSelector(),
              const SizedBox(height: 16),
              _deliveryInfoCard(),
              const SizedBox(height: 16),
              _keyFeatures(),
              const SizedBox(height: 16),
              _productDetailsTable(),
              const SizedBox(height: 16),
              _specifications(),
              const SizedBox(height: 16),
              _reviewsSection(),
              const SizedBox(height: 16),
              _similarItemsPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
      ],
    );
  }

  Widget _productImagesCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (_, index) => Image.asset("assets/sample_product.png"),
      ),
    );
  }

  Widget _productInfoBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Kohler Statement™ Oblong 3-function Showerhead, 9.5 lpm",
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text("₹6000",
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(width: 8),
            Text("₹7500",
                style: GoogleFonts.inter(
                    decoration: TextDecoration.lineThrough,
                    fontSize: 14,
                    color: Colors.grey)),
            const SizedBox(width: 8),
            Text("20% OFF",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text("4.4 (21 reviews)", style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _flowRateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Flow rate",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            _selectorPill("8 lpm", isSelected: false),
            const SizedBox(width: 8),
            _selectorPill("9.5 lpm", isSelected: true),
            const SizedBox(width: 8),
            _selectorPill("12 lpm", isSelected: false),
          ],
        ),
      ],
    );
  }

  Widget _selectorPill(String text, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0A243F) : const Color(0xFFF2F6F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _colorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Color", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            _colorBox("Vibrant French Gold", Colors.amber),
            const SizedBox(width: 12),
            _colorBox("Polished Chrome", Colors.grey),
            const SizedBox(width: 12),
            _colorBox("Vibrant Rose Gold", Colors.pink),
          ],
        ),
      ],
    );
  }

  Widget _colorBox(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 14, backgroundColor: color),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.inter(fontSize: 10), textAlign: TextAlign.center)
      ],
    );
  }

  Widget _deliveryInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFEEF7E9),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Text("Will be delivered before tomorrow evening",
              style: GoogleFonts.inter(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _keyFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Key Features",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
            "Relax in a shower that fully soaks, restores, and targets sore muscles—all at the touch of a button...",
            style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }

  Widget _productDetailsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Product Details",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: [
            _tableRow("Type", "Multifunction showerhead"),
            _tableRow("Finish", "Polished Chrome"),
            _tableRow("Brand", "Kohler"),
            _tableRow("Material", "Wood"),
            _tableRow("Color", "Polished Chrome"),
          ],
        )
      ],
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(value,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _specifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Specifications",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
            "• Multifunction showerhead with advanced spray engine...\n• Deep massage streams...",
            style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }

  Widget _reviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("21 Reviews",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _reviewTile(
            "Satish Kumar", "13 Dec 2024", 4.4, "Durable build quality..."),
        _reviewTile("Neh Bhandari", "11 Dec 2024", 4.3,
            "Love the adjustable settings..."),
      ],
    );
  }

  Widget _reviewTile(String name, String date, double rating, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(rating.toString(),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 12)),
            const SizedBox(width: 8),
            Text(name, style: GoogleFonts.inter(fontSize: 12)),
            const Spacer(),
            Text(date,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text(comment, style: GoogleFonts.inter(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _similarItemsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("View similar items",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          height: 150,
          color: Colors.grey.shade200,
          child: const Center(child: Text("Product carousel placeholder")),
        )
      ],
    );
  }
}
