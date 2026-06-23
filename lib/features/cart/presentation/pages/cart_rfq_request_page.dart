import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';

class CartRfqRequestPage extends StatefulWidget {
  const CartRfqRequestPage({super.key, required this.summary});

  static const String routeName = 'CartRfqRequestPage';
  static const String routePath = '/cart/rfq-request';

  final CartSummaryEntity summary;

  @override
  State<CartRfqRequestPage> createState() => _CartRfqRequestPageState();
}

class _CartRfqRequestPageState extends State<CartRfqRequestPage> {
  static const _navy = Color(0xFF0A243F);
  static const _muted = Color(0xFF6C7C8C);
  static const _border = Color(0xFFE1E6ED);
  static const _yellow = Color(0xFFFECB00);

  final _formKey = GlobalKey<FormState>();
  late final RfqBloc _rfqBloc;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentsController = TextEditingController();
  bool _phoneIsLocked = false;

  @override
  void initState() {
    super.initState();
    _rfqBloc = sl<RfqBloc>();
    _prefillForm();
  }

  @override
  void dispose() {
    _rfqBloc.close();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _prefillForm() async {
    final user = AuthSession.instance.userDetails ?? const <String, dynamic>{};
    _nameController.text = _firstValue(user, const ['full_name', 'name']);
    final phone = _firstValue(
      user,
      const ['phone_number', 'phone', 'mobile'],
    );
    _phoneController.text = phone;
    _phoneIsLocked = phone.trim().isNotEmpty;
    _emailController.text = _firstValue(user, const ['email']);

    final address =
        SelectedAddressStore.cached ?? await SelectedAddressStore.read();
    if (!mounted || address == null) return;
    if (_cityController.text.trim().isEmpty) {
      setState(() => _cityController.text = address.city);
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RfqBloc>.value(
      value: _rfqBloc,
      child: BlocConsumer<RfqBloc, RfqState>(
        listener: _onRfqStateChanged,
        builder: (context, state) {
          final submitting = state is CartRfqSubmitting;
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: SafeArea(
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        _cartSummaryBanner(),
                        const SizedBox(height: 20),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _field(
                                'Name (Business/ Individual)*',
                                _nameController,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Name is required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _field(
                                      'Business mobile (for OTP)*',
                                      _phoneController,
                                      keyboardType: TextInputType.phone,
                                      readOnly: _phoneIsLocked,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      validator: (value) =>
                                          value == null ||
                                                  value.trim().length != 10
                                              ? 'Enter a valid 10-digit number'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _field(
                                      'City*',
                                      _cityController,
                                      validator: (value) =>
                                          value == null ||
                                                  value.trim().isEmpty
                                              ? 'City is required'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _field(
                                'Email Id (optional)',
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
                              const SizedBox(height: 16),
                              _field(
                                'Comments',
                                _commentsController,
                                minLines: 3,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _footer(submitting),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quote request (RFQ)',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: _navy),
          ),
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
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                if (widget.summary.items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...widget.summary.items.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 32,
                              height: 32,
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
                      if (widget.summary.items.length > 3)
                        Text(
                          '+${widget.summary.items.length - 3} more',
                          style: GoogleFonts.inter(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View cart',
              style: GoogleFonts.inter(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: _navy, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.inter(color: _muted, fontSize: 13),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF5F7FA) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: const Color(0xFF0360E5)),
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

  Widget _footer(bool submitting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(48),
                  ),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.inter(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _yellow,
                  disabledBackgroundColor: _yellow.withValues(alpha: 0.6),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(48),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: _navy,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        'SUBMIT',
                        style: GoogleFonts.inter(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _rfqBloc.add(
      CartRfqSubmitRequested({
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'email': _emailController.text.trim(),
        'comments': _commentsController.text.trim(),
        'cart_id': widget.summary.cartId,
        if (widget.summary.shippingAddressId.isNotEmpty)
          'address': widget.summary.shippingAddressId,
      }),
    );
  }

  void _onRfqStateChanged(BuildContext context, RfqState state) {
    if (state is CartRfqSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.rfqId.isEmpty
                ? 'Quote request submitted successfully.'
                : 'Quote request submitted. RFQ ${state.rfqId}',
          ),
        ),
      );
      context.pop();
      return;
    }
    if (state is CartRfqError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
    }
  }
}
