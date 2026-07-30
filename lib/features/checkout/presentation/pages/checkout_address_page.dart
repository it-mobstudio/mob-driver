import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/app_runtime/nav/nav.dart'
    show appNavigatorKey;
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/add_address_detail_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_payment_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/address_picker.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

class CheckoutAddressPage extends StatefulWidget {
  static const routeName = 'CheckoutAddressPage';
  static const routePath = '/checkout/address';

  const CheckoutAddressPage({super.key});

  @override
  State<CheckoutAddressPage> createState() => _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage> {
  late final AddressBloc _addressBloc;
  late final CartBloc _cartBloc;
  late final CheckoutBloc _checkoutBloc;
  bool _sameAddress = false;
  AddressEntity? _storedSelectedAddress;
  bool _selectedAddressLoaded = false;
  AddressEntity? _selectedDelivery;
  AddressEntity? _selectedBilling;
  bool _cartNeedsReview = false;

  // null = not checked yet, true = serviceable, false = not serviceable
  bool? _pincodeValid;
  bool _checkingPincode = false;
  String _lastCheckedPincode = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logBeginCheckout().catchError((_) {});
    _cartBloc = context.read<CartBloc>();
    _addressBloc = sl<AddressBloc>()..add(AddressLoadRequested());
    _checkoutBloc = sl<CheckoutBloc>();
    _loadSelectedAddress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cartBloc.add(CartLoadRequested());
    });
  }

  @override
  void dispose() {
    _addressBloc.close();
    _checkoutBloc.close();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // push (not go) — preserves the StatefulShellRoute underneath so
      // Cart's own back button can simply pop instead of having to tear
      // down and recreate the shell (which raced and threw duplicate
      // GlobalKey / deactivated-element errors).
      context.push('/cart');
    }
  }

  Future<void> _loadSelectedAddress() async {
    final selected =
        SelectedAddressStore.cached ?? await SelectedAddressStore.read();
    if (!mounted) return;
    setState(() {
      _storedSelectedAddress = selected;
      _selectedAddressLoaded = true;
      if (selected != null && selected.id.trim().isNotEmpty) {
        _selectedDelivery = selected;
      }
    });
  }

  Future<void> _checkPincode(String pincode) async {
    if (pincode.isEmpty || pincode == _lastCheckedPincode) return;
    _lastCheckedPincode = pincode;
    setState(() => _checkingPincode = true);
    try {
      final response = await DioClient.instance.dio.get<dynamic>(
        '/utility/serviceble/',
        queryParameters: {'pincode': pincode},
      );
      final data = response.data;
      final isServiceable = data is Map
          ? (data['status'] == true || data['serviceable'] == true)
          : false;
      if (mounted) {
        setState(() {
          _pincodeValid = isServiceable;
          _checkingPincode = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pincodeValid = null;
          _checkingPincode = false;
        });
      }
    }
  }

  // Checkout delivery follows the address selected in the top nav. If nothing
  // saved is selected there, only the saved mobCREDIT address can be used as a
  // default; otherwise delivery remains blank for the user to choose/add.
  void _autoSelectDefaultAddresses(
    List<AddressEntity> addresses,
  ) {
    if (!_selectedAddressLoaded) return;
    if (addresses.isEmpty) return;
    var changed = false;
    final selectedAddress = _storedSelectedAddress;
    final selectedAddressId = selectedAddress?.id.trim() ?? '';

    if (selectedAddress != null) {
      // A selected address with no DB id is only a browsing/current location.
      // Treat it as no saved top-nav address so mobCREDIT can still be used
      // as the explicit saved-address fallback.
      if (selectedAddressId.isNotEmpty) {
        final savedSelectedAddress = _addressById(addresses, selectedAddressId);
        if (savedSelectedAddress != null &&
            _selectedDelivery?.id != savedSelectedAddress.id) {
          _selectedDelivery = savedSelectedAddress;
          changed = true;
        }
      }
    }

    if (selectedAddressId.isEmpty && _selectedDelivery == null) {
      final mobCreditAddress = _mobCreditAddress(addresses);
      if (mobCreditAddress != null) {
        _selectedDelivery = mobCreditAddress;
        changed = true;
      }
    }

    if (changed) setState(() {});
  }

  bool get _hasSavedTopNavAddress {
    return _storedSelectedAddress?.id.trim().isNotEmpty == true;
  }

  List<AddressEntity> _addressList() {
    final state = _addressBloc.state;
    if (state is AddressListLoaded) return state.addresses;
    return const [];
  }

  bool get _needsSavedDeliveryAddress {
    final selectedAddress = _storedSelectedAddress;
    return selectedAddress != null &&
        selectedAddress.id.trim().isEmpty &&
        _selectedDelivery == null;
  }

  bool _canContinue(CartSummaryEntity summary) {
    if (summary.isEmpty) return false;
    final hasDelivery = _selectedDelivery != null ||
        (_hasSavedTopNavAddress && summary.hasDeliveryAddress);
    final hasBilling = _sameAddress ||
        _selectedBilling != null ||
        summary.billingAddress.trim().isNotEmpty;
    // Block if pincode is confirmed invalid; allow if null (not checked) or true
    final pincodeOk = _pincodeValid != false;
    return hasDelivery && hasBilling && pincodeOk && !_checkingPincode;
  }

  void _continueToPayment(CartSummaryEntity summary) {
    final deliveryId = int.tryParse(
          _selectedDelivery?.id ?? summary.shippingAddressId,
        ) ??
        0;
    final billingId = _sameAddress
        ? deliveryId
        : int.tryParse(
              _selectedBilling?.id ?? summary.billingAddressId,
            ) ??
            deliveryId;
    _checkoutBloc.add(
      CheckoutAddressUpdateRequested(
        payload: {
          'cart_id': int.tryParse(summary.cartId) ?? 0,
          'order_delivery_address': deliveryId,
          'order_billing_address': billingId,
        },
      ),
    );
  }

  AddressEntity? _addressById(List<AddressEntity> addresses, String id) {
    final targetId = id.trim();
    if (targetId.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == targetId) return address;
    }
    return null;
  }

  AddressEntity? _effectiveDeliveryAddress(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    if (_needsSavedDeliveryAddress) return null;
    if (_selectedDelivery != null) return _selectedDelivery;
    if (!_hasSavedTopNavAddress) return null;
    return _addressById(addresses, summary.shippingAddressId);
  }

  AddressEntity? _mobCreditAddress(List<AddressEntity> addresses) {
    for (final address in addresses) {
      final tag = address.addressTag.trim().toLowerCase();
      if (address.mobCredit || tag == 'mobcredit' || tag == 'mob credit') {
        return address;
      }
    }
    return null;
  }

  AddressEntity? _effectiveBillingAddress(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    if (_sameAddress) return _effectiveDeliveryAddress(summary, addresses);
    return _selectedBilling ??
        _addressById(addresses, summary.billingAddressId);
  }

  /// Builds the address text purely from address_line_1/2 + city/state/
  /// pincode — each omitted when empty — instead of the Google-formatted
  /// blob, so a field that's missing on this address never leaves a stray
  /// or doubled comma in the display.
  String _addressLines(AddressEntity address) {
    return [
      address.addressLine1.trim(),
      address.addressLine2.trim(),
      address.city.trim(),
      address.state.trim(),
      address.pincode.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  String _billingAddressText(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    final billingAddress = _effectiveBillingAddress(summary, addresses);
    if (billingAddress != null) return _addressLines(billingAddress);
    if (_sameAddress) {
      return _needsSavedDeliveryAddress ? '' : summary.shippingAddress;
    }
    return summary.billingAddress;
  }

  String _billingPhone(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    final billingAddress = _effectiveBillingAddress(summary, addresses);
    if (billingAddress != null) return billingAddress.phoneNumber;
    if (_sameAddress) {
      return _needsSavedDeliveryAddress ? '' : summary.shippingPhone;
    }
    return '';
  }

  String _billingGstNumber(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    return _effectiveBillingAddress(summary, addresses)?.gstNumber ?? '';
  }

  void _showAddressDrawer(BuildContext context, {bool forBilling = false}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // BlocProvider.value + BlocBuilder (not just a snapshot list) so
        // edit/delete can refresh the address list in place without closing
        // this sheet — a bottom-sheet route sits alongside the page's own
        // route, not inside its widget subtree, so it can't see _addressBloc
        // unless it's re-provided here.
        return BlocProvider<AddressBloc>.value(
          value: _addressBloc,
          child: BlocBuilder<AddressBloc, AddressState>(
            builder: (context, state) {
              return _AddressSelectionDrawer(
                addresses: state is AddressListLoaded
                    ? state.addresses
                    : _addressList(),
                title: forBilling
                    ? 'Select billing address'
                    : 'Select delivery address',
                selectedAddressId:
                    (forBilling ? _selectedBilling : _selectedDelivery)?.id,
                onAddAddress: () {
                  Navigator.of(sheetContext).pop();
                  _openAddressFlow(context);
                },
                onSelectAddress: (address) {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    if (forBilling) {
                      _selectedBilling = address;
                      if (_sameAddress) _sameAddress = false;
                    } else {
                      _selectedDelivery = address;
                      _storedSelectedAddress = address;
                      if (_sameAddress) _selectedBilling = address;
                      // Reset pincode validity and re-check for new delivery address
                      _pincodeValid = null;
                      _lastCheckedPincode = '';
                    }
                  });
                  if (!forBilling) {
                    unawaited(SelectedAddressStore.save(address));
                  }
                  if (!forBilling || _sameAddress) {
                    _checkPincode(address.pincode);
                  }
                },
                // Edit/delete keep this sheet open — the BlocBuilder above
                // picks up the refreshed list once the edit page returns or
                // the delete confirmation completes.
                onEditAddress: _editAddress,
                onDeleteAddress: _confirmDeleteAddress,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openAddressFlow(BuildContext context) async {
    // Same shortcut as cart/AddressSelectionWidget: straight to the
    // map-confirm step (centering on current GPS when no location is known)
    // then the receiver detail form, instead of a whole separate search screen.
    //
    // Both pushes deliberately go through appNavigatorKey.currentContext
    // rather than this method's own `context` parameter: ConfirmDeliveryLocationPage
    // and AddAddressDetailPage use `parentNavigatorKey: appNavigatorKey` to
    // escape onto the root navigator, and popping back off that navigator
    // leaves this page's own BuildContext reporting `mounted == false` (a
    // GoRouter/StatefulShellRoute quirk with parentNavigatorKey-escaped
    // routes) even though the page itself is still very much alive
    // underneath — gating on `context.mounted` here silently aborted the
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
    if (mounted) {
      setState(() {
        _storedSelectedAddress = savedAddress;
        _selectedAddressLoaded = true;
        _selectedDelivery = savedAddress;
        _pincodeValid = null;
        _lastCheckedPincode = '';
      });
      _checkPincode(savedAddress.pincode);
    }
    _addressBloc.add(AddressLoadRequested());
    _cartBloc.add(CartLoadRequested());
  }

  Future<void> _editAddress(AddressEntity existing) async {
    final updated = await context.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: existing,
    );
    if (!mounted || updated == null) return;
    setState(() {
      if (_selectedDelivery?.id == updated.id) _selectedDelivery = updated;
      if (_selectedBilling?.id == updated.id) _selectedBilling = updated;
    });
    _addressBloc.add(AddressLoadRequested());
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
      if (_selectedDelivery?.id == address.id) _selectedDelivery = null;
      if (_selectedBilling?.id == address.id) _selectedBilling = null;
    });
    _addressBloc.add(AddressLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddressBloc>.value(
      value: _addressBloc,
      child: BlocProvider<CheckoutBloc>.value(
        value: _checkoutBloc,
        child: BlocConsumer<CheckoutBloc, CheckoutState>(
          listener: (context, checkoutState) {
            if (!mounted) return;
            if (checkoutState is CheckoutAddressUpdated) {
              if (checkoutState.addressChanged) {
                setState(() => _cartNeedsReview = true);
                _cartBloc.add(CartLoadRequested());
              } else {
                context.push(CheckoutPaymentPage.routePath);
              }
            } else if (checkoutState is CheckoutError) {
              TopSnackBar.show(
                context,
                message: checkoutState.message,
                type: TopSnackBarType.error,
              );
            }
          },
          builder: (context, checkoutState) {
            final isUpdatingAddress = checkoutState is CheckoutLoading;
            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _CheckoutHeader(onBack: () => _goBack(context)),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF0F0F0),
                        child: BlocBuilder<CartBloc, CartState>(
                          builder: (context, state) {
                            return switch (state) {
                              CartInitial() || CartLoading() => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              CartError(:final message) => ErrorStateView(
                                  title: 'Unable to load checkout',
                                  message: message,
                                  onRetry: () => context
                                      .read<CartBloc>()
                                      .add(CartLoadRequested()),
                                ),
                              CartRequiresLogin() => const Center(
                                  child: Text('Please login to continue.'),
                                ),
                              CartLoaded(:final summary) =>
                                BlocBuilder<AddressBloc, AddressState>(
                                  bloc: _addressBloc,
                                  builder: (context, addressState) {
                                    final addresses = _addressList();
                                    final showCartDeliveryAddress =
                                        _hasSavedTopNavAddress;
                                    // Mirror web hasSavedAddress:
                                    // show CHANGE if cart already has an address
                                    // OR user has any saved addresses.
                                    final hasAnyAddress =
                                        _selectedDelivery != null ||
                                            (showCartDeliveryAddress &&
                                                summary.shippingAddressId
                                                    .isNotEmpty) ||
                                            addresses.isNotEmpty;
                                    final hasEffectiveDeliveryAddress =
                                        _effectiveDeliveryAddress(
                                                  summary,
                                                  addresses,
                                                ) !=
                                                null ||
                                            (showCartDeliveryAddress &&
                                                summary.hasDeliveryAddress);
                                    final isMissingDeliveryAddress =
                                        !hasEffectiveDeliveryAddress;
                                    final effectiveBillingAddress =
                                        _effectiveBillingAddress(
                                      summary,
                                      addresses,
                                    );

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      _autoSelectDefaultAddresses(addresses);
                                      final pincode = _selectedDelivery
                                                  ?.pincode.isNotEmpty ==
                                              true
                                          ? _selectedDelivery!.pincode
                                          : showCartDeliveryAddress
                                              ? summary.shippingPincode
                                              : '';
                                      _checkPincode(pincode);
                                    });

                                    return Stack(
                                      children: [
                                        ListView(
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            16,
                                            16,
                                            _cartNeedsReview ? 190 : 118,
                                          ),
                                          children: [
                                            if (_pincodeValid == false)
                                              const _PincodeErrorBanner(),
                                            if (_pincodeValid == false)
                                              const SizedBox(height: 12),
                                            _DeliveryAddressCard(
                                              name: _selectedDelivery?.name ??
                                                  (showCartDeliveryAddress
                                                      ? summary
                                                          .shippingRecipientName
                                                      : ''),
                                              address: _selectedDelivery != null
                                                  ? _addressLines(
                                                      _selectedDelivery!,
                                                    )
                                                  : (showCartDeliveryAddress
                                                      ? summary.shippingAddress
                                                      : ''),
                                              phone: _selectedDelivery
                                                      ?.phoneNumber ??
                                                  (showCartDeliveryAddress
                                                      ? summary.shippingPhone
                                                      : ''),
                                              tag: _selectedDelivery
                                                      ?.addressTag ??
                                                  '',
                                              project: _selectedDelivery
                                                      ?.projectName ??
                                                  '',
                                              isMissingDeliveryAddress:
                                                  isMissingDeliveryAddress,
                                              actionLabel: hasAnyAddress
                                                  ? 'Change'
                                                  : 'Add',
                                              onAction: () =>
                                                  _showAddressDrawer(context),
                                            ),
                                            const SizedBox(height: 12),
                                            _SameAddressRow(
                                              checked: _sameAddress &&
                                                  hasEffectiveDeliveryAddress,
                                              enabled:
                                                  hasEffectiveDeliveryAddress,
                                              onChanged: (v) {
                                                if (!hasEffectiveDeliveryAddress) {
                                                  return;
                                                }
                                                setState(
                                                  () => _sameAddress = v,
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            _BillingAddressCard(
                                              address: _billingAddressText(
                                                summary,
                                                addresses,
                                              ),
                                              phone: _billingPhone(
                                                summary,
                                                addresses,
                                              ),
                                              gstNumber: _billingGstNumber(
                                                summary,
                                                addresses,
                                              ),
                                              tag: effectiveBillingAddress
                                                      ?.addressTag ??
                                                  '',
                                              project: effectiveBillingAddress
                                                      ?.projectName ??
                                                  '',
                                              isMobCredit:
                                                  effectiveBillingAddress
                                                          ?.mobCredit ??
                                                      false,
                                              isMissingBillingAddress:
                                                  !_sameAddress &&
                                                      effectiveBillingAddress ==
                                                          null &&
                                                      summary.billingAddress
                                                          .trim()
                                                          .isEmpty,
                                              actionLabel:
                                                  (effectiveBillingAddress !=
                                                              null ||
                                                          summary.billingAddress
                                                              .trim()
                                                              .isNotEmpty)
                                                      ? 'Change'
                                                      : 'Add',
                                              onAction: () =>
                                                  _showAddressDrawer(
                                                context,
                                                forBilling: true,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            OrderDetailsCard(
                                              subtotal: summary.subtotal,
                                              shipping: summary.shipping,
                                              tax: summary.tax,
                                              savings: summary.savings,
                                              total: summary.total,
                                              earningPoints:
                                                  summary.earningPoints,
                                            ),
                                          ],
                                        ),
                                        if (_cartNeedsReview)
                                          _ReviewCartBottomBar(
                                            isLoading: isUpdatingAddress,
                                            onReviewCart: () => context.go(
                                              '/cart?cartUpdated=true',
                                            ),
                                          )
                                        else
                                          BottomCheckoutBar(
                                            label: 'Continue to payment',
                                            isDisabled: !_canContinue(summary),
                                            isLoading: isUpdatingAddress,
                                            onProceed: () =>
                                                _continueToPayment(summary),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            };
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartUpdatedReviewBanner extends StatelessWidget {
  const _CartUpdatedReviewBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/error-bg.svg',
          width: 38,
          height: 38,
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Your cart has been updated for your new location.Please review before checkout.',
            style: TextStyle(
              color: Color(0xFF0A243F),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewCartBottomBar extends StatelessWidget {
  const _ReviewCartBottomBar({
    required this.onReviewCart,
    this.isLoading = false,
  });

  final VoidCallback onReviewCart;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(bottom: bottomInset + 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _CartUpdatedReviewBanner(),
            ),
            Container(
              height: 1,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 9),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onReviewCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0360E5),
                    disabledBackgroundColor: const Color(0xFFB0C4DE),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Review cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Add address detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0A243F),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                height: 1.47,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 48,
                height: 50,
                child: Align(
                  alignment: Alignment.center,
                  child: AppBackIcon(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.name,
    required this.address,
    required this.phone,
    required this.isMissingDeliveryAddress,
    required this.actionLabel,
    required this.onAction,
    this.tag = '',
    this.project = '',
  });

  final String name;
  final String address;
  final String phone;
  final bool isMissingDeliveryAddress;
  final String actionLabel;
  final VoidCallback onAction;
  final String tag;
  final String project;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim();
    final displayAddress = address.trim().isNotEmpty
        ? address.trim()
        : 'Select a delivery address to continue';
    final displayPhone = phone.trim();
    final displayTag = tag.trim();
    final displayProject = project.trim();
    final showTag = displayTag.isNotEmpty && !_isMobCreditTag(displayTag);
    final hasPills = showTag || displayProject.isNotEmpty;

    final card = _CheckoutCard(
      padding: const EdgeInsets.all(12),
      border: isMissingDeliveryAddress
          ? Border.all(color: const Color(0xFFF0483E))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: displayName.isEmpty
                            ? 'Delivery address'
                            : 'Deliver to:',
                        style: TextStyle(
                          color: Color(0xFF67696D),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.43,
                        ),
                      ),
                      if (displayName.isNotEmpty)
                        TextSpan(
                          text: ' $displayName',
                          style: const TextStyle(
                            color: Color(0xFF0A243F),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    displayAddress,
                    if (displayPhone.isNotEmpty) displayPhone,
                  ].join('\n'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF67696D),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                if (hasPills) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (showTag)
                        _AddressPill(
                          text: displayTag,
                          color: const Color(0xFFE6EEF9),
                        ),
                      if (showTag && displayProject.isNotEmpty)
                        const SizedBox(width: 8),
                      if (displayProject.isNotEmpty)
                        Flexible(
                          child: _AddressPill(
                            text: displayProject.startsWith('Project:')
                                ? displayProject
                                : 'Project: $displayProject',
                            color: const Color(0xFFFFEFCE),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Text(
              actionLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF2973F0),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.50,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isMissingDeliveryAddress) return card;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        const SizedBox(height: 6),
        Text(
          'Please add delivery address',
          style: GoogleFonts.inter(
            color: const Color(0xFFF0483E),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
        ),
      ],
    );
  }
}

bool _isMobCreditTag(String tag) {
  final normalized = tag.trim().toLowerCase();
  return normalized == 'mobcredit' || normalized == 'mob credit';
}

class _MobCreditTag extends StatelessWidget {
  const _MobCreditTag();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mobCreditTag.png',
      height: 20,
      fit: BoxFit.contain,
    );
  }
}

class _AddressPill extends StatelessWidget {
  const _AddressPill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 16 / 11,
        ),
      ),
    );
  }
}

class _SameAddressRow extends StatelessWidget {
  const _SameAddressRow({
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onChanged(!checked) : null,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF2973F0) : Colors.white,
              border: Border.all(
                color: checked
                    ? const Color(0xFF2973F0)
                    : enabled
                        ? const Color(0xFF767C8F)
                        : const Color(0xFFB8BDC5),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: checked
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Use same address for delivery and billing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF0A243F) : const Color(0xFF9AA1AD),
                fontSize: 11,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingAddressCard extends StatelessWidget {
  const _BillingAddressCard({
    required this.address,
    required this.gstNumber,
    required this.isMissingBillingAddress,
    required this.actionLabel,
    required this.onAction,
    this.tag = '',
    this.project = '',
    this.isMobCredit = false,
    this.phone = '',
  });

  final String address;
  final String phone;
  final String gstNumber;
  final String tag;
  final String project;
  final bool isMobCredit;
  final bool isMissingBillingAddress;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final displayAddress = address.trim();
    final displayPhone = phone.trim();
    final displayGstNumber = gstNumber.trim();
    final displayTag = tag.trim();
    final displayProject = project.trim();
    final showMobCreditTag = isMobCredit || _isMobCreditTag(displayTag);
    final hasPills =
        showMobCreditTag || displayTag.isNotEmpty || displayProject.isNotEmpty;

    final card = _CheckoutCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      border: isMissingBillingAddress
          ? Border.all(color: const Color(0xFFF0483E))
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Billing address',
                        style: TextStyle(
                          color: Color(0xFF0A243F),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.43,
                        ),
                      ),
                      if (isMissingBillingAddress)
                        const TextSpan(
                          text: ' + GST',
                          style: TextStyle(
                            color: Color(0xFF67696D),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Text(
                  actionLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF2973F0),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                  ),
                ),
              ),
            ],
          ),
          if (displayGstNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF133B62),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: Text(
                      'GST NO: $displayGstNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 16 / 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (displayAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                displayAddress,
                if (displayPhone.isNotEmpty) displayPhone,
              ].join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF767C8F),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
              ),
            ),
            if (hasPills) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (showMobCreditTag)
                    const _MobCreditTag()
                  else if (displayTag.isNotEmpty)
                    _AddressPill(
                      text: displayTag,
                      color: const Color(0xFFE6EEF9),
                    ),
                  if ((showMobCreditTag || displayTag.isNotEmpty) &&
                      displayProject.isNotEmpty)
                    const SizedBox(width: 8),
                  if (displayProject.isNotEmpty)
                    Flexible(
                      child: _AddressPill(
                        text: displayProject.startsWith('Project:')
                            ? displayProject
                            : 'Project: $displayProject',
                        color: const Color(0xFFFFD911),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );

    if (!isMissingBillingAddress) return card;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        const SizedBox(height: 6),
        Text(
          'Please add billing address',
          style: GoogleFonts.inter(
            color: const Color(0xFFF0483E),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
        ),
      ],
    );
  }
}

class _AddressSelectionDrawer extends StatelessWidget {
  const _AddressSelectionDrawer({
    required this.addresses,
    required this.onAddAddress,
    required this.onSelectAddress,
    required this.onEditAddress,
    required this.onDeleteAddress,
    this.selectedAddressId,
    this.title = 'Select delivery address',
  });

  final List<AddressEntity> addresses;
  final String? selectedAddressId;
  final String title;
  final VoidCallback onAddAddress;
  final ValueChanged<AddressEntity> onSelectAddress;
  final ValueChanged<AddressEntity> onEditAddress;
  final ValueChanged<AddressEntity> onDeleteAddress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 656 / 812,
        widthFactor: 1,
        child: Material(
          color: const Color(0xFFF7F7F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 22 / 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.close,
                              color: Color(0xFF0A243F),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AddressPickerBody(
                    addresses: addresses,
                    selectedAddressId: selectedAddressId,
                    showSearch: false,
                    showQuickActions: false,
                    onAddNewAddress: onAddAddress,
                    onSelectAddress: onSelectAddress,
                    onEditAddress: onEditAddress,
                    onDeleteAddress: onDeleteAddress,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _PincodeErrorBanner extends StatelessWidget {
  const _PincodeErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "We don't deliver\nhere yet.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 20 / 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please try another location.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67696D),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 136,
            height: 88,
            child: Lottie.asset(
              'assets/lottiejson/Unserviceable.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        ],
      ),
    );
  }
}
