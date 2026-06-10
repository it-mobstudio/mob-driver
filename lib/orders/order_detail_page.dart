import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

class OrderDetailPage extends StatelessWidget {
  static const String routeName = 'OrderDetailPage';
  static const String routePath = '/order-detail';

  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      showLocationheader: false,
      showBackButton: true,
      headerBackgroundColor: const Color(0xFFE8F2EF),
      searchHintText: 'Search for product, category, brand..',
      child: _OrderDetailBody(),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  static const _placeholderImages = [
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F0F0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── White top section ──────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID
                  Text(
                    'Order ID: MOB9867855HJS6',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                      height: 22 / 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Placed on
                  Text(
                    'Placed on: 6 Feb 2022, 10:32am',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF67696D),
                      height: 18 / 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Download invoice
                  Row(
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        size: 16,
                        color: Color(0xFF0A243F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Download invoice',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 12px grey divider ──
            const SizedBox(height: 12),

            // ── Multi-shipment info banner ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'In multiple shipment scenarios, all your products will reach you as expected, however, the products might not be assigned accurately against the vehicles.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A243F),
                    height: 18 / 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Total items + product scroll ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total items: 8',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDEDEDE)),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'View all items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0A243F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _placeholderImages.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _placeholderImages[index],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1F2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Shipment cards ──
            _ShipmentCard(
              shipmentNumber: 'Shipment 1',
              subId: 'MOB9867855HJS6',
              soldBy: 'Sold by Backyard Decor',
              status: ShipmentCardStatus.outForDelivery,
              statusText: 'Out for delivery',
              statusSubText: 'Arrives today by 8pm',
              progressStep: 3,
              showRateItems: false,
              actionButton: const _CancelButton(show: false),
            ),

            const SizedBox(height: 12),

            _ShipmentCard(
              shipmentNumber: 'Shipment 2',
              subId: 'MOB9867855HJS6',
              soldBy: 'Sold by Backyard Decor',
              status: ShipmentCardStatus.processing,
              statusText: 'Sorting best quality products',
              statusSubText: 'Arrives today by 8pm',
              progressStep: 2,
              showRateItems: false,
              actionButton: const _CancelButton(show: true),
            ),

            const SizedBox(height: 12),

            _ShipmentCard(
              shipmentNumber: 'Shipment 3',
              subId: 'MOB9867855HJS6',
              soldBy: 'Sold by Backyard Decor',
              status: ShipmentCardStatus.delivered,
              statusText: 'Delivered',
              statusSubText: 'on 1st Nov at 2:30pm',
              progressStep: 4,
              showRateItems: true,
              actionButton: const _ReturnExchangeButton(),
            ),

            const SizedBox(height: 12),

            // ── Delivery address ──
            _AddressCard(
              label: 'Delivery address:',
              name: 'Carlos Sainz',
              address:
                  '10 Downing Street, 4th Floor, Infront of westend mall, Chennai, 600005',
              phone: '+91 9876554324',
              gstNo: null,
            ),

            const SizedBox(height: 12),

            // ── Billing address ──
            _AddressCard(
              label: 'Billing address:',
              name: 'Carlos Sainz',
              address:
                  '10 Downing Street, 4th floor, Infront of westend mall, Chennai, 600005',
              phone: '+91 9876554324',
              gstNo: '18AABCU9603R1ZM',
            ),

            const SizedBox(height: 12),

            // ── Order details + earn points ──
            _OrderDetailsCard(),

            const SizedBox(height: 12),

            // ── Payment method ──
            _PaymentMethodCard(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Shipment status enum
// ──────────────────────────────────────────────
enum ShipmentCardStatus { outForDelivery, processing, delivered }

// ──────────────────────────────────────────────
// Shipment card
// ──────────────────────────────────────────────
class _ShipmentCard extends StatelessWidget {
  final String shipmentNumber;
  final String subId;
  final String soldBy;
  final ShipmentCardStatus status;
  final String statusText;
  final String statusSubText;
  final int progressStep; // 1-4
  final bool showRateItems;
  final Widget actionButton;

  static const _placeholderImages = [
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
    'https://via.placeholder.com/48',
  ];

  const _ShipmentCard({
    required this.shipmentNumber,
    required this.subId,
    required this.soldBy,
    required this.status,
    required this.statusText,
    required this.statusSubText,
    required this.progressStep,
    required this.showRateItems,
    required this.actionButton,
  });

  Color get _statusColor {
    if (status == ShipmentCardStatus.outForDelivery) {
      return const Color(0xFF01A685);
    }
    return const Color(0xFF0A243F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Shipment header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shipmentNumber,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                Text(
                  'Invoice',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2973F0),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Sub ID: $subId',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF67696D),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              soldBy,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF67696D),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Status row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                          height: 22 / 15,
                        ),
                      ),
                      if (statusSubText.isNotEmpty)
                        Text(
                          statusSubText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF0A243F),
                          ),
                        ),
                    ],
                  ),
                ),
                actionButton,
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Progress tracker ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ShipmentProgressBar(activeStep: progressStep),
          ),

          const SizedBox(height: 16),

          // ── Divider ──
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFD0D4DC)),

          // ── Items row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '2 items',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Color(0xFF0A243F),
                ),
              ],
            ),
          ),

          // ── Product images ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: _placeholderImages
                  .map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ── Rate items (delivered only) ──
          if (showRateItems) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFFDEDEDE), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'RATE ITEMS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A243F),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'get',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6C7C8C),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            '5',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0A243F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Divider ──
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFD0D4DC)),

          // ── View all details ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all details',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFF0A243F)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Shipment progress bar (4 steps)
// ──────────────────────────────────────────────
class _ShipmentProgressBar extends StatelessWidget {
  final int activeStep; // 1-4

  const _ShipmentProgressBar({required this.activeStep});

  static const _icons = [
    Icons.receipt_long_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.local_shipping_rounded,
    Icons.inventory_2_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final stepIndex = i + 1;
        final isActive = stepIndex <= activeStep;
        return Expanded(
          child: Row(
            children: [
              _StepCircle(icon: _icons[i], isActive: isActive),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 4,
                    color: stepIndex < activeStep
                        ? const Color(0xFF0A243F)
                        : const Color(0xFFDEDEDE),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _StepCircle({required this.icon, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0A243F) : const Color(0xFFDEDEDE),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Cancel button (Shipment 2 action)
// ──────────────────────────────────────────────
class _CancelButton extends StatelessWidget {
  final bool show;
  const _CancelButton({required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFF0A243F)),
          const SizedBox(width: 4),
          Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Return / Exchange button (Shipment 3 action)
// ──────────────────────────────────────────────
class _ReturnExchangeButton extends StatelessWidget {
  const _ReturnExchangeButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0A243F)),
          const SizedBox(width: 4),
          Text(
            'Return/ Exchange',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Address card
// ──────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final String label;
  final String name;
  final String address;
  final String phone;
  final String? gstNo;

  const _AddressCard({
    required this.label,
    required this.name,
    required this.address,
    required this.phone,
    required this.gstNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A243F),
                height: 20 / 14,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(color: Color(0xFF67696D)),
                ),
                TextSpan(text: name),
              ],
            ),
          ),
          if (gstNo != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF133B62),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'GST NO: $gstNo',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 16 / 11,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            address,
            style: GoogleFonts.inter(
              fontSize: gstNo != null ? 11 : 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF67696D),
              height: gstNo != null ? 16 / 11 : 18 / 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            phone,
            style: GoogleFonts.inter(
              fontSize: gstNo != null ? 11 : 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF67696D),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Order details card
// ──────────────────────────────────────────────
class _OrderDetailsCard extends StatelessWidget {
  static const _rows = [
    ('Subtotal', '₹ 26567.00'),
    ('Shipping', '₹ 500.00'),
    ('Total tax', '₹ 433.00'),
    ('Savings', '₹ 1055.00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Order details',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A243F),
              ),
            ),
          ),
          ..._rows.map(
            (row) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row.$1,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF67696D),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0A243F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16, thickness: 0.5, color: Color(0xFFD0D4DC)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                Text(
                  '₹ 26567.00',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Earn points banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFDFF8F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC107), size: 16),
                const SizedBox(width: 6),
                Text(
                  'You\'ll earn 1150 points on this purchase',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Payment method card
// ──────────────────────────────────────────────
class _PaymentMethodCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F71),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'VISA',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Visa card ending 9507',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF67696D),
            ),
          ),
        ],
      ),
    );
  }
}
