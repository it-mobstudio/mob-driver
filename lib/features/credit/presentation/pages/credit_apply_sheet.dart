import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/business_segment_entity.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/bloc/credit_bloc.dart';

Future<void> showCreditApplySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => BlocProvider(
      create: (_) => sl<CreditBloc>()..add(CreditSegmentsRequested()),
      child: const _CreditApplySheet(),
    ),
  );
}

class _CreditApplySheet extends StatefulWidget {
  const _CreditApplySheet();

  @override
  State<_CreditApplySheet> createState() => _CreditApplySheetState();
}

class _CreditApplySheetState extends State<_CreditApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  final _gst = TextEditingController();

  List<BusinessSegmentEntity> _segments = const [];
  bool _segmentsLoading = true;
  String? _segmentsError;
  BusinessSegmentEntity? _selectedSegment;
  bool _submitting = false;

  @override
  void dispose() {
    _businessName.dispose();
    _phone.dispose();
    _gst.dispose();
    super.dispose();
  }

  void _submit(BuildContext blocContext) {
    if (_selectedSegment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business segment')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    blocContext.read<CreditBloc>().add(
          CreditApplyRequested(
            businessName: _businessName.text.trim(),
            gst: _gst.text.trim().toUpperCase(),
            phoneNumber: _phone.text.trim(),
            businessSegment: _selectedSegment!.category,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * .60;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<CreditBloc, CreditState>(
      listener: (context, state) {
        switch (state) {
          case CreditSegmentsLoading():
            setState(() {
              _segmentsLoading = true;
              _segmentsError = null;
            });
          case CreditSegmentsLoaded(segments: final segments):
            setState(() {
              _segmentsLoading = false;
              _segments = segments;
            });
          case CreditSegmentsError(message: final message):
            setState(() {
              _segmentsLoading = false;
              _segmentsError = message;
            });
          case CreditApplySubmitting():
            setState(() => _submitting = true);
          case CreditApplySubmitted():
            setState(() => _submitting = false);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your mobCREDIT request has been submitted'),
              ),
            );
          case CreditApplyError(message: final message):
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          case CreditInitial():
            break;
        }
      },
      builder: (context, state) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SizedBox(
            height: screenHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Material(
                      color: Colors.white,
                      child: SizedBox(
                        height: sheetHeight,
                        child: SafeArea(
                          top: false,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Apply for mobCREDIT',
                                          style: TextStyle(
                                            color: Color(0xFF0A243F),
                                            fontSize: 18,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 1.44,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        _CreditApplyTextField(
                                          controller: _businessName,
                                          label: 'Business name*',
                                          validator: (value) =>
                                              (value == null ||
                                                      value.trim().isEmpty)
                                                  ? 'Business name is required'
                                                  : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _CreditApplyTextField(
                                          controller: _phone,
                                          label: 'Business mobile (for OTP)*',
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              10,
                                            ),
                                          ],
                                          validator: (value) {
                                            final digits = value?.trim() ?? '';
                                            if (digits.length != 10) {
                                              return 'Enter a valid 10-digit mobile number';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        _CreditApplyTextField(
                                          controller: _gst,
                                          label: 'GSTIN*',
                                          textCapitalization:
                                              TextCapitalization.characters,
                                          validator: (value) => (value ==
                                                      null ||
                                                  value.trim().length < 15)
                                              ? 'Enter a valid 15-character GSTIN'
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        _segmentDropdown(),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    24,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _submitting
                                          ? null
                                          : () => _submit(context),
                                      style: ElevatedButton.styleFrom(
                                        elevation: 0,
                                        backgroundColor: const Color(
                                          0xFF0360E5,
                                        ),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: const Color(
                                          0xFF8FB8F5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              'Send request',
                                              style: _sheetTextStyle(
                                                color: Colors.white,
                                                size: 14,
                                                weight: FontWeight.w600,
                                                height: 21 / 14,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: sheetHeight + 16,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: SvgPicture.asset(
                        'assets/images/close.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _segmentDropdown() {
    if (_segmentsError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _segmentsError!,
                style: _sheetTextStyle(
                  color: Colors.red,
                  size: 14,
                  weight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<CreditBloc>().add(CreditSegmentsRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<BusinessSegmentEntity>(
      initialValue: _selectedSegment,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF0A243F),
        size: 24,
      ),
      decoration: _applyInputDecoration('Business segment*'),
      hint: _segmentsLoading
          ? Text('Loading...', style: _inputTextStyle)
          : Text('Select business segment', style: _inputTextStyle),
      selectedItemBuilder: (context) => _segments
          .map(
            (segment) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                segment.categoryName,
                style: _inputTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      items: _segments
          .map(
            (segment) => DropdownMenuItem(
              value: segment,
              child: Text(
                segment.categoryName,
                style: _inputTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _segmentsLoading
          ? null
          : (value) => setState(() => _selectedSegment = value),
    );
  }
}

class _CreditApplyTextField extends StatelessWidget {
  const _CreditApplyTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: _inputTextStyle,
      decoration: _applyInputDecoration(label),
      validator: validator,
    );
  }
}

InputDecoration _applyInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: _sheetTextStyle(
      color: const Color(0xFF767C8F),
      size: 11,
      weight: FontWeight.w500,
      height: 1.27,
    ),
    floatingLabelStyle: _sheetTextStyle(
      color: const Color(0xFF767C8F),
      size: 11,
      weight: FontWeight.w500,
      height: 1.27,
    ),
    contentPadding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    constraints: const BoxConstraints(minHeight: 48),
    border: _inputBorder(),
    enabledBorder: _inputBorder(),
    focusedBorder: _inputBorder(color: const Color(0xFF0360E5)),
    errorBorder: _inputBorder(color: const Color(0xFFE54848)),
    focusedErrorBorder: _inputBorder(color: const Color(0xFFE54848)),
  );
}

OutlineInputBorder _inputBorder({Color color = const Color(0xFFDFE4EC)}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}

TextStyle get _inputTextStyle => _sheetTextStyle(
      color: const Color(0xFF0A243F),
      size: 14,
      weight: FontWeight.w500,
      height: 1.43,
    );

TextStyle _sheetTextStyle({
  required Color color,
  required double size,
  required FontWeight weight,
  required double height,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );
}
