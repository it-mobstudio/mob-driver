import 'package:mob_driver/features/driver/domain/entities/trip.dart';

/// Every path in the app, in one place, so the router, the screens and
/// notification deep links can't drift apart.
///
/// `…Pattern` is what the router matches; the method of the same name builds
/// a concrete link to navigate to.
abstract final class AppRoutes {
  // Signed out
  static const login = '/login';
  static const otp = '/login/otp';

  // The shell (tabs reached from the dashboard and the profile menu)
  static const dashboard = '/driver';
  static const trips = '/driver/trips';
  static const wallet = '/driver/wallet';
  static const vehicle = '/driver/vehicle';
  static const profile = '/driver/profile';

  // Account
  static const editProfile = '/driver/profile/edit';
  static const payout = '/driver/payout';
  static const verification = '/driver/verification';

  // Vehicles (`new` must be matched before `:id`)
  static const myVehicles = '/driver/vehicle/mine';
  static const newVehicle = '/driver/vehicle/mine/new';
  static const editVehiclePattern = '/driver/vehicle/mine/:id';
  static String editVehicle(String id) => '/driver/vehicle/mine/$id';

  // A trip
  static const tripPattern = '/driver/trip/:id';
  static String trip(String id) => '/driver/trip/$id';

  static const incomingOrderPattern = '/driver/trip/:id/offer';
  static String incomingOrder(String id) => '/driver/trip/$id/offer';

  /// [fromTrip]: opened with "View details" on the trip screen — for
  /// reading, without the offer screen's pickup commitment.
  static const orderDetailsPattern = '/driver/trip/:id/details';
  static String orderDetails(String id, {bool fromTrip = false}) =>
      '/driver/trip/$id/details${fromTrip ? '?from=trip' : ''}';

  static const photosPattern = '/driver/trip/:id/photos/:stage';
  static String photos(String id, PhotoStage stage) =>
      '/driver/trip/$id/photos/${stage.wire}';

  static const itemsPattern = '/driver/trip/:id/items';
  static String items(String id, {String? stopId}) =>
      '/driver/trip/$id/items${stopId == null ? '' : '?stop=$stopId'}';

  static const stopPattern = '/driver/trip/:id/stops/:stop';
  static String stop(String id, String stopId) =>
      '/driver/trip/$id/stops/$stopId';

  static const paymentPattern = '/driver/trip/:id/payment';
  static String payment(String id) => '/driver/trip/$id/payment';

  static const deliveryOtpPattern = '/driver/trip/:id/otp';
  static String deliveryOtp(String id) => '/driver/trip/$id/otp';

  static const deliveredPattern = '/driver/trip/:id/delivered';
  static String delivered(String id) => '/driver/trip/$id/delivered';
}
