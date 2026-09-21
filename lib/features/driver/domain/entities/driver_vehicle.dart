import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';

class DriverVehicle extends Equatable {
  const DriverVehicle({
    required this.id,
    required this.registrationNumber,
    this.vehicleTypeName,
    this.category,
    this.capacityKg,
    this.photoUrl,
    this.isCurrent = false,
    this.isOwn = false,
  });

  /// Parses `DriverVehicleSummarySerializer` rows — from `driver/vehicles`
  /// (which adds `is_current`) and from `driver/me`'s `current_vehicle`.
  factory DriverVehicle.fromJson(Map<String, dynamic> json) {
    final type = asMap(json['vehicle_type']);
    return DriverVehicle(
      id: readString(json['id']) ?? '',
      registrationNumber: readString(json['registration_number']) ?? '—',
      vehicleTypeName: readString(type['name']),
      category: readString(type['category']),
      capacityKg: readDouble(json['capacity_kg']),
      photoUrl: readString(json['photo_url']),
      isCurrent: readBool(json['is_current']),
      isOwn: readBool(json['is_own']),
    );
  }

  final String id;
  final String registrationNumber;
  final String? vehicleTypeName;

  /// `two_wheeler`, `three_wheeler` or `four_wheeler`.
  final String? category;
  final double? capacityKg;
  final String? photoUrl;
  final bool isCurrent;

  /// The driver registered this vehicle themselves (not the company's fleet).
  final bool isOwn;

  String get categoryLabel => switch (category) {
        'two_wheeler' => '2 wheeler',
        'three_wheeler' => '3 wheeler',
        'four_wheeler' => '4 wheeler',
        _ => '',
      };

  @override
  List<Object?> get props =>
      [id, registrationNumber, vehicleTypeName, category, isCurrent, isOwn];
}
