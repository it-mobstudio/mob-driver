import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/business_segment_entity.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/bloc/credit_bloc.dart';
import 'package:m_o_b_demand_side/shared/validators/gst_validator.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

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
  final _businessNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _gstFocus = FocusNode();

  List<BusinessSegmentEntity> _segments = const [];
  bool _segmentsLoading = true;
  String? _segmentsError;
  BusinessSegmentEntity? _selectedSegment;
  bool _submitting = false;

  @override
  void dispose() {
    _businessNameFocus.dispose();
    _phoneFocus.dispose();
    _gstFocus.dispose();
    _businessName.dispose();
    _phone.dispose();
    _gst.dispose();
    super.dispose();
  }

  void _submit(BuildContext blocContext) {
    FocusScope.of(context).unfocus();
    if (_selectedSegment == null) {
      TopSnackBar.show(
        context,
        message: 'Please select a business segment',
        type: TopSnackBarType.error,
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
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final buttonBottomPadding = bottomPadding > 0 ? bottomPadding + 4 : 24.0;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<CreditBloc, CreditState>(
      listener: (context, state) {
        switch (state) {
          case CreditSegmentsLoading():
            setState(() {
              _segmentsLoading = true;
            });
          case CreditSegmentsLoaded(segments: final segments):
            setState(() {
              _segmentsLoading = false;
              _segments = segments;
              _segmentsError = null;
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
            TopSnackBar.show(
              context,
              message: 'Your mobCREDIT request has been submitted',
              type: TopSnackBarType.success,
            );
            Navigator.of(context).pop();
          case CreditApplyError(message: final message):
            setState(() => _submitting = false);
            TopSnackBar.show(
              context,
              message: message,
              type: TopSnackBarType.error,
            );
          case CreditInitial():
          case CreditHistoryLoading():
          case CreditHistoryLoaded():
          case CreditHistoryError():
            break;
        }
      },
      builder: (context, state) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final desiredSheetHeight = math.max(560.0, screenHeight * .75);
              final maximumSheetHeight = math.max(
                0.0,
                availableHeight - topPadding - 72,
              );
              final sheetHeight = math
                  .min(desiredSheetHeight, maximumSheetHeight)
                  .clamp(0.0, availableHeight)
                  .toDouble();

              return SizedBox(
                height: availableHeight,
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      keyboardDismissBehavior:
                                          ScrollViewKeyboardDismissBehavior
                                              .onDrag,
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
                                          AppTextField(
                                            controller: _businessName,
                                            focusNode: _businessNameFocus,
                                            label: 'Business name*',
                                            hintText: 'Business name*',
                                            showClearButton: false,
                                            textInputAction:
                                                TextInputAction.next,
                                            onFieldSubmitted: (_) =>
                                                _phoneFocus.requestFocus(),
                                            validator: (value) => (value ==
                                                        null ||
                                                    value.trim().isEmpty)
                                                ? 'Business name is required'
                                                : null,
                                          ),
                                          const SizedBox(height: 20),
                                          AppTextField(
                                            controller: _phone,
                                            focusNode: _phoneFocus,
                                            label: 'Business mobile (for OTP)*',
                                            hintText:
                                                'Business mobile (for OTP)*',
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.next,
                                            onFieldSubmitted: (_) =>
                                                _gstFocus.requestFocus(),
                                            showClearButton: false,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                            ],
                                            validator: (value) {
                                              final digits =
                                                  value?.trim() ?? '';
                                              if (digits.length != 10) {
                                                return 'Enter a valid 10-digit mobile number';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          AppTextField(
                                            controller: _gst,
                                            label: 'GSTIN*',
                                            hintText: 'GSTIN*',
                                            focusNode: _gstFocus,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) =>
                                                FocusScope.of(context)
                                                    .unfocus(),
                                            showClearButton: false,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            inputFormatters: gstInputFormatters,
                                            validator: requiredGstValidator,
                                          ),
                                          const SizedBox(height: 20),
                                          _segmentDropdown(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      buttonBottomPadding,
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
                                          disabledBackgroundColor:
                                              const Color(0xFF8FB8F5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
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
                    if (availableHeight >= 72)
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _segmentDropdown() {
    if (_segmentsError != null) {
      return InputDecorator(
        decoration: appTextFieldDecoration(
          label: 'Business segment*',
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _segmentsError!,
                style: AppTextFieldStyles.inputText.copyWith(
                  color: AppTextFieldColors.error,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _segmentsLoading = true;
                  _segmentsError = null;
                });
                context.read<CreditBloc>().add(CreditSegmentsRequested());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final dropdownWidth = MediaQuery.sizeOf(context).width - 32;
    return PopupMenuButton<BusinessSegmentEntity>(
      offset: const Offset(0, 58),
      constraints: BoxConstraints(
        maxHeight: 260,
        minWidth: dropdownWidth,
        maxWidth: dropdownWidth,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onOpened: () => FocusScope.of(context).unfocus(),
      onSelected: (value) {
        FocusScope.of(context).unfocus();
        setState(() => _selectedSegment = value);
      },
      itemBuilder: (context) => _segments.map((segment) {
        return PopupMenuItem<BusinessSegmentEntity>(
          value: segment,
          child: Text(
            segment.categoryName,
            style: AppTextFieldStyles.inputText,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      child: InputDecorator(
        decoration: appTextFieldDecoration(
          label: 'Business segment*',
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _segmentsLoading
                    ? 'Loading...'
                    : (_selectedSegment?.categoryName ??
                        'Select business segment'),
                style: AppTextFieldStyles.inputText,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            RotatedBox(
              quarterTurns: 1,
              child: SvgPicture.asset(
                'assets/images/Arrow.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF0A243F),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
