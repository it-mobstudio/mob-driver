import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
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
  static const incomingOrderPattern = '/driver/trip/:id/offer';
  static String incomingOrder(String id) => '/driver/trip/$id/offer';
  static const orderDetailsPattern = '/driver/trip/:id/details';
  /// [fromTrip]: opened with "View details" on the trip screen — for
  /// reading, without the offer screen's pickup commitment.
  static String orderDetails(String id, {bool fromTrip = false}) =>
      '/driver/trip/$id/details${fromTrip ? '?from=trip' : ''}';
  static const deliveredPattern = '/driver/trip/:id/delivered';
  static String delivered(String id) => '/driver/trip/$id/delivered';
  static const photosPattern = '/driver/trip/:id/photos/:stage';
  static String photos(String id, PhotoStage stage) =>
      '/driver/trip/$id/photos/${stage.wire}';
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
  // Replaces the whole trip stack: there's nothing to go back to.
  context.go(DriverRoutes.delivered(trip.id), extra: trip);
}
