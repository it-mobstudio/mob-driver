import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/main_scaffold.dart';

class CartPage extends StatefulWidget {
  static const String routeName = 'CartPage';
  static const String routePath = '/cart';

  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  CartAddressEntity? _selectedDeliveryAddress;
  CartAddressEntity? _selectedBillingAddress;
  bool _useDeliveryForBilling = false;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: -1,
      showTopSearchBar: false,
      showLocationheader: false,
      showBackButton: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: SafeArea(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              return switch (state) {
                CartInitial() || CartLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                CartError(:final message) => ErrorStateView(
                    title: 'Unable to load cart',
                    message: message,
                    onRetry: () =>
                        context.read<CartBloc>().add(CartLoadRequested()),
                  ),
                CartRequiresLogin() => Center(
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
                  ),
                CartLoaded(:final summary, :final updatingItemKey) =>
                  summary.isEmpty
                      ? EmptyCartBody(
                          topBar: const CartTopBar(),
                          shippingTile: ShippingTile(
                            title: _deliveryName(summary),
                            subtitle: _deliveryDetails(summary),
                            hasAddress: summary.hasDeliveryAddress,
                            onAddressAction: () =>
                                _showAddressBottomSheet(summary),
                          ),
                          micPill: const AiMicPill(),
                        )
                      : _buildCartWithItems(context, summary, updatingItemKey),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartWithItems(
    BuildContext context,
    CartSummaryEntity summary,
    String? updatingItemKey,
  ) {
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
                    title: _deliveryName(summary),
                    subtitle: _deliveryDetails(summary),
                    hasAddress: summary.hasDeliveryAddress,
                    onAddressAction: () => _showAddressBottomSheet(summary),
                  ),
                  const SizedBox(height: 12),
                  SameAddressRow(
                    value: _useDeliveryForBilling,
                    onChanged: (value) {
                      setState(() {
                        _useDeliveryForBilling = value;
                        if (value) {
                          _selectedBillingAddress =
                              _currentDeliveryAddress(summary);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  BillingAddressTile(
                    hasBillingAddress:
                        _billingDetails(summary).trim().isNotEmpty,
                    addressDetails: _billingDetails(summary),
                    onTap: () =>
                        _showAddressBottomSheet(summary, forBilling: true),
                  ),
                  const SizedBox(height: 20),
                  ...summary.itemsBySeller.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SellerSection(
                        sellerCode: entry.key,
                        sellerItems: entry.value,
                        isUpdatingCart: updatingItemKey != null,
                        updatingItemKey: updatingItemKey,
                        onQtyChanged: (item, qty) =>
                            context.read<CartBloc>().add(
                                  CartQuantityUpdateRequested(
                                      item: item, newQty: qty),
                                ),
                        onQtyInputChanged: (item, text) {
                          final qty = int.tryParse(text);
                          if (qty != null) {
                            context.read<CartBloc>().add(
                                  CartQuantityUpdateRequested(
                                      item: item, newQty: qty),
                                );
                          }
                        },
                        onRemove: (item) => context.read<CartBloc>().add(
                              CartItemRemoveRequested(item: item),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ViewCouponsTile(),
                  const SizedBox(height: 20),
                  OrderDetailsCard(
                    subtotal: summary.subtotal,
                    shipping: summary.shipping,
                    tax: summary.tax,
                    savings: summary.savings,
                    total: summary.total,
                    rewardPoints: summary.rewardPoints,
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

  String _deliveryName(CartSummaryEntity summary) {
    final selectedName = _selectedDeliveryAddress?.name.trim() ?? '';
    if (selectedName.isNotEmpty) return selectedName;
    final name = summary.shippingRecipientName.trim();
    if (name.isNotEmpty) return name;
    return summary.shippingTitle;
  }

  String _deliveryDetails(CartSummaryEntity summary) {
    final selected = _selectedDeliveryAddress;
    if (selected != null) return _addressDetails(selected);
    final parts = <String>[
      summary.shippingAddress.trim(),
      summary.shippingPhone.trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join('\n');
    return summary.shippingSubtitle;
  }

  String _billingDetails(CartSummaryEntity summary) {
    if (_useDeliveryForBilling) return _deliveryDetails(summary);
    final selected = _selectedBillingAddress;
    if (selected != null) return _addressDetails(selected);
    return summary.billingAddress.trim();
  }

  CartAddressEntity _currentDeliveryAddress(CartSummaryEntity summary) {
    return _selectedDeliveryAddress ??
        CartAddressEntity(
          name: _deliveryName(summary),
          address: summary.shippingAddress.trim(),
          phone: summary.shippingPhone.trim(),
          tag: 'Delivery',
        );
  }

  String _addressDetails(CartAddressEntity address) {
    return <String>[
      address.address.trim(),
      address.phone.trim(),
    ].where((p) => p.isNotEmpty).join('\n');
  }

  void _showAddressBottomSheet(
    CartSummaryEntity summary, {
    bool forBilling = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CartAddressBottomSheet(
          addresses: summary.savedAddresses,
          onSelectAddress: (CartAddressEntity address) {
            Navigator.of(sheetContext).pop();
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
            Navigator.of(sheetContext).pop();
            _openAddressFlow();
          },
        );
      },
    );
  }

  Future<void> _openAddressFlow() async {
    final savedAddress = await context.push(
      AddressSelectionWidget.routePath,
    );
    if (!mounted || savedAddress == null) return;
    context.read<CartBloc>().add(CartLoadRequested());
  }
}
