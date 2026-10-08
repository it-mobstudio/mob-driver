/// Every bundled asset the app uses, by name. Add new files here (and to
/// the folders listed in pubspec.yaml) rather than spelling paths inline.
abstract final class AppAssets {
  // Animations (Lottie)
  static const splashAnimation = 'assets/animations/splash.json';
  static const findingOrdersAnimation = 'assets/animations/finding_orders.json';

  // Icons
  static const back = 'assets/icons/back.svg';
  static const driverMarker = 'assets/icons/driver_marker.svg';
  static const pickupDot = 'assets/icons/pickup_dot.svg';
  static const pickupMark = 'assets/icons/pickup_mark.svg';
  static const recenter = 'assets/icons/recenter.svg';
  static const sos = 'assets/icons/sos.svg';
  static const toastSuccess = 'assets/icons/toast/success.svg';
  static const toastFailure = 'assets/icons/toast/failure.svg';
  static const toastInfo = 'assets/icons/toast/stock.svg';
  static const toastCopied = 'assets/icons/toast/copied.svg';

  // Images
  static const mobLogo = 'assets/images/moblogo.svg';
  static const deliveredDriver = 'assets/images/delivered_driver.png';
  static const heavyLoading = 'assets/images/heavy_loading.png';

  /// A vehicle illustration: `auto`, `lorry`, `pickup`, `scooter`, `truck`,
  /// `tata_ace`, or `person` (the driver standing beside one).
  static String vehicle(String name) => 'assets/images/vehicles/$name.png';
  static const loginVehicle = 'assets/images/vehicles/tata_ace.png';
  static const loginDriver = 'assets/images/vehicles/person.png';

  // Sounds
  static const newOrderSound = 'assets/sounds/new_order.m4a';
}
