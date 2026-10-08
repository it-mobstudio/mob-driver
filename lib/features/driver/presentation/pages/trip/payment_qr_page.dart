import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/errors/app_failure.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/centered_message.dart';
import 'package:mob_driver/core/widgets/fade_slide_in.dart';
import 'package:mob_driver/core/widgets/skeleton_shimmer.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/realtime/driver_realtime.dart';
import 'package:mob_driver/features/driver/domain/entities/trip_extras.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// "Scan to pay" for a COD trip.
///
/// In production the code is Razorpay's — a single-use QR for exactly this
/// fare — and Razorpay tells the server when it's paid, so this screen simply
/// waits and moves on to the OTP step by itself (the server texts the customer
/// their delivery OTP the moment the money lands). "Check payment" asks the
/// server to look again right now; it never takes anyone's word for it.
///
/// The local-development stand-in has no such confirmation, so there the
/// driver confirms the money arrived (that tap is what sends the OTP).
class PaymentQrPage extends StatefulWidget {
  const PaymentQrPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<PaymentQrPage> createState() => _PaymentQrPageState();
}

class _PaymentQrPageState extends State<PaymentQrPage> {
  PaymentQr? _qr;
  String? _error;
  bool _loading = true;
  bool _confirming = false;
  bool _leaving = false;

  /// Polls the trip while a verified code is on screen, to notice the payment.
  Timer? _watch;
  StreamSubscription<String>? _paidPush;

  /// Once a second, for the "valid for mm:ss" countdown.
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _watch?.cancel();
    _paidPush?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _startWatching(PaymentQr qr) {
    _watch?.cancel();
    _paidPush?.cancel();
    _tick?.cancel();
    if (qr.paymentIsVerified) {
      // The server says when Razorpay confirms the payment (a push for this
      // trip); the slow timer only covers the push socket being down.
      final cubit = context.read<DriverSessionCubit>();
      _paidPush = cubit.tripChanges
          .where((id) => id == widget.tripId)
          .listen((_) => _checkPaid());
      _watch = Timer.periodic(const Duration(seconds: 5), (_) {
        if (cubit.realtimeStatus.value != RealtimeStatus.live) _checkPaid();
      });
    }
    if (qr.expiresAt != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  /// The customer may have paid while this screen was open; the server marks
  /// the trip paid on Razorpay's say-so, so re-reading it is all that's needed.
  Future<void> _checkPaid() async {
    if (_leaving || _confirming || !mounted) return;
    final trip =
        await context.read<DriverSessionCubit>().refreshTrip(widget.tripId);
    if (!mounted || trip == null) return;
    if (trip.isPaid) _goToOtp(freshlySent: true);
  }

  void _goToOtp({String? debugOtp, required bool freshlySent}) {
    if (_leaving) return;
    _leaving = true;
    _watch?.cancel();
    _paidPush?.cancel();
    _tick?.cancel();
    AppHaptics.success();
    context.pushReplacement(
      AppRoutes.deliveryOtp(widget.tripId),
      extra: {
        'debugOtp': debugOtp,
        // Only a fresh send starts the resend cool-down.
        'freshlySent': freshlySent,
      },
    );
  }

  Future<void> _load() async {
    // An old code's timers must not outlive it (nor tick over the skeleton).
    _watch?.cancel();
    unawaited(_paidPush?.cancel());
    _tick?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    final (qr, failure) =
        await context.read<DriverSessionCubit>().paymentQr(widget.tripId);
    if (!mounted) return;
    if (failure?.code == 'ALREADY_PAID') {
      // The customer already paid (this screen was reopened, or the server
      // found the payment while issuing this code) — only the OTP is left.
      unawaited(context.read<DriverSessionCubit>().refreshTrip(widget.tripId));
      _goToOtp(freshlySent: false);
      return;
    }
    setState(() {
      _qr = qr;
      _error = qr == null
          ? failure?.message ?? tr('Could not load the QR code.')
          : null;
      _loading = false;
      _now = DateTime.now();
    });
    if (qr != null) _startWatching(qr);
  }

  Future<void> _confirmReceived() async {
    final qr = _qr;
    if (qr == null) return;

    // Without a provider that can verify, the driver's word is all there is, so
    // make them mean it. With Razorpay the server checks — no question to ask.
    if (!qr.paymentIsVerified) {
      final amount = formatMoney(qr.amount, currency: qr.currency);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Received {amount}?', {'amount': amount})),
          content: Text(
            tr('Only confirm once the payment has shown up on your phone or the customer’s UPI app. This sends the delivery OTP to the customer.'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('Not yet'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('Yes, received'))),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _confirming = true);
    final (sent, failure) =
        await context.read<DriverSessionCubit>().collectPayment(widget.tripId);
    if (!mounted) return;
    setState(() => _confirming = false);

    if (sent != null || failure?.code == 'ALREADY_PAID') {
      _goToOtp(debugOtp: sent?.debugOtp, freshlySent: sent != null);
      return;
    }
    if (failure?.code == 'PAYMENT_NOT_RECEIVED') {
      // Not an error — the customer just hasn't paid yet.
      AppHaptics.lightTap();
      TopSnackBar.show(context,
          message: failure!.message, type: TopSnackBarType.info);
      return;
    }
    _showError(failure);
  }

  void _showError(AppFailure? failure) => TopSnackBar.show(context,
      message: failure?.message ?? tr('Something went wrong.'),
      type: TopSnackBarType.error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(tr('Collect payment'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: _loading
              ? const _QrSkeleton()
              : _error != null
                  ? CenteredMessage(
                      icon: Icons.qr_code_2_rounded,
                      title: tr('QR code unavailable'),
                      message: _error,
                      actionLabel: tr('Retry'),
                      onAction: _load,
                    )
                  : _body(_qr!),
        ),
      ),
    );
  }

  Widget _body(PaymentQr qr) {
    final expired = qr.isExpiredAt(_now);
    final remaining = qr.expiresAt?.difference(_now);
    return FadeSlideIn(
      offset: 18,
      child: Column(children: [
        const Spacer(),
        Text(tr('Amount to collect'),
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 4),
        Text(formatMoney(qr.amount, currency: qr.currency),
            key: const Key('qr_amount'),
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 38,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x140F2942),
                  blurRadius: 24,
                  offset: Offset(0, 8)),
            ],
          ),
          // White quiet-zone is part of the QR spec; keeping the background
          // white (never themed) is what lets UPI apps read it.
          child: SizedBox(
            width: 240,
            height: 240,
            child: expired
                ? _ExpiredCode(onRefresh: _load)
                : qr.hasImage
                    ? Image.network(
                        qr.imageUrl!,
                        key: const Key('payment_qr_image'),
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Center(
                                child: Icon(Icons.qr_code_2_rounded,
                                    size: 64, color: AppColors.line)),
                        errorBuilder: (_, __, ___) =>
                            _ImageError(onRetry: _load),
                      )
                    : UpiQrCode(
                        key: const Key('payment_qr'),
                        payload: qr.payload ?? ''),
          ),
        ),
        const SizedBox(height: 16),
        if (qr.paymentIsVerified && !expired) ...[
          const _WaitingForPayment(),
          if (remaining != null && !remaining.isNegative) ...[
            const SizedBox(height: 4),
            Text(tr('Code valid for {p0}', {'p0': _mmss(remaining)}),
                key: const Key('qr_countdown'),
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ] else
          Text(
            qr.paymentIsVerified
                ? tr('Get a new code, then ask the customer to scan it.')
                : tr(
                    'Ask the customer to scan this with any UPI app\n(GPay, PhonePe, Paytm…) and pay.'),
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
          ),
        const Spacer(),
        if (qr.paymentIsVerified)
          PrimaryButton(
            key: const Key('check_payment'),
            label: tr('Check payment'),
            icon: Icons.refresh_rounded,
            loading: _confirming,
            onPressed: expired ? null : _confirmReceived,
          )
        else
          PrimaryButton(
            label: tr('Payment received'),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.green,
            loading: _confirming,
            onPressed: _confirmReceived,
          ),
      ]),
    );
  }

  static String _mmss(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// While a Razorpay code is on screen: the screen is doing the waiting, so the
/// driver doesn't have to.
class _WaitingForPayment extends StatelessWidget {
  const _WaitingForPayment();

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.orange),
          const SizedBox(width: 6),
          Text(tr('Waiting for the customer’s payment'),
              key: const Key('qr_waiting'),
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text(tr('Ask them to scan with any UPI app. This moves on by itself.'),
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4)),
      ]);
}

class _ExpiredCode extends StatelessWidget {
  const _ExpiredCode({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.timer_off_outlined, size: 44, color: AppColors.muted),
        const SizedBox(height: 10),
        Text(tr('This code has expired'),
            key: const Key('qr_expired'),
            style: TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextButton(
          key: const Key('qr_new_code'),
          onPressed: onRefresh,
          child: Text(tr('Get a new code')),
        ),
      ]);
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.broken_image_outlined, size: 40, color: AppColors.muted),
        const SizedBox(height: 8),
        Text(tr('Couldn’t load the code'),
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
        TextButton(onPressed: onRetry, child: Text(tr('Try again'))),
      ]);
}

/// The QR screen's shape while the code loads.
class _QrSkeleton extends StatelessWidget {
  const _QrSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonShimmer(
        child: Column(children: [
          Spacer(),
          SkeletonBlock(width: 120, height: 14, radius: 6),
          SizedBox(height: 10),
          SkeletonBlock(width: 200, height: 40, radius: 10),
          SizedBox(height: 22),
          SkeletonBlock(width: 276, height: 276, radius: 20),
          Spacer(),
          SkeletonBlock(height: 50, radius: 13),
        ]),
      );
}

/// The QR a customer scans to pay. The white background is not decoration:
/// a QR needs a light quiet zone to be readable, so it's fixed white rather
/// than following any theme.
class UpiQrCode extends StatelessWidget {
  const UpiQrCode({super.key, required this.payload, this.size = 240});

  /// The `upi://pay?...` deep link the backend generated for this trip.
  final String payload;
  final double size;

  @override
  Widget build(BuildContext context) => QrImageView(
        data: payload,
        size: size,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
}
