import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_styles.dart';
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: Colors.white,
          child: BlocConsumer<CreditBloc, CreditState>(
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
                      content: Text(
                        'Your mobCREDIT request has been submitted',
                      ),
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
              return SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Apply for mobCREDIT',
                                style: AppTextStyles.screenTitle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _businessName,
                          decoration: AppFormFieldStyles.outlinedDecoration(
                            'Business name*',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Business name is required'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: AppFormFieldStyles.outlinedDecoration(
                            'Business mobile (for OTP)*',
                          ),
                          validator: (value) {
                            final digits = value?.trim() ?? '';
                            if (digits.length != 10) {
                              return 'Enter a valid 10-digit mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _gst,
                          textCapitalization: TextCapitalization.characters,
                          decoration: AppFormFieldStyles.outlinedDecoration(
                            'GSTIN*',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 15)
                                  ? 'Enter a valid 15-character GSTIN'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        _segmentDropdown(),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: AppComponentStyles.buttonHeight,
                          child: ElevatedButton(
                            onPressed:
                                _submitting ? null : () => _submit(context),
                            style: AppComponentStyles.primaryButton,
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
                                    style: AppTextStyles.buttonLabel,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
                style: AppTextStyles.body14.copyWith(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => context
                  .read<CreditBloc>()
                  .add(CreditSegmentsRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<BusinessSegmentEntity>(
      initialValue: _selectedSegment,
      isExpanded: true,
      decoration: AppFormFieldStyles.outlinedDecoration('Business segment*'),
      hint: _segmentsLoading
          ? Text('Loading…', style: AppTextStyles.inputText)
          : Text('Select business segment', style: AppTextStyles.inputText),
      items: _segments
          .map(
            (segment) => DropdownMenuItem(
              value: segment,
              child: Text(
                segment.categoryName,
                style: AppTextStyles.inputText,
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
