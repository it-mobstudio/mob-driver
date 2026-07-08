import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/address_selection_widget.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';

/// Opens the RFQ ("purchase later / recheck prices") form as a true modal
/// bottom sheet over the current screen, matching the rest of the app's
/// sheet conventions (see `showCreditDocumentsSheet`) instead of a full page
/// route — a full route rendered its own fake dimmed backdrop and "Cart"
/// header, which looked like a totally different screen mid-transition.
Future<void> showCartRfqRequestSheet(
  BuildContext context,
  CartSummaryEntity summary,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _CartRfqRequestSheet(summary: summary),
  );
}

class _CartRfqRequestSheet extends StatefulWidget {
  const _CartRfqRequestSheet({required this.summary});

  final CartSummaryEntity summary;

  @override
  State<_CartRfqRequestSheet> createState() => _CartRfqRequestSheetState();
}

class _CartRfqRequestSheetState extends State<_CartRfqRequestSheet> {
  static const _navy = Color(0xFF0A243F);
  static const _muted = Color(0xFF6C7C8C);
  static const _border = Color(0xFFE1E6ED);
  static const _blue = Color(0xFF0865E8);

  final _formKey = GlobalKey<FormState>();
  final _sheetController = DraggableScrollableController();
  late final RfqBloc _rfqBloc;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailController = TextEditingController();
  AddressEntity? _selectedAddress;
  bool _phoneIsLocked = false;
  bool _rfqHowExpanded = false;
  String _submittedRfqId = '';

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
    _prefillForm();
  }

  @override
  void dispose() {
    _rfqBloc.close();
    _sheetController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _prefillForm() async {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = _firstValue(user, const ['full_name', 'name']);
    final phone = _firstValue(user, const ['phone_number', 'phone', 'mobile']);
    _phoneController.text = phone;
    _phoneIsLocked = phone.trim().isNotEmpty;
    _emailController.text = _firstValue(user, const ['email']);

    final cartAddress = _currentCartAddress;
    if (cartAddress != null) {
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = cartAddress.name;
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = cartAddress.phone;
        _phoneIsLocked = cartAddress.phone.trim().isNotEmpty;
      }
      _pincodeController.text = cartAddress.pincode;
    }

    final address =
        SelectedAddressStore.cached ?? await SelectedAddressStore.read();
    if (!mounted || address == null) return;
    setState(() {
      _selectedAddress = address;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = address.name;
      }
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = address.phoneNumber;
        _phoneIsLocked = address.phoneNumber.trim().isNotEmpty;
      }
      if (_pincodeController.text.trim().isEmpty) {
        _pincodeController.text = address.pincode;
      }
    });
  }

  String _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  CartAddressEntity? get _currentCartAddress {
    if (widget.summary.hasDeliveryAddress) {
      return CartAddressEntity(
        addressId: widget.summary.shippingAddressId,
        name: widget.summary.shippingRecipientName,
        address: widget.summary.shippingAddress,
        phone: widget.summary.shippingPhone,
        pincode: widget.summary.shippingPincode,
      );
    }
    return null;
  }

  bool get _hasAddress {
    return _selectedAddress != null || _currentCartAddress?.hasAddress == true;
  }

  String get _activeAddressId {
    final selectedId = _selectedAddress?.id.trim() ?? '';
    if (selectedId.isNotEmpty) return selectedId;
    return _currentCartAddress?.addressId.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: BlocConsumer<RfqBloc, RfqState>(
        listener: _onRfqStateChanged,
        builder: (context, state) {
          final submitting = state is CartRfqSubmitting;
          final screenHeight = MediaQuery.sizeOf(context).height;
          final childSize = _submittedRfqId.isEmpty ? 0.84 : 0.78;
          return SizedBox(
            height: screenHeight,
            child: Stack(
              children: [
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: childSize,
                  minChildSize: 0.56,
                  maxChildSize: 0.96,
                  snap: true,
                  snapSizes: const [0.56, 0.78, 0.84, 0.96],
                  builder: (context, scrollController) {
                    return _submittedRfqId.isEmpty
                        ? _requestSheet(submitting, scrollController)
                        : _successSheet(scrollController);
                  },
                ),
                // The close button lives in THIS outer, full-screen Stack
                // (not nested inside the DraggableScrollableSheet's own
                // builder) because a Positioned child painted outside the
                // sheet's own fractional bounds via Clip.none is visible but
                // NOT hit-testable — Flutter's hit-testing still gates on
                // each RenderBox's own reported size, which for the sheet's
                // content is only ever the current extent, never the
                // overflow above it. Tracking the live extent here keeps the
                // button positioned correctly as the sheet is dragged/snapped.
                AnimatedBuilder(
                  animation: _sheetController,
                  builder: (context, child) {
                    final extent = _sheetController.isAttached
                        ? _sheetController.size
                        : childSize;
                    // 44px button + 16px gap above the sheet's top edge,
                    // instead of the button's bottom half overlapping it.
                    return Positioned(
                      top: screenHeight * (1 - extent) - 60,
                      left: 0,
                      right: 0,
                      child: child!,
                    );
                  },
                  child: _closeButton(size: 44),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _closeButton({required double size}) {
    return Center(
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox(
            width: size,
            height: size,
            child: const Icon(Icons.close, color: _navy, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _requestSheet(bool submitting, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
              children: [
                Text(
                  'Quote request (RFQ)',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 34),
                if (widget.summary.items.isNotEmpty) ...[
                  _cartSummaryBanner(),
                  const SizedBox(height: 26),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_hasAddress) ...[
                        _field(
                          'Business name*',
                          _nameController,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Business name is required'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _field(
                        'Business mobile (for OTP)*',
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        readOnly: _phoneIsLocked,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) =>
                            value == null || value.trim().length != 10
                                ? 'Enter a valid 10-digit number'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      _field(
                        'Delivery pincode*',
                        _pincodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) =>
                            value == null || value.trim().length != 6
                                ? 'Enter a valid pincode'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      _field(
                        'Email id',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          return text.contains('@')
                              ? null
                              : 'Enter a valid email';
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _hasAddress ? _addressCard() : _addAddressTile(),
                const SizedBox(height: 20),
                _howRfqWorks(),
              ],
            ),
          ),
          _footer(submitting),
        ],
      ),
    );
  }

  Widget _cartSummaryBanner() {
    final itemCount = widget.summary.itemCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have added $itemCount items for quote request',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
                if (widget.summary.items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...widget.summary.items.take(3).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(right: 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  color: Colors.white,
                                  child: item.isNetworkImage
                                      ? Image.network(
                                          item.imageAsset,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 16,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View cart',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.chevron_right, color: _navy, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      style: GoogleFonts.inter(color: _navy, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.inter(color: _muted, fontSize: 13),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F7FA) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: _blue),
        errorBorder: _inputBorder(color: const Color(0xFFE14040)),
        focusedErrorBorder: _inputBorder(color: const Color(0xFFE14040)),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color color = _border}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _addAddressTile() {
    return InkWell(
      onTap: _openAddressFlow,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: _blue),
            const SizedBox(width: 12),
            Text(
              'Add address',
              style: GoogleFonts.inter(
                color: _blue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard() {
    final cartAddress = _currentCartAddress;
    final selected = _selectedAddress;
    final title = selected?.name.trim().isNotEmpty == true
        ? selected!.name.trim()
        : cartAddress?.name.trim().isNotEmpty == true
            ? cartAddress!.name.trim()
            : 'Saved address';
    final addressText = selected?.displayAddress.trim().isNotEmpty == true
        ? selected!.displayAddress.trim()
        : (cartAddress?.address.trim() ?? '');
    final phone = selected?.phoneNumber.trim().isNotEmpty == true
        ? selected!.phoneNumber.trim()
        : (cartAddress?.phone.trim() ?? '');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'Deliver to: '),
                      TextSpan(
                        text: title,
                        style: const TextStyle(color: _navy),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: _openAddressFlow,
                style: TextButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [addressText, phone].where((part) => part.isNotEmpty).join('\n'),
            style: GoogleFonts.inter(
              color: const Color(0xFF6C707A),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howRfqWorks() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _rfqHowExpanded = !_rfqHowExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'How RFQ works',
                      style: GoogleFonts.inter(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(
                      _rfqHowExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _navy,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_rfqHowExpanded) ...[
            _rfqStep(
              asset: 'assets/images/request.svg',
              title: '1. Submit Request',
              message: 'Submit your requirements through the RFQ form',
            ),
            _rfqStep(
              asset: 'assets/images/quotation.svg',
              title: '2. Receive Quotation',
              message:
                  'You will receive a quotation from our side within 24 hrs',
            ),
            _rfqStep(
              asset: 'assets/images/finalise.svg',
              title: '3. Finalise',
              message:
                  'If you like the quotes finalise the order and get it delivered',
              bottomPadding: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _rfqStep({
    required String asset,
    required String title,
    required String message,
    double bottomPadding = 12,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                asset,
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 12,
                    height: 17 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(bool submitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _blue,
            disabledBackgroundColor: _blue.withValues(alpha: 0.6),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Text(
                  'Submit',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _successSheet(ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              children: [
                const SizedBox(height: 24),
                Lottie.asset(
                  'assets/lottiejson/paymentsuccess.json',
                  width: 210,
                  height: 210,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
                const SizedBox(height: 2),
                Text(
                  'Quote requested',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                if (_submittedRfqId.isNotEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'RFQ No: $_submittedRfqId',
                        style: GoogleFonts.inter(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'Thanks! Our team will get back to you shortly with the final quote.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 14,
                    height: 21 / 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: SafeArea(
              top: false,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.goNamed(RfqPage.routeName);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View RFQ',
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddressFlow() async {
    final savedAddress = await context.push<AddressEntity>(
      AddressSelectionWidget.routePath,
      extra: {'showSearch': false, 'title': 'Your address'},
    );
    if (!mounted || savedAddress == null) return;
    setState(() {
      _selectedAddress = savedAddress;
      if (savedAddress.name.trim().isNotEmpty) {
        _nameController.text = savedAddress.name.trim();
      }
      if (savedAddress.phoneNumber.trim().isNotEmpty) {
        _phoneController.text = savedAddress.phoneNumber.trim();
        _phoneIsLocked = true;
      }
      if (savedAddress.pincode.trim().isNotEmpty) {
        _pincodeController.text = savedAddress.pincode.trim();
      }
    });
  }

  String _addressCity() {
    final selectedCity = _selectedAddress?.city.trim() ?? '';
    if (selectedCity.isNotEmpty) return selectedCity;
    final address = _currentCartAddress?.address ?? '';
    return address.split(',').map((part) => part.trim()).firstWhere(
          (part) => part.isNotEmpty && !RegExp(r'^[0-9 ]+$').hasMatch(part),
          orElse: () => '',
        );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _rfqBloc.add(
      CartRfqSubmitRequested({
        'quantity': 1,
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'city': _addressCity(),
        'email': _emailController.text.trim(),
        'cart_id': int.tryParse(widget.summary.cartId) ?? widget.summary.cartId,
        if (_activeAddressId.isNotEmpty)
          'address': int.tryParse(_activeAddressId) ?? _activeAddressId,
      }),
    );
  }

  void _onRfqStateChanged(BuildContext context, RfqState state) {
    if (state is CartRfqSubmitted) {
      setState(() => _submittedRfqId = state.rfqId);
      return;
    }
    if (state is CartRfqError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }
}
