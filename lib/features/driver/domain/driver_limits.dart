/// Limits the driver app enforces before the backend has to refuse.
abstract final class DriverLimits {
  /// Pictures one of the driver's own vehicles can have.
  static const maxVehiclePhotos = 6;

  /// Vehicles a driver can add as their own.
  static const maxOwnVehicles = 10;

  /// Photos of the whole order a driver can keep per stop.
  static const maxOrderPhotos = 10;

  /// Digits in the delivery OTP the customer reads out.
  static const deliveryOtpLength = 4;

  /// On duty with no order for this long, the dashboard suggests moving to
  /// a busier area.
  static const idleHintAfter = Duration(minutes: 2);

  /// Wait before the delivery OTP can be sent to the customer again.
  static const deliveryOtpResendSeconds = 30;
}
