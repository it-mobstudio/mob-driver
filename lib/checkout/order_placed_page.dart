// lib/pages/order_placed_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';

class OrderPlacedPage extends StatelessWidget {
  static const routeName = 'OrderPlacedPage';
  static const routePath = '/checkout/success';

  const OrderPlacedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _topGreenBanner(context),
              const SizedBox(height: 12),
              _pointsCard(),
              const SizedBox(height: 16),
              _experienceCard(),
              const SizedBox(height: 16),
              _orderSummaryStrip(),
              const SizedBox(height: 12),
              _viewOrderBtn(),
              const SizedBox(height: 16),
              _nextSteps(),
              const SizedBox(height: 16),
              _referCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topGreenBanner(BuildContext c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Thank you! Your order has been placed',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(c),
          ),
        ],
      ),
    );
  }

  Widget _pointsCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('🪙  1150 points  on the way!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      );

  Widget _experienceCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('How was your experience?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                      5, (i) => const Icon(Icons.star, color: Colors.black87))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text('LOVED IT!!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () {}, child: const Text('Submit')),
          ],
        ),
      );

  Widget _orderSummaryStrip() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ID: MOB3567RUYFVYQC',
              style: GoogleFonts.inter(fontSize: 12)),
          const SizedBox(height: 6),
          Text('Arriving between 31 Jan - 6 Feb',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  border: Border.all(color: const Color(0xFFE8EEF5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chair_alt_outlined),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                border: Border.all(color: const Color(0xFFE8EEF5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('+5 more'),
            )
          ])
        ],
      );

  Widget _viewOrderBtn() => OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('View order details'),
      );

  Widget _nextSteps() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next steps',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _step('1',
              'Sorting your material to check\nassured quality requirement'),
          const SizedBox(height: 8),
          _step('2', 'Allocating vehicle for super fast\ndelivery'),
          const SizedBox(height: 8),
          _step('3', 'Product delivered at your\naddress'),
        ],
      );

  Widget _step(String num, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 16, child: Text(num)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter())),
        ],
      );

  Widget _referCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refer a friend and get ₹500 each',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'For every friend you refer, you get ₹500 and your friend gets ₹500 after their first order.',
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
                onPressed: () {}, child: const Text('Refer a friend')),
          ],
        ),
      );
}
