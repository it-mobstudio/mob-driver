/// Paths of the delivery backend's driver API, relative to
/// `AppConfig.apiBaseUrl` (`…/api/v1/`).
abstract final class DriverEndpoints {
  // Profile and documents
  static const me = '/driver/me';
  static const photo = '/driver/me/photo';
  static const aadhaar = '/driver/me/kyc/aadhar';
  static const licence = '/driver/me/kyc/dl';
  static const police = '/driver/me/kyc/police';
  static const stats = '/driver/stats';

  // Duty
  static const dutyVehicles = '/driver/vehicles';
  static const startDuty = '/driver/duty/start';
  static const endDuty = '/driver/duty/end';
  static const location = '/driver/location';

  // Wallet
  static const wallet = '/driver/wallet';
  static const walletTransactions = '/driver/wallet/transactions';

  // Trips
  static const trips = '/driver/trips';
  static const activeTrip = '/driver/trips/active';
  static String trip(String id) => '/driver/trips/$id';
  static String navigation(String id) => '/driver/trips/$id/navigation';
  static String arrive(String id) => '/driver/trips/$id/arrive';
  static String start(String id) => '/driver/trips/$id/start';
  static String complete(String id) => '/driver/trips/$id/complete';
  static String cancel(String id) => '/driver/trips/$id/cancel';
  static String paymentQr(String id) => '/driver/trips/$id/payment/qr';
  static String collectPayment(String id) =>
      '/driver/trips/$id/payment/collect';
  static String resendDeliveryOtp(String id) =>
      '/driver/trips/$id/delivery-otp/resend';

  /// [stage] is `pickup` or `delivery`.
  static String tripPhoto(String id, String stage) =>
      '/driver/trips/$id/$stage-photo';
  static String tripPhotoById(String id, String photoId) =>
      '/driver/trips/$id/photos/$photoId';
  static String verifyItem(String id, String itemId) =>
      '/driver/trips/$id/items/$itemId/verify';

  // In-between stops
  static String arriveAtStop(String id, String stopId) =>
      '/driver/trips/$id/stops/$stopId/arrive';
  static String stopPhoto(String id, String stopId) =>
      '/driver/trips/$id/stops/$stopId/photo';
  static String finishStop(String id, String stopId) =>
      '/driver/trips/$id/stops/$stopId/done';

  // The driver's own vehicles
  static const vehicleTypes = '/driver/vehicle-types';
  static const myVehicles = '/driver/my-vehicles';
  static String myVehicle(String id) => '/driver/my-vehicles/$id';
  static String myVehiclePhotos(String id) => '/driver/my-vehicles/$id/photos';
  static String myVehiclePhoto(String id, String photoId) =>
      '/driver/my-vehicles/$id/photos/$photoId';
}
