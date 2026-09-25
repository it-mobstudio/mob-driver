import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/app_runtime/push_notification_service.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/otp_input.dart';
import 'package:m_o_b_demand_side/shared/widgets/test_mode_otp_hint.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Length of the delivery OTP the backend texts the customer.
const int kDeliveryOtpLength = 4;

/// Matches the backend's resend throttle (`DELIVERY_OTP_RESEND_THROTTLE_SECONDS`).
const int kDeliveryOtpResendSeconds = 30;

/// Final step of a COD trip: the customer reads out the OTP the backend sent
/// them when the driver confirmed payment, and entering it completes the
/// delivery — proof the right person received the order.
class DeliveryOtpPage extends StatefulWidget {
  const DeliveryOtpPage({
    super.key,
    required this.tripId,
    this.debugOtp,
    this.freshlySent = false,
  });

  static const routeName = 'DriverDeliveryOtp';

  final String tripId;

  /// Set only when the backend echoes the OTP (non-production).
  final String? debugOtp;

  /// The OTP was sent moments ago (so resend is on cool-down) rather than
  /// this screen being reopened later.
  final bool freshlySent;

  @override
  State<DeliveryOtpPage> createState() => _DeliveryOtpPageState();
}

class _DeliveryOtpPageState extends State<DeliveryOtpPage> {
  final _otpKey = GlobalKey<OtpInputState>();

  Trip? _trip;
  String? _debugOtp;
  String _code = '';
  bool _submitting = false;
  bool _resending = false;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _debugOtp = widget.debugOtp;
    final cubit = context.read<DriverSessionCubit>();
    if (cubit.state.activeTrip?.id == widget.tripId) {
      _trip = cubit.state.activeTrip;
    } else {
      _loadTrip();
    }
    if (widget.freshlySent) _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    final (trip, _) =
        await context.read<DriverSessionCubit>().fetchTrip(widget.tripId);
    if (mounted && trip != null) setState(() => _trip = trip);
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = kDeliveryOtpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  Future<void> _submit(String otp) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final (trip, failure) = await context
        .read<DriverSessionCubit>()
        .complete(widget.tripId, otp: otp);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (trip != null) {
      AppHaptics.success();
      await PushNotificationService.instance.hideOngoingTrip();
      if (!mounted) return;
      await showTripCompletedDialog(context, trip);
      return;
    }

    AppHaptics.error();
    _otpKey.currentState?.clear();
    TopSnackBar.show(context,
        message: failure?.message ?? 'Could not complete the delivery.',
        type: TopSnackBarType.error);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final (sent, failure) = await context
        .read<DriverSessionCubit>()
        .resendDeliveryOtp(widget.tripId);
    if (!mounted) return;
    setState(() => _resending = false);

    if (sent == null) {
      TopSnackBar.show(context,
          message: failure?.message ?? 'Could not resend the OTP.',
          type: TopSnackBarType.error);
      // A 429 means one was sent moments ago — reflect that on the button.
      if (failure?.code == 'OTP_ALREADY_REQUESTED') _startResendTimer();
      return;
    }
    _otpKey.currentState?.clear();
    setState(() => _debugOtp = sent.debugOtp);
    _startResendTimer();
    TopSnackBar.show(context,
        message: sent.message, type: TopSnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final recipient = _trip?.drop.contactName;
    final phone = formatPhone(_trip?.drop.contactPhone);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: DriverColors.ink,
        title: const Text('Verify delivery',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FadeSlideIn(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.verified_user_outlined,
                          color: DriverColors.blue, size: 27),
                    ),
                    const SizedBox(height: 22),
                    const Text('Enter delivery OTP',
                        style: TextStyle(
                            color: DriverColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      [
                        'Payment received. Ask',
                        recipient ?? 'the customer',
                        'for the $kDeliveryOtpLength-digit code',
                        phone.isEmpty
                            ? 'sent to their phone.'
                            : 'sent to $phone.',
                      ].join(' '),
                      key: const Key('otp_instructions'),
                      style: const TextStyle(
                          color: DriverColors.muted, fontSize: 13, height: 1.5),
                    ),
                  ]),
            ),
            const SizedBox(height: 28),
            OtpInput(
              key: _otpKey,
              length: kDeliveryOtpLength,
              enabled: !_submitting,
              onChanged: (value) => setState(() => _code = value),
              onCompleted: _submit,
            ),
            if (_debugOtp != null) ...[
              const SizedBox(height: 16),
              TestModeOtpHint(
                otp: _debugOtp!,
                label: 'Test mode · customer’s OTP is ',
                onFill: () => _otpKey.currentState?.setCode(_debugOtp!),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: DriverColors.muted),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'The OTP confirms the right person received the order.',
                  style: TextStyle(color: DriverColors.muted, fontSize: 11),
                ),
              ),
              if (_resendSeconds > 0)
                Text('Resend in ${_resendSeconds}s',
                    key: const Key('otp_resend_countdown'),
                    style: const TextStyle(
                        color: DriverColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))
              else
                TextButton(
                  key: const Key('otp_resend'),
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Sending…' : 'Resend'),
                ),
            ]),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Verify & complete delivery',
              icon: Icons.arrow_forward_rounded,
              loading: _submitting,
              onPressed: _code.length == kDeliveryOtpLength
                  ? () => _submit(_code)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}
