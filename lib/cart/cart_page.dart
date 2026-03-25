import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/checkout/checkout_address_page.dart';
import 'package:m_o_b_demand_side/conversational_ai/conversational_ai.dart';
import 'package:m_o_b_demand_side/features/cart/controllers/cart_controller.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

class CartPage extends StatefulWidget {
  static const String routeName = 'CartPage';
  static const String routePath = '/cart';

  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CartController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _controller.isEmpty
                  ? const EmptyCartBody(
                      topBar: CartTopBar(),
                      shippingTile: ShippingTile(),
                      micPill: AiMicPill(),
                    )
                  : _buildCartWithItems(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartWithItems(BuildContext context) {
    final sellerSections = _controller.itemsBySeller.entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SellerSection(
              sellerCode: entry.key,
              sellerItems: entry.value,
              onQtyChanged: _controller.updateQuantity,
              onRemove: _controller.removeItem,
            ),
          ),
        )
        .toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          children: [
            const CartTopBar(),
            const ShippingTile(),
            const SavingsStrip(savings: CartController.savingsBannerAmount),
            const SizedBox(height: 8),
            ...sellerSections,
            const ViewCouponsTile(),
            const SizedBox(height: 12),
            OrderDetailsCard(
              subtotal: _controller.subtotal,
              shipping: _controller.shipping,
              tax: _controller.tax,
              savings: _controller.savings,
              total: _controller.total,
            ),
            const SizedBox(height: 12),
            const CartActionRow(),
            const SizedBox(height: 12),
          ],
        ),
        BottomCheckoutBar(
          total: _controller.total,
          onProceed: () => GoRouter.of(context).go(CheckoutAddressPage.routePath),
        ),
        Positioned(
          bottom: 80,
          right: 20,
          child: FloatingAiMic(onTap: () => _showAIBottomSheet(context)),
        ),
      ],
    );
  }

  void _showAIBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AzureConversationalAI(
        azureKey: 'YOUR_AZURE_KEY',
        azureRegion: 'YOUR_AZURE_REGION',
        locale: 'en-US',
      ),
    );
  }
}
