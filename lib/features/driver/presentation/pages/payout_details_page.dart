import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

final _upiPattern = RegExp(r'^[A-Za-z0-9._-]{2,}@[A-Za-z][A-Za-z0-9.-]{1,}$');
final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

enum _Method { upi, bank }

/// Where the company should send the driver's earnings: a UPI id or a bank
/// account. The account number is never shown back — only its last four digits.
class PayoutDetailsPage extends StatefulWidget {
  const PayoutDetailsPage({super.key});

  static const routeName = 'DriverPayoutDetails';
  static const routePath = DriverRoutes.payout;

  @override
  State<PayoutDetailsPage> createState() => _PayoutDetailsPageState();
}

class _PayoutDetailsPageState extends State<PayoutDetailsPage> {
  late final PayoutDetails _current =
      context.read<DriverSessionCubit>().state.profile?.payout ??
          const PayoutDetails();
  late _Method _method =
      _current.upiId == null && _current.bankAccountLast4 != null
          ? _Method.bank
          : _Method.upi;

  late final _upi = TextEditingController(text: _current.upiId ?? '');
  late final _holder =
      TextEditingController(text: _current.bankAccountHolder ?? '');
  final _account = TextEditingController();
  late final _ifsc = TextEditingController(text: _current.bankIfsc ?? '');

  bool _submitted = false;
  bool _saving = false;
  String? _serverError;

  @override
  void dispose() {
    for (final c in [_upi, _holder, _account, _ifsc]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _upiError => _upiPattern.hasMatch(_upi.text.trim())
      ? null
      : 'Enter a valid UPI id, like name@bank.';

  String? get _holderError => _holder.text.trim().length < 2
      ? 'Enter the account holder’s name.'
      : null;

  // Blank is fine when an account is already saved: the number is never sent
  // back, so leaving it empty means "keep the one I have".
  String? get _accountError {
    if (_account.text.isEmpty && _current.bankAccountLast4 != null) return null;
    final ok = _account.text.length >= 9 && _account.text.length <= 18;
    return ok ? null : 'Enter the account number (9–18 digits).';
  }

  String? get _ifscError =>
      _ifscPattern.hasMatch(_ifsc.text.trim().toUpperCase())
          ? null
          : 'Enter a valid IFSC code, like HDFC0001234.';

  bool get _valid => _method == _Method.upi
      ? _upiError == null
      : _holderError == null && _accountError == null && _ifscError == null;

  String? _shown(String? error) => _submitted ? error : null;

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_valid) {
      AppHaptics.error();
      return;
    }
    setState(() => _saving = true);
    final update = _method == _Method.upi
        ? ProfileUpdate(payoutUpiId: _upi.text.trim())
        : ProfileUpdate(
            bankAccountHolder: _holder.text.trim(),
            // The backend needs the three bank fields as a set, so a kept
            // account can't be re-saved without its number.
            bankAccountNumber: _account.text.isEmpty ? null : _account.text,
            bankIfsc: _ifsc.text.trim().toUpperCase(),
          );
    final failure =
        await context.read<DriverSessionCubit>().updateProfile(update);
    if (!mounted) return;
    setState(() => _saving = false);
    if (failure != null) {
      AppHaptics.error();
      setState(() => _serverError = failure.message);
      return;
    }
    AppHaptics.success();
    TopSnackBar.show(context,
        message: 'Payout details saved.', type: TopSnackBarType.success);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DriverColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: DriverColors.ink,
          title: const Text('Payout details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              const Text(
                  'This is where your company sends your earnings. Add a UPI id or a bank account.',
                  style: TextStyle(
                      color: DriverColors.muted, fontSize: 13.5, height: 1.4)),
              if (_current.summary != null) ...[
                const SizedBox(height: 14),
                InfoBanner(
                  key: const Key('payout_current'),
                  text: 'Currently: ${_current.summary}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: DriverColors.green,
                ),
              ],
              const SizedBox(height: 18),
              SegmentedButton<_Method>(
                key: const Key('payout_method'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _Method.upi, label: Text('UPI')),
                  ButtonSegment(
                      value: _Method.bank, label: Text('Bank account')),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() {
                  _method = s.first;
                  _serverError = null;
                }),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_method),
                  child: _method == _Method.upi ? _upiForm() : _bankForm(),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _serverError == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: InfoBanner(
                          key: const Key('payout_error'),
                          text: _serverError!,
                          icon: Icons.error_outline_rounded,
                          color: DriverColors.red,
                        ),
                      ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                key: const Key('payout_save'),
                label: 'Save',
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      );

  Widget _upiForm() => DriverTextField(
        key: const Key('field_upi'),
        controller: _upi,
        label: 'UPI id',
        hint: 'name@okhdfc',
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        enabled: !_saving,
        errorText: _shown(_upiError),
        onChanged: (_) => setState(() {}),
      );

  Widget _bankForm() => Column(children: [
        DriverTextField(
          key: const Key('field_bank_holder'),
          controller: _holder,
          label: 'Account holder name',
          textCapitalization: TextCapitalization.words,
          enabled: !_saving,
          errorText: _shown(_holderError),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        DriverTextField(
          key: const Key('field_bank_account'),
          controller: _account,
          label: 'Account number',
          helper: _current.bankAccountLast4 == null
              ? null
              : 'Saved account ends ${_current.bankAccountLast4}. Leave blank to keep it.',
          keyboardType: TextInputType.number,
          inputFormatters: digitsOnly(18),
          enabled: !_saving,
          errorText: _shown(_accountError),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        DriverTextField(
          key: const Key('field_bank_ifsc'),
          controller: _ifsc,
          label: 'IFSC code',
          hint: 'HDFC0001234',
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          textInputAction: TextInputAction.done,
          enabled: !_saving,
          errorText: _shown(_ifscError),
          onChanged: (_) => setState(() {}),
        ),
      ]);
}
