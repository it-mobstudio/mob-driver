import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/add_address_detail_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/address_picker.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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
  bool _sameAddress = false;
  AddressEntity? _selectedDelivery;
  AddressEntity? _selectedBilling;

  // null = not checked yet, true = serviceable, false = not serviceable
  bool? _pincodeValid;
  bool _checkingPincode = false;
  String _lastCheckedPincode = '';

  @override
  void initState() {
    super.initState();
    _cartBloc = context.read<CartBloc>();
    _addressBloc = sl<AddressBloc>()..add(AddressLoadRequested());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cartBloc.add(CartLoadRequested(outOfStock: true));
    });
  }

  @override
  void dispose() {
    _addressBloc.close();
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

  // Mirrors web's CheckoutAddress.jsx: once saved addresses load, if the
  // cart doesn't already have a delivery/billing address picked, default
  // to the first saved address (delivery) and whichever saved address is
  // flagged as the mobCREDIT/billing address (billing) — instead of
  // leaving the user to manually pick an address they've already saved.
  void _autoSelectDefaultAddresses(
    CartSummaryEntity summary,
    List<AddressEntity> addresses,
  ) {
    if (addresses.isEmpty) return;
    var changed = false;

    if (_selectedDelivery == null && summary.shippingAddress.trim().isEmpty) {
      _selectedDelivery = addresses.first;
      changed = true;
    }

    if (!_sameAddress &&
        _selectedBilling == null &&
        summary.billingAddress.trim().isEmpty) {
      for (final address in addresses) {
        if (address.mobCredit) {
          _selectedBilling = address;
          changed = true;
          break;
        }
      }
    }

    if (changed) setState(() {});
  }

  List<AddressEntity> _addressList() {
    final state = _addressBloc.state;
    if (state is AddressListLoaded) return state.addresses;
    return const [];
  }

  bool _canContinue(CartSummaryEntity summary) {
    final hasDelivery = _selectedDelivery != null || summary.hasDeliveryAddress;
    final hasBilling = _sameAddress ||
        _selectedBilling != null ||
        summary.billingAddress.trim().isNotEmpty;
    // Block if pincode is confirmed invalid; allow if null (not checked) or true
    final pincodeOk = _pincodeValid != false;
    return hasDelivery && hasBilling && pincodeOk && !_checkingPincode;
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
                    if (forBilling && !_sameAddress) {
                      _selectedBilling = address;
                    } else {
                      _selectedDelivery = address;
                      if (_sameAddress) _selectedBilling = address;
                      // Reset pincode validity and re-check for new delivery address
                      _pincodeValid = null;
                      _lastCheckedPincode = '';
                    }
                  });
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
    // map-confirm step (defaulting to a Bengaluru pin) then the receiver
    // detail form, instead of a whole separate search screen.
    final confirmed = await context.push<AddressEntity>(
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
    if (!context.mounted || confirmed == null) return;
    final savedAddress = await context.push<AddressEntity>(
      AddAddressDetailPage.routePath,
      extra: confirmed,
    );
    if (!context.mounted || savedAddress == null) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure?.message ?? 'Unable to delete address.'),
        ),
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
      child: Scaffold(
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
                                .add(CartLoadRequested(outOfStock: true)),
                          ),
                        CartRequiresLogin() => const Center(
                            child: Text('Please login to continue.'),
                          ),
                        CartLoaded(:final summary) =>
                          BlocBuilder<AddressBloc, AddressState>(
                            bloc: _addressBloc,
                            builder: (context, addressState) {
                              final addresses = _addressList();
                              // Mirror web hasSavedAddress:
                              // show CHANGE if cart already has an address OR
                              // user has any saved addresses in their account
                              final hasAnyAddress = _selectedDelivery != null ||
                                  summary.shippingAddressId.isNotEmpty ||
                                  addresses.isNotEmpty;

                              // Trigger pincode check on first load
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _autoSelectDefaultAddresses(summary, addresses);
                                final pincode =
                                    _selectedDelivery?.pincode.isNotEmpty ==
                                            true
                                        ? _selectedDelivery!.pincode
                                        : summary.shippingPincode;
                                _checkPincode(pincode);
                              });

                              return Stack(
                                children: [
                                  ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 118),
                                    children: [
                                      if (_pincodeValid == false)
                                        const _PincodeErrorBanner(),
                                      if (_pincodeValid == false)
                                        const SizedBox(height: 12),
                                      _DeliveryAddressCard(
                                        name: _selectedDelivery?.name ??
                                            summary.shippingRecipientName,
                                        address:
                                            _selectedDelivery?.displayAddress ??
                                                summary.shippingAddress,
                                        phone: _selectedDelivery?.phoneNumber ??
                                            summary.shippingPhone,
                                        tag:
                                            _selectedDelivery?.addressTag ?? '',
                                        project:
                                            _selectedDelivery?.projectName ??
                                                '',
                                        actionLabel:
                                            hasAnyAddress ? 'Change' : 'Add',
                                        onAction: () =>
                                            _showAddressDrawer(context),
                                      ),
                                      const SizedBox(height: 12),
                                      _SameAddressRow(
                                        checked: _sameAddress,
                                        onChanged: (v) =>
                                            setState(() => _sameAddress = v),
                                      ),
                                      const SizedBox(height: 20),
                                      _BillingAddressCard(
                                        address: _sameAddress
                                            ? (_selectedDelivery
                                                    ?.displayAddress ??
                                                summary.shippingAddress)
                                            : (_selectedBilling
                                                    ?.displayAddress ??
                                                summary.billingAddress),
                                        gstNumber: summary.billingGstNumber,
                                        actionLabel: _sameAddress
                                            ? 'Change'
                                            : ((_selectedBilling != null ||
                                                    summary.billingAddress
                                                        .trim()
                                                        .isNotEmpty ||
                                                    hasAnyAddress)
                                                ? 'Change'
                                                : 'Add'),
                                        onAction: _sameAddress
                                            ? null
                                            : () => _showAddressDrawer(context,
                                                forBilling: true),
                                      ),
                                      const SizedBox(height: 20),
                                      OrderDetailsCard(
                                        subtotal: summary.subtotal,
                                        shipping: summary.shipping,
                                        tax: summary.tax,
                                        savings: summary.savings,
                                        total: summary.total,
                                        earningPoints: summary.earningPoints,
                                      ),
                                    ],
                                  ),
                                  BottomCheckoutBar(
                                    label: 'Continue',
                                    isDisabled: !_canContinue(summary),
                                    onProceed: () {
                                      final deliveryId = int.tryParse(
                                            _selectedDelivery?.id ??
                                                summary.shippingAddressId,
                                          ) ??
                                          0;
                                      final billingId = _sameAddress
                                          ? deliveryId
                                          : int.tryParse(
                                                _selectedBilling?.id ??
                                                    summary.billingAddressId,
                                              ) ??
                                              deliveryId;
                                      context.push(
                                        CheckoutOrderReviewPage.routePath,
                                        extra: {
                                          'cart_id':
                                              int.tryParse(summary.cartId) ?? 0,
                                          'delivery_address_id': deliveryId,
                                          'billing_address_id': billingId,
                                        },
                                      );
                                    },
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
    required this.actionLabel,
    required this.onAction,
    this.tag = '',
    this.project = '',
  });

  final String name;
  final String address;
  final String phone;
  final String actionLabel;
  final VoidCallback onAction;
  final String tag;
  final String project;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Add address';
    final displayAddress = address.trim().isNotEmpty
        ? address.trim()
        : 'Select a delivery address to continue';
    final displayPhone = phone.trim();
    final displayTag = tag.trim();
    final displayProject = project.trim();
    final hasPills = displayTag.isNotEmpty || displayProject.isNotEmpty;

    return _CheckoutCard(
      padding: const EdgeInsets.all(12),
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
                      const TextSpan(
                        text: 'Deliver to:',
                        style: TextStyle(
                          color: Color(0xFF67696D),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 1.43,
                        ),
                      ),
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
                      if (displayTag.isNotEmpty)
                        _AddressPill(
                          text: displayTag,
                          color: const Color(0xFFE6EEF9),
                        ),
                      if (displayTag.isNotEmpty && displayProject.isNotEmpty)
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
        borderRadius: BorderRadius.circular(4),
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
  const _SameAddressRow({required this.checked, required this.onChanged});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: checked ? const Color(0xFF2973F0) : Colors.white,
              border: Border.all(
                color:
                    checked ? const Color(0xFF2973F0) : const Color(0xFF767C8F),
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: checked
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Use same address for delivery and billing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF0A243F),
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
    required this.actionLabel,
    required this.onAction,
  });

  final String address;
  final String gstNumber;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final displayAddress = address.trim();
    final displayGstNumber = gstNumber.trim();

    return _CheckoutCard(
      height: 128,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Billing address',
                  style: TextStyle(
                    color: Color(0xFF0A243F),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.43,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0360E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 20,
            child: displayGstNumber.isNotEmpty
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
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
                            color: const Color(0xFF0A243F),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 16 / 11,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          Text(
            displayAddress.isNotEmpty
                ? displayAddress
                : 'Add billing address to continue',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF767C8F),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
            ),
          ),
        ],
      ),
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
    this.height,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
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
            width: 92,
            height: 92,
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
