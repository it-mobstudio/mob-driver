import 'package:equatable/equatable.dart';

/// A nudge from the server about where the work is: "Demand is high near
/// Indiranagar". [latitude]/[longitude], when present, are where to go.
class DemandHint extends Equatable {
  const DemandHint({required this.message, this.latitude, this.longitude});

  final String message;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [message, latitude, longitude];
}
