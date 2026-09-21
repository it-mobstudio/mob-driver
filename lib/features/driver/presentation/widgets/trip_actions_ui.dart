import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Route paths for the trip screens. Kept next to the UI helpers so the
/// router, the pages and the notification deep links can't drift apart.
abstract final class DriverRoutes {
  static const dashboard = '/driver';
  static const trips = '/driver/trips';
  static const wallet = '/driver/wallet';
  static const vehicle = '/driver/vehicle';
  static const profile = '/driver/profile';
  static const editProfile = '/driver/profile/edit';
  static const payout = '/driver/payout';
  static const verification = '/driver/verification';

  static const tripPattern = '/driver/trip/:id';
  static String trip(String id) => '/driver/trip/$id';
  static const paymentPattern = '/driver/trip/:id/payment';
  static String payment(String id) => '/driver/trip/$id/payment';
  static const otpPattern = '/driver/trip/:id/otp';
  static String otp(String id) => '/driver/trip/$id/otp';
  static const itemsPattern = '/driver/trip/:id/items';
  static String items(String id) => '/driver/trip/$id/items';
  static const myVehicles = '/driver/vehicle/mine';
  static const newVehicle = '/driver/vehicle/mine/new';
  static const editVehiclePattern = '/driver/vehicle/mine/:id';
  static String editVehicle(String id) => '/driver/vehicle/mine/$id';
}

/// Opens turn-by-turn navigation to a stop in the user's maps app. The plain
/// https Google Maps URL is handled by the Maps app when installed and by the
/// browser otherwise, on both platforms.
Future<bool> openNavigationTo(TripStop stop) {
  if (!stop.hasCoordinates) return Future.value(false);
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${stop.latitude},${stop.longitude}&travelmode=driving',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> callPhone(String? phone) {
  final number = phone?.trim() ?? '';
  if (number.isEmpty) return Future.value(false);
  return launchUrl(Uri(scheme: 'tel', path: number));
}

/// The "Trip completed" confirmation shown once a delivery is finished, then
/// back to the dashboard.
Future<void> showTripCompletedDialog(BuildContext context, Trip trip) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // The tick pops in with a little spring — the moment worth marking.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (_, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: DriverColors.green.withValues(alpha: .12),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: DriverColors.green, size: 38),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Delivery completed',
            style: TextStyle(
                color: DriverColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          trip.isCod
              ? '${formatMoney(trip.totalFare, currency: trip.currency)} collected'
              : 'Trip value ${formatMoney(trip.totalFare, currency: trip.currency)}',
          style: const TextStyle(color: DriverColors.muted, fontSize: 14),
        ),
        if (trip.driverEarning != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const Key('completed_earning'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: DriverColors.green.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                'You earned ${formatMoney(trip.driverEarning, currency: trip.currency)}',
                style: const TextStyle(
                    color: DriverColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${formatDistance(trip.distanceMeters)} · ${trip.drop.address}',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: DriverColors.muted, fontSize: 12),
        ),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 200,
          child: PrimaryButton(
            label: 'Back to home',
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ],
    ),
  );
  if (context.mounted) context.go(DriverRoutes.dashboard);
}
