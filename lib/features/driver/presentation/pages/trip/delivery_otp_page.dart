import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/services/push_notification_service.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/fade_slide_in.dart';
import 'package:mob_driver/core/widgets/otp_input.dart';
import 'package:mob_driver/core/widgets/test_mode_otp_hint.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/domain/driver_limits.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

/// Matches the backend's resend throttle (`DELIVERY_OTP_RESEND_THROTTLE_SECONDS`).

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
    setState(() => _resendSeconds = DriverLimits.deliveryOtpResendSeconds);
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
      context.go(AppRoutes.delivered(trip.id), extra: trip);
      return;
    }

    AppHaptics.error();
    _otpKey.currentState?.clear();
    TopSnackBar.show(context,
        message: failure?.message ?? tr('Could not complete the delivery.'),
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
          message: failure?.message ?? tr('Could not resend the OTP.'),
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
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(tr('Verify delivery'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.verified_user_outlined,
                          color: AppColors.blue, size: 27),
                    ),
                    const SizedBox(height: 22),
                    Text(tr('Enter delivery OTP'),
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      [
                        'Payment received. Ask',
                        recipient ?? tr('the customer'),
                        tr('for the {length}-digit code',
                            {'length': DriverLimits.deliveryOtpLength}),
                        phone.isEmpty
                            ? tr('sent to their phone.')
                            : tr('sent to {phone}.', {'phone': phone}),
                      ].join(' '),
                      key: const Key('otp_instructions'),
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 13, height: 1.5),
                    ),
                  ]),
            ),
            const SizedBox(height: 28),
            OtpInput(
              key: _otpKey,
              length: DriverLimits.deliveryOtpLength,
              enabled: !_submitting,
              onChanged: (value) => setState(() => _code = value),
              onCompleted: _submit,
            ),
            if (_debugOtp != null) ...[
              const SizedBox(height: 16),
              TestModeOtpHint(
                otp: _debugOtp!,
                label: tr('Test mode · customer’s OTP is '),
                onFill: () => _otpKey.currentState?.setCode(_debugOtp!),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  tr('The OTP confirms the right person received the order.'),
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              if (_resendSeconds > 0)
                Text(tr('Resend in {seconds}s', {'seconds': _resendSeconds}),
                    key: const Key('otp_resend_countdown'),
                    style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))
              else
                TextButton(
                  key: const Key('otp_resend'),
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? tr('Sending…') : tr('Resend')),
                ),
            ]),
            const SizedBox(height: 28),
            PrimaryButton(
              label: tr('Verify & complete delivery'),
              icon: Icons.arrow_forward_rounded,
              loading: _submitting,
              onPressed: _code.length == DriverLimits.deliveryOtpLength
                  ? () => _submit(_code)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}
