import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/address_selection/address_selection_widget.dart';
import 'package:m_o_b_demand_side/checkout/checkout_order_review_page.dart';
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
  CartAddress? _selectedDeliveryAddress;
  CartAddress? _selectedBillingAddress;
  bool _useDeliveryForBilling = false;

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
      showTopSearchBar: false,
      showLocationheader: false,
      showBackButton: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
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
                      topBar: const CartTopBar(),
                      shippingTile: ShippingTile(
                        title: _deliveryName,
                        subtitle: _deliveryDetails,
                        hasAddress: _controller.hasDeliveryAddress,
                        onAddressAction: () => _showAddressBottomSheet(),
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
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CartTopBar(),
            Container(height: 16, color: const Color(0xFFF0F0F0)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
                children: [
                  ShippingTile(
                    title: _deliveryName,
                    subtitle: _deliveryDetails,
                    hasAddress: _controller.hasDeliveryAddress,
                    onAddressAction: () => _showAddressBottomSheet(),
                  ),
                  const SizedBox(height: 12),
                  SameAddressRow(
                    value: _useDeliveryForBilling,
                    onChanged: (value) {
                      setState(() {
                        _useDeliveryForBilling = value;
                        if (value) {
                          _selectedBillingAddress = _currentDeliveryAddress;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  BillingAddressTile(
                    hasBillingAddress: _billingDetails.trim().isNotEmpty,
                    addressDetails: _billingDetails,
                    onTap: () => _showAddressBottomSheet(forBilling: true),
                  ),
                  const SizedBox(height: 20),
                  const ViewCouponsTile(),
                  const SizedBox(height: 20),
                  OrderDetailsCard(
                    subtotal: _controller.subtotal,
                    shipping: _controller.shipping,
                    tax: _controller.tax,
                    savings: _controller.savings,
                    total: _controller.total,
                    rewardPoints: _controller.rewardPoints,
                  ),
                ],
              ),
            ),
          ],
        ),
        BottomCheckoutBar(
          onProceed: () =>
              GoRouter.of(context).go(CheckoutOrderReviewPage.routePath),
        ),
      ],
    );
  }

  String get _deliveryName {
    final selectedName = _selectedDeliveryAddress?.name.trim() ?? '';
    if (selectedName.isNotEmpty) {
      return selectedName;
    }
    final name = _controller.shippingRecipientName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return _controller.shippingTitle;
  }

  String get _deliveryDetails {
    final selectedAddress = _selectedDeliveryAddress;
    if (selectedAddress != null) {
      return _addressDetails(selectedAddress);
    }

    final parts = <String>[
      _controller.shippingAddress.trim(),
      _controller.shippingPhone.trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join('\n');
    }
    return _controller.shippingSubtitle;
  }

  String get _billingDetails {
    if (_useDeliveryForBilling) {
      return _deliveryDetails;
    }

    final selectedBilling = _selectedBillingAddress;
    if (selectedBilling != null) {
      return _addressDetails(selectedBilling);
    }

    return _controller.billingAddress.trim();
  }

  CartAddress get _currentDeliveryAddress {
    final selectedDelivery = _selectedDeliveryAddress;
    if (selectedDelivery != null) {
      return selectedDelivery;
    }

    return CartAddress(
      name: _deliveryName,
      address: _controller.shippingAddress.trim(),
      phone: _controller.shippingPhone.trim(),
      tag: 'Delivery',
    );
  }

  String _addressDetails(CartAddress address) {
    return <String>[
      address.address.trim(),
      address.phone.trim(),
    ].where((part) => part.isNotEmpty).join('\n');
  }

  void _showAddressBottomSheet({bool forBilling = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CartAddressBottomSheet(
          addresses: _controller.savedAddresses,
          onSelectAddress: (address) {
            Navigator.of(context).pop();
            setState(() {
              if (forBilling && !_useDeliveryForBilling) {
                _selectedBillingAddress = address;
              } else {
                _selectedDeliveryAddress = address;
                if (_useDeliveryForBilling || forBilling) {
                  _selectedBillingAddress = address;
                }
              }
            });
          },
          onAddAddress: () {
            Navigator.of(context).pop();
            this.context.go(AddressSelectionWidget.routePath);
          },
        );
      },
    );
  }

}
