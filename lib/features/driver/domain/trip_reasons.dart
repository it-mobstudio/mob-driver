/// The reasons a driver picks from. They're sent to the backend as written
/// (in English) and translated only where they're shown.
abstract final class TripReasons {
  /// The choice that lets the driver type their own reason.
  static const other = 'Other';

  /// Cancelling a trip before pickup.
  static const cancel = [
    'Vehicle breakdown',
    'Customer not reachable',
    'Pickup not ready',
    'Unsafe or wrong location',
    other,
  ];

  /// Why an item wasn't handed over at the drop.
  static const notDelivered = [
    'Customer refused it',
    'Item damaged',
    'Item missing or short',
    'Wrong item',
    other,
  ];
}
