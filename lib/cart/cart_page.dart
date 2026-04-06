import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/checkout/checkout_address_page.dart';
import 'package:m_o_b_demand_side/conversational_ai/conversational_ai.dart';
import 'package:m_o_b_demand_side/features/cart/controllers/cart_controller.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/widgets/error_state_view.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';
import 'package:m_o_b_demand_side/loginpage/loginpage_widget.dart';

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
    _controller.loadCart();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      showLocationheader: false,
      showBackButton: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.errorMessage != null &&
                  _controller.errorMessage!.isNotEmpty &&
                  _controller.items.isEmpty) {
                return ErrorStateView(
                  title: 'Unable to load cart',
                  message: _controller.errorMessage!,
                  onRetry: () => _controller.loadCart(),
                );
              }
              if (_controller.requiresLogin) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          'Login to access your cart',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              context.go(LoginpageWidget.routePath),
                          child: const Text('Go to Login'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _controller.isEmpty
                  ? EmptyCartBody(
                      topBar: CartTopBar(),
                      shippingTile: ShippingTile(
                        title: _controller.shippingTitle,
                        subtitle: _controller.shippingSubtitle,
                      ),
                      micPill: const AiMicPill(),
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
              onQtyInputChanged: _controller.onQuantityInputChanged,
              onRemove: _controller.removeItem,
              isUpdatingCart: _controller.isUpdatingCart,
              updatingItemKey: _controller.updatingItemKey,
            ),
          ),
        )
        .toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Non-scrollable header: title + full-width gray divider
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: CartTopBar(),
            ),
            Container(height: 12, color: const Color(0xFFF1F1F2)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                children: [
                  ShippingTile(
                    title: _controller.shippingTitle,
                    subtitle: _controller.shippingSubtitle,
                  ),
                  SavingsStrip(
                    savings: _controller.savings,
                  ),
                  const SizedBox(height: 8),
                  if (_controller.hasRfqItems)
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Cart has ${_controller.rfqItemCount} RFQ item(s) without price. Proceed with checkout only for priced items.',
                        style: const TextStyle(
                          color: Color(0xFF8A3A00),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
            ),
          ],
        ),
        BottomCheckoutBar(
          total: _controller.total,
          onProceed: () =>
              GoRouter.of(context).go(CheckoutAddressPage.routePath),
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
