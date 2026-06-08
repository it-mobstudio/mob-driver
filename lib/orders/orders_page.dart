import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/orders/order_detail_page.dart';

class OrdersPage extends StatelessWidget {
  static const String routeName = 'OrdersPage';
  static const String routePath = '/orders';

  const OrdersPage({super.key});

  static const List<_OrderData> _orders = [
    _OrderData(
      amount: '\u20B91000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/Roff.webp',
        'assets/images/Brands/greenply.webp',
        'assets/images/Brands/century.webp',
      ],
    ),
    _OrderData(
      amount: '\u20B91000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/greenply.webp',
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/Roff.webp',
      ],
    ),
    _OrderData(
      amount: '\u20B91000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Roff.webp',
        'assets/images/Brands/Ultratech.webp',
        'assets/images/Brands/greenply.webp',
      ],
    ),
    _OrderData(
      amount: '\u20B91000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      project: 'Project: Hotel California',
      productImages: [
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/century.webp',
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/Ultratech.webp',
        'assets/images/Brands/Roff.webp',
      ],
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
            _OrdersHeader(onBack: () => _goBack(context)),
            Expanded(
              child: Container(
                color: const Color(0xFFF0F0F0),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const _OrdersSearch(),
                    const SizedBox(height: 12),
                    const _FilterButton(),
                    const SizedBox(height: 16),
                    ..._orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OrderCard(
                          order: order,
                          onTap: () => context.push(OrderDetailPage.routePath),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/myaccount');
    }
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 20,
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF0A243F),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'My orders',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 22 / 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersSearch extends StatelessWidget {
  const _OrdersSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF0A243F),
            size: 18,
          ),
          const SizedBox(width: 16),
          Text(
            'Search for orders',
            style: GoogleFonts.inter(
              color: const Color(0xFF596378),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDEDEDE)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune,
              color: Color(0xFF0A243F),
              size: 12,
            ),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final _OrderData order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _OrderHeader(order: order),
            ),
            const Divider(height: 1, color: Color(0xFFE5E8EE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 0, 16),
              child: _ProductStrip(images: order.productImages),
            ),
            _PointsBanner(points: order.points),
            if (order.project != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _ProjectPill(label: order.project!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E8EE)),
            const _OrderActions(),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final _OrderData order;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFCEFBE3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFF0BCB60),
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Order delivered',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 16,
                    color: const Color(0xFFD9D9D9),
                  ),
                  const SizedBox(width: 10),
                  SvgPicture.asset(
                    'assets/images/qwik.svg',
                    width: 54,
                    height: 14,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.amount} \u2022 ${order.dateTime}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF767C8F),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductStrip extends StatelessWidget {
  const _ProductStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _ProductThumb(asset: images[index]);
        },
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/Image-coming-soon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4CA), Color(0x00FFF4CA)],
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/points.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$points points',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(
                    text: ' will be added 7 days after delivery',
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectPill extends StatelessWidget {
  const _ProjectPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD911), Color(0x00FFD911)],
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0360E5),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                ),
              ),
              child: const Text('Repeat'),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0360E5),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 18 / 12,
                ),
              ),
              child: const Text('Rate order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderData {
  const _OrderData({
    required this.amount,
    required this.dateTime,
    required this.productImages,
    required this.points,
    this.project,
  });

  final String amount;
  final String dateTime;
  final List<String> productImages;
  final int points;
  final String? project;
}
