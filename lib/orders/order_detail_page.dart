import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';

part 'order_detail_bill_section.dart';
part 'order_detail_footer_section.dart';
part 'order_detail_header.dart';
part 'order_detail_info_section.dart';
part 'order_detail_shipments.dart';

class OrderDetailPage extends StatelessWidget {
  static const String routeName = 'OrderDetailPage';
  static const String routePath = '/order-detail';

  const OrderDetailPage({super.key});

  static const _items = [
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower, F160119',
      image: 'assets/images/Brands/hindware-seeklogo.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/Fevicol.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/Drfixit.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/Roff.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/greenply.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/century.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/kajaria.webp',
    ),
    _OrderItem(
      name: 'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower',
      image: 'assets/images/Brands/jaquar.webp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _OrderDetailHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShipmentSection(
                      index: 1,
                      title: 'Arriving in 5 mins',
                      icon: Icons.local_shipping_outlined,
                      iconBackground: const Color(0xFFDFF8F9),
                      items: _items.take(2).toList(),
                    ),
                    const _SectionGap(),
                    _ShipmentSection(
                      index: 2,
                      title: 'Arriving in 34 mins',
                      icon: Icons.local_shipping_outlined,
                      iconBackground: const Color(0xFFDFF8F9),
                      items: _items.skip(2).take(3).toList(),
                    ),
                    const _SectionGap(),
                    _ShipmentSection(
                      index: 3,
                      title: 'Packing your order',
                      icon: Icons.inventory_2_outlined,
                      iconBackground: const Color(0xFFFFF2C3),
                      items: _items.skip(5).take(3).toList(),
                    ),
                    const _SectionGap(),
                    const _RateItemsStrip(),
                    const _SectionGap(),
                    const _BillDetailsSection(),
                    const _SectionGap(),
                    const _OrderInfoSection(),
                    const _SectionGap(),
                    const _HelpTile(),
                    const _SectionGap(),
                    const _PromoFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    return Container(height: 12, color: const Color(0xFFF1F1F2));
  }
}

class _OrderItem {
  final String name;
  final String image;

  const _OrderItem({
    required this.name,
    required this.image,
  });
}
