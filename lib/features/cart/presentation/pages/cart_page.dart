import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/nav/nav.dart' show appNavigatorKey;
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/add_address_detail_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_address_page.dart';
import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/loginpage_widget.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/features/home/domain/store_delivery_label.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

class CartPage extends StatefulWidget {
  static const String routeName = 'CartPage';
  static const String routePath = '/cart';

  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  AddressEntity? _selectedDeliveryAddress;
  AddressEntity? _storedAddress;
  List<AddressEntity> _savedAddresses = const [];
  String _deliveryLabel = '';
  bool _isStoreOpen = true;

  @override
  void initState() {
    super.initState();
    _loadStoredAddress();
    _loadSavedAddresses();
    _loadStoreDeliveryLabel();
  }

  Future<void> _loadStoreDeliveryLabel() async {
    final (status, failure) = await sl<HomeRepository>().getStoreOpenStatus();
    if (!mounted || failure != null) return;
    setState(() {
      _deliveryLabel = storeDeliveryLabel(status);
      _isStoreOpen = status?.isOpen ?? true;
    });
  }

  Future<void> _loadStoredAddress() async {
    final stored = await SelectedAddressStore.read();
    if (!mounted) return;
    if (stored != null) {
      setState(() => _storedAddress = stored);
      return;
    }
    final (addresses, failure) = await sl<AddressRepository>().getAddresses();
    if (!mounted || failure != null || addresses == null || addresses.isEmpty) {
      return;
    }
    final first = addresses.first;
    await SelectedAddressStore.save(first);
    if (!mounted) return;
    setState(() => _storedAddress = first);
  }

  Future<void> _loadSavedAddresses() async {
    final (addresses, failure) = await sl<AddressRepository>().getAddresses();
    if (!mounted || failure != null || addresses == null) return;
    setState(() => _savedAddresses = addresses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        // Surface failed cart updates once, then clear so they don't reappear
        // on the next unrelated rebuild.
        child: BlocListener<CartBloc, CartState>(
          listenWhen: (previous, current) {
            if (current is! CartLoaded) return false;
            final prevError =
                previous is CartLoaded ? previous.actionError : null;
            return current.actionError != prevError;
          },
          listener: (context, state) {
            if (state is! CartLoaded) return;
            if (state.actionError != null) {
              TopSnackBar.show(
                context,
                message: state.actionError!,
                type: TopSnackBarType.error,
              );
              context.read<CartBloc>().add(CartActionErrorCleared());
            }
          },
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
                            hasAddress: _hasDeliveryAddress(summary),
                            onAddressAction: () =>
                                _showAddressBottomSheet(summary),
                          ),
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
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF0F0F0),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 112),
                  children: [
                    ShippingTile(
                      title: _deliveryName(summary),
                      subtitle: _deliveryDetails(summary),
                      hasAddress: _hasDeliveryAddress(summary),
                      onAddressAction: () => _showAddressBottomSheet(summary),
                    ),
                    if (summary.savings > 0) ...[
                      const SizedBox(height: 8),
                      SavingsStrip(savings: summary.savings),
                    ],
                    const SizedBox(height: 20),
                    for (final indexed
                        in summary.itemsBySeller.entries.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SellerSection(
                          sellerCode: indexed.$2.key,
                          sellerItems: indexed.$2.value,
                          itemStartIndex: summary.itemsBySeller.entries
                              .take(indexed.$1)
                              .fold<int>(0, (sum, e) => sum + e.value.length),
                          deliveryLabel: _deliveryLabel,
                          isStoreOpen: _isStoreOpen,
                          isUpdatingCart: updatingItemKey != null,
                          updatingItemKey: updatingItemKey,
                          onQtyChanged: (item, qty) =>
                              _updateCartQuantity(context, item, qty),
                          onQtyInputChanged: (item, text) {
                            final qty = int.tryParse(text.trim()) ?? 0;
                            _updateCartQuantity(context, item, qty);
                          },
                          onRemove: (item) => context.read<CartBloc>().add(
                                CartItemRemoveRequested(item: item),
                              ),
                        ),
                      ),
                    // const ViewCouponsTile(),
                    // const SizedBox(height: 8),
                    OrderDetailsCard(
                      subtotal: summary.subtotal,
                      shipping: summary.shipping,
                      tax: summary.tax,
                      savings: summary.savings,
                      total: _effectiveTotal(summary),
                      earningPoints: summary.earningPoints,
                    ),
                    const SizedBox(height: 20),
                    CartActionRow(summary: summary),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        BottomCheckoutBar(
          label: 'Place order',
          total: _effectiveTotal(summary),
          onProceed: () =>
              GoRouter.of(context).push(CheckoutAddressPage.routePath),
        ),
      ],
    );
  }

  // Web shows sub_cart_total + shipping for logged-in users; API total is often 0.
  double _effectiveTotal(CartSummaryEntity summary) {
    if (summary.total > 0) return summary.total;
    return summary.subtotal + summary.shipping;
  }

  void _updateCartQuantity(BuildContext context, CartItem item, int quantity) {
    final stock = item.availableStock;
    var nextQuantity = quantity;
    if (stock > 0 && quantity > stock) {
      nextQuantity = stock;
      TopSnackBar.show(
        context,
        message: 'Only $stock units available. Quantity updated to $stock.',
        type: TopSnackBarType.info,
      );
    }
    context.read<CartBloc>().add(
          CartQuantityUpdateRequested(item: item, newQty: nextQuantity),
        );
  }

  bool _hasDeliveryAddress(CartSummaryEntity summary) {
    return _selectedDeliveryAddress != null ||
        _storedAddress != null ||
        summary.hasDeliveryAddress;
  }

  String _deliveryName(CartSummaryEntity summary) {
    final selectedName = _selectedDeliveryAddress?.name.trim() ?? '';
    if (selectedName.isNotEmpty) return selectedName;
    final storedName = _storedAddress?.name.trim() ?? '';
    if (storedName.isNotEmpty) return storedName;
    final name = summary.shippingRecipientName.trim();
    if (name.isNotEmpty) return name;
    return summary.shippingTitle;
  }

  String _deliveryDetails(CartSummaryEntity summary) {
    final selected = _selectedDeliveryAddress ?? _storedAddress;
    if (selected != null) {
      final addressText = <String>[
        selected.addressLine1,
        selected.addressLine2,
        selected.sublocality,
        selected.city,
        selected.pincode,
      ].where((p) => p.trim().isNotEmpty).join(', ');
      final displayAddress = addressText.isNotEmpty
          ? addressText
          : selected.formattedAddress.trim();
      return <String>[
        displayAddress,
        selected.phoneNumber.trim(),
      ].where((p) => p.isNotEmpty).join('\n');
    }
    final parts = <String>[
      summary.shippingAddress.trim(),
      summary.shippingPhone.trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join('\n');
    return summary.shippingSubtitle;
  }

  void _showAddressBottomSheet(CartSummaryEntity summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // StatefulBuilder so edit/delete can refresh the list in place
        // without closing this sheet — _savedAddresses lives on the page's
        // State, and a bottom-sheet route isn't rebuilt by the page's own
        // setState, so it needs its own rebuild trigger.
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CartAddressBottomSheet(
              addresses: _savedAddresses,
              selectedAddressId:
                  (_selectedDeliveryAddress ?? _storedAddress)?.id,
              onSelectAddress: (address) {
                Navigator.of(sheetContext).pop();
                _selectAddress(address);
              },
              onAddAddress: () {
                Navigator.of(sheetContext).pop();
                _openAddressFlow();
              },
              onEditAddress: (address) async {
                await _editAddress(address);
                if (sheetContext.mounted) setSheetState(() {});
              },
              onDeleteAddress: (address) async {
                await _confirmDeleteAddress(address);
                if (sheetContext.mounted) setSheetState(() {});
              },
            );
          },
        );
      },
    );
  }

  Future<void> _editAddress(AddressEntity existing) async {
    final updated = await context.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: existing,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _savedAddresses = [
        for (final address in _savedAddresses)
          if (address.id == updated.id) updated else address,
      ];
      if (_selectedDeliveryAddress?.id == updated.id) {
        _selectedDeliveryAddress = updated;
      }
    });
    if (_storedAddress?.id == updated.id) {
      await SelectedAddressStore.save(updated);
      if (!mounted) return;
      setState(() => _storedAddress = updated);
    }
  }

  Future<void> _confirmDeleteAddress(AddressEntity address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete address?'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final (success, failure) =
        await sl<AddressRepository>().deleteAddress(address.id);
    if (!mounted) return;
    if (!success) {
      TopSnackBar.show(
        context,
        message: failure?.message ?? 'Unable to delete address.',
        type: TopSnackBarType.error,
      );
      return;
    }
    setState(() {
      _savedAddresses =
          _savedAddresses.where((a) => a.id != address.id).toList();
      if (_selectedDeliveryAddress?.id == address.id) {
        _selectedDeliveryAddress = null;
      }
    });
    if (_storedAddress?.id == address.id) {
      await SelectedAddressStore.clear();
      if (!mounted) return;
      setState(() => _storedAddress = null);
    }
  }

  // Picking a saved address here only updated this page's own ephemeral
  // widget state before — it never actually took effect (survived
  // navigation, showed up at checkout, etc.) because nothing persisted it.
  // SelectedAddressStore is the single source of truth the rest of the app
  // (nav bar, checkout) already reads from, so save there too — mirrors the
  // web app's selectDeliveryLocation, which updates both redux state and
  // localStorage's storedAddress.
  Future<void> _selectAddress(AddressEntity address) async {
    setState(() => _selectedDeliveryAddress = address);
    await SelectedAddressStore.save(address);
    if (!mounted) return;
    setState(() => _storedAddress = SelectedAddressStore.cached);
  }

  // "Add new address" here used to push the whole search screen
  // (AddressSelectionWidget), which has its own "Add new address" tile —
  // forcing a second, redundant tap. Go straight to the map-confirm step
  // instead, mirroring AddressSelectionWidget's own _openMap(): a default
  // Bengaluru pin (auto-resolved once the map loads) unless the user drags
  // it or searches from there.
  Future<void> _openAddressFlow() async {
    // Push through appNavigatorKey.currentContext, not this page's own
    // `context` — ConfirmDeliveryLocationPage/AddAddressDetailPage use
    // `parentNavigatorKey: appNavigatorKey` to escape onto the root
    // navigator, and popping back off it can leave this page's own
    // BuildContext/State reporting not-mounted (a GoRouter/StatefulShellRoute
    // quirk with parentNavigatorKey-escaped routes) even though the page is
    // still alive underneath — gating on `mounted` here silently aborted the
    // whole flow right after the map step confirmed a location.
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) return;
    final confirmed = await navContext.push<AddressEntity>(
      ConfirmDeliveryLocationPage.routePath,
      extra: const AddressLocationEntity(
        latitude: 12.9716,
        longitude: 77.5946,
        formattedAddress: '',
        city: '',
        state: '',
        pincode: '',
        sublocality: '',
        locationName: '',
      ),
    );
    if (confirmed == null) return;
    final navContext2 = appNavigatorKey.currentContext;
    if (navContext2 == null) return;
    final savedAddress = await navContext2.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: confirmed,
    );
    if (savedAddress == null) return;
    await SelectedAddressStore.save(savedAddress);
    if (!mounted) return;
    setState(() {
      _storedAddress = savedAddress;
      _savedAddresses = [..._savedAddresses, savedAddress];
    });
  }
}
