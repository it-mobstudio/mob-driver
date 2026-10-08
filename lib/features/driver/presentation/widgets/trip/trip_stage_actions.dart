import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/errors/app_failure.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/services/push_notification_service.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/swipe_button.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/domain/trip_reasons.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';

/// Moving a trip along its stages — reached pickup, pickup order, each
/// in-between stop, deliver order — and everything each step asks for first
/// (photos, the item check, the payment, the customer's OTP). Shared by the
/// trip screen and the order details, so both offer the same next step and
/// take it the same way.
mixin TripStageActions<T extends StatefulWidget> on State<T> {
  DriverSessionCubit get stageCubit;
  String get stageTripId;

  /// The screen's own copy of the trip.
  Trip? get stageTrip;

  /// The server's answer after a step.
  void onStageTrip(Trip trip);

  /// The trip as it stands now: the live one while it's the driver's active
  /// trip, else the screen's copy.
  Trip? get latestTrip {
    final live = stageCubit.state.activeTrip;
    return live != null && live.id == stageTripId ? live : stageTrip;
  }

  Future<void> _run(
    Future<(Trip?, AppFailure?)> Function() action, {
    void Function(Trip trip)? onSuccess,
  }) async {
    final (trip, failure) = await action();
    if (!mounted) return;
    if (trip == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? tr('Something went wrong.'),
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.success();
    onStageTrip(trip);
    onSuccess?.call(trip);
  }

  Future<void> reachedPickup() => _run(() => stageCubit.arrive(stageTripId));

  Future<void> reachedStop(TripWaypoint stop) =>
      _run(() => stageCubit.arriveAtStop(stageTripId, stop.id));

  /// The stop's own screen: its photos, items and checks, then "done".
  Future<void> workStop(TripWaypoint stop) async {
    final done = await context.push<bool>(AppRoutes.stop(stageTripId, stop.id));
    if (done == true && mounted) {
      TopSnackBar.show(context,
          message: '${stop.label} done', type: TopSnackBarType.success);
    }
  }

  /// Gets the photos [stage] still owes; true once every one is in. Opens the
  /// photo screen — a screen that shows the photo slots itself can point at
  /// them instead.
  Future<bool> ensurePhotos(PhotoStage stage) async {
    await context.push<bool>(AppRoutes.photos(stageTripId, stage));
    return mounted && (latestTrip?.hasPhotos(stage) ?? false);
  }

  /// "Pickup order": the pickup photos the order asks for, then the start.
  Future<void> pickupOrder() async {
    final trip = latestTrip;
    if (trip == null) return;
    if (!trip.hasPhotos(PhotoStage.pickup) &&
        !await ensurePhotos(PhotoStage.pickup)) {
      return;
    }
    await _run(() => stageCubit.startTrip(stageTripId));
  }

  /// "Deliver order": walks the driver through whatever the drop still
  /// needs, in order — the item check, the delivery photos, the payment, the
  /// customer's OTP — or confirms a prepaid handover when nothing's left.
  Future<void> deliverOrder() async {
    var trip = latestTrip;
    if (trip == null) return;
    if (trip.needsItemVerification) {
      await context.push(AppRoutes.items(trip.id));
      trip = latestTrip;
      if (!mounted || trip == null || trip.needsItemVerification) return;
    }
    if (trip.needsDeliveryPhotos) {
      if (!await ensurePhotos(PhotoStage.delivery)) return;
      trip = latestTrip!;
    }
    if (!mounted) return;
    if (trip.needsPaymentCollection) {
      await _collectPayment(trip);
    } else if (trip.needsDeliveryOtp) {
      await _openDeliveryOtp(trip);
    } else {
      await _completePrepaid();
    }
  }

  /// Cash on delivery: ask how the customer paid. Cash (or any way the
  /// company can't see) is taken on the driver's word — the fare is debited
  /// from their wallet for the company to collect — and goes straight to the
  /// customer's OTP. Otherwise the scan-to-pay code is shown.
  Future<void> _collectPayment(Trip trip) async {
    final amount = formatMoney(trip.totalFare, currency: trip.currency);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentChoiceSheet(amount: amount),
    );
    if (!mounted || choice == null) return;
    if (choice == 'qr') {
      await context.push(AppRoutes.payment(trip.id));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Collected {amount}?', {'amount': amount})),
        content: Text(tr(
            'Confirm only once you have the money in hand. It’s added to what you owe the company (taken from your wallet), and the customer gets their delivery OTP.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Not yet'))),
          TextButton(
              key: const Key('pay_cash_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Yes, collected'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final (sent, failure) =
        await stageCubit.collectPayment(trip.id, method: 'cash');
    if (!mounted) return;
    if (sent != null || failure?.code == 'ALREADY_PAID') {
      AppHaptics.success();
      await context.push(AppRoutes.deliveryOtp(trip.id),
          extra: {'debugOtp': sent?.debugOtp, 'freshlySent': sent != null});
      return;
    }
    AppHaptics.error();
    TopSnackBar.show(context,
        message:
            failure?.message ?? tr('Couldn’t record the payment. Try again.'),
        type: TopSnackBarType.error);
  }

  /// A COD trip's OTP went out with the payment; a prepaid one is texted to
  /// the customer now, as the driver reaches this step.
  Future<void> _openDeliveryOtp(Trip trip) async {
    if (trip.isCod) {
      await context.push(AppRoutes.deliveryOtp(trip.id));
      return;
    }
    final (sent, failure) = await stageCubit.resendDeliveryOtp(trip.id);
    if (!mounted) return;
    // Sent moments ago (429) is fine — the customer already has a code.
    if (sent == null && failure?.code != 'OTP_ALREADY_REQUESTED') {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? tr('Couldn’t send the OTP.'),
          type: TopSnackBarType.error);
      return;
    }
    await context.push(AppRoutes.deliveryOtp(trip.id), extra: {
      'debugOtp': sent?.debugOtp,
      'freshlySent': true,
    });
  }

  Future<void> _completePrepaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Complete delivery?')),
        content:
            Text(tr('Confirm the order has been handed over to the customer.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Not yet'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Complete'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => stageCubit.complete(stageTripId),
      onSuccess: (trip) async {
        await PushNotificationService.instance.hideOngoingTrip();
        if (mounted) context.go(AppRoutes.delivered(trip.id), extra: trip);
      },
    );
  }

  /// Asks why, then hands the order back to the company and goes home.
  Future<void> cancelTrip() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => stageCubit.cancel(stageTripId, reason),
      onSuccess: (_) async {
        await PushNotificationService.instance.hideOngoingTrip();
        if (!mounted) return;
        TopSnackBar.show(context,
            message: tr('Trip cancelled'), type: TopSnackBarType.info);
        context.go(AppRoutes.dashboard);
      },
    );
  }

  /// The swipe for whatever [trip]'s stage asks for next. Cross-fades as the
  /// stage changes rather than swapping, so it doesn't flicker as the trip
  /// moves along. Nothing once the trip is over.
  Widget stageSwipe(Trip trip,
          {required bool busy, Key swipeKey = const Key('trip_swipe')}) =>
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(
              '${trip.status.wire}|${trip.nextStop?.id}|${trip.nextStop?.status.wire}'),
          child: switch (trip.status) {
            TripStatus.assigned => SwipeButton(
                key: swipeKey,
                label: tr('Reached pickup'),
                loading: busy,
                onConfirmed: reachedPickup,
              ),
            TripStatus.arrivedAtPickup => SwipeButton(
                key: swipeKey,
                label: tr('Pickup order'),
                loading: busy,
                onConfirmed: pickupOrder,
              ),
            TripStatus.inProgress => switch (trip.nextStop) {
                // An in-between stop comes first: reach it, then work it.
                final stop? when stop.status == WaypointStatus.pending =>
                  SwipeButton(
                    key: swipeKey,
                    label: tr('Reached {p0}', {'p0': stop.label.toLowerCase()}),
                    loading: busy,
                    onConfirmed: () => reachedStop(stop),
                  ),
                final stop? => SwipeButton(
                    key: swipeKey,
                    label: stop.isPickup
                        ? tr('Collect items')
                        : tr('Deliver items'),
                    loading: busy,
                    onConfirmed: () => workStop(stop),
                  ),
                null => SwipeButton(
                    key: swipeKey,
                    label: tr('Deliver order'),
                    loading: busy,
                    onConfirmed: deliverOrder,
                  ),
              },
            _ => const SizedBox.shrink(),
          },
        ),
      );
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _choice;
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String? get _reason {
    if (_choice == null) return null;
    if (_choice != TripReasons.other) return _choice;
    final text = _other.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        // A Material (not a painted Container): the radio rows' ink ripples
        // render on the nearest Material, and an opaque box in between hides
        // them — and trips a debug assertion.
        child: Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 18, 20, 20 + MediaQuery.paddingOf(context).bottom),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Why are you cancelling?'),
                      style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(tr('The order goes back to the company. You can’t cancel once the delivery has started.'),
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12.5, height: 1.4)),
                  const SizedBox(height: 10),
                  RadioGroup<String>(
                    groupValue: _choice,
                    onChanged: (v) => setState(() => _choice = v),
                    child: Column(children: [
                      for (final reason in TripReasons.cancel)
                        RadioListTile<String>(
                          key: Key('cancel_reason_$reason'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: reason,
                          title: Text(tr(reason)),
                        ),
                    ]),
                  ),
                  if (_choice == TripReasons.other)
                    TextField(
                      key: const Key('cancel_other_text'),
                      controller: _other,
                      maxLength: 255,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          hintText: tr('Tell us what happened')),
                    ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: tr('Cancel trip'),
                    color: AppColors.red,
                    onPressed: _reason == null
                        ? null
                        : () => Navigator.pop(context, _reason),
                  ),
                ]),
          ),
        ),
      );
}

/// "How did the customer pay?" — cash straight to the driver, or the QR code.
class _PaymentChoiceSheet extends StatelessWidget {
  const _PaymentChoiceSheet({required this.amount});
  final String amount;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 18),
              Text(tr('Collect payment'),
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(amount,
                  key: const Key('pay_amount'),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6)),
              const SizedBox(height: 4),
              Text(tr('How did the customer pay?'),
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _PaymentOption(
                key: const Key('pay_cash'),
                icon: Icons.payments_outlined,
                color: AppColors.green,
                title: tr('Cash / paid another way'),
                subtitle: tr(
                    'They paid you directly. You’ll give it to the company — it’s taken from your wallet.'),
                onTap: () => Navigator.pop(context, 'cash'),
              ),
              const SizedBox(height: 10),
              _PaymentOption(
                key: const Key('pay_qr'),
                icon: Icons.qr_code_2_rounded,
                color: AppColors.blue,
                title: tr('Show QR code'),
                subtitle: tr(
                    'The customer scans and pays by UPI — confirmed automatically.'),
                onTap: () => Navigator.pop(context, 'qr'),
              ),
            ]),
      );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.line)),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(subtitle,
                            style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12.5,
                                height: 1.35)),
                      ]),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      );
}
