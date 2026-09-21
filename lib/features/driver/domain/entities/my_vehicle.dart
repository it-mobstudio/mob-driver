import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';

String vehicleCategoryLabel(String? category) => switch (category) {
      'two_wheeler' => '2 wheeler',
      'three_wheeler' => '3 wheeler',
      'four_wheeler' => '4 wheeler',
      _ => '',
    };

/// One picture of a vehicle, as the server holds it.
class VehiclePhotoRef extends Equatable {
  const VehiclePhotoRef({required this.id, required this.url});

  factory VehiclePhotoRef.fromJson(Map<String, dynamic> json) =>
      VehiclePhotoRef(
        id: readString(json['id']) ?? '',
        url: readString(json['url']) ?? '',
      );

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}

/// A vehicle the driver registered themselves (`driver/my-vehicles`), with all
/// its pictures. The first picture is the main one ([photoUrl]).
class MyVehicle extends Equatable {
  const MyVehicle({
    required this.id,
    required this.registrationNumber,
    this.vehicleTypeId,
    this.vehicleTypeName,
    this.category,
    this.capacityKg,
    this.photoUrl,
    this.photos = const [],
    this.status = 'active',
    this.isCurrent = false,
  });

  factory MyVehicle.fromJson(Map<String, dynamic> json) {
    final type = asMap(json['vehicle_type']);
    return MyVehicle(
      id: readString(json['id']) ?? '',
      registrationNumber: readString(json['registration_number']) ?? '—',
      vehicleTypeId: readString(type['id']),
      vehicleTypeName: readString(type['name']),
      category: readString(type['category']),
      capacityKg: readDouble(json['capacity_kg']),
      photoUrl: readString(json['photo_url']),
      photos: [
        for (final p in (json['photos'] as List?) ?? const [])
          VehiclePhotoRef.fromJson(asMap(p)),
      ],
      status: readString(json['status']) ?? 'active',
      isCurrent: readBool(json['is_current']),
    );
  }

  final String id;
  final String registrationNumber;
  final String? vehicleTypeId;
  final String? vehicleTypeName;
  final String? category;
  final double? capacityKg;
  final String? photoUrl;
  final List<VehiclePhotoRef> photos;
  final String status;

  /// The vehicle the driver is on duty with (or last was).
  final bool isCurrent;

  String get categoryLabel => vehicleCategoryLabel(category);

  /// Every picture URL to show, main one first.
  List<String> get photoUrls => photos.isNotEmpty
      ? [for (final p in photos) p.url]
      : [if ((photoUrl ?? '').isNotEmpty) photoUrl!];

  @override
  List<Object?> get props => [
        id,
        registrationNumber,
        vehicleTypeId,
        vehicleTypeName,
        category,
        capacityKg,
        photoUrl,
        photos,
        status,
        isCurrent,
      ];
}

/// A kind of vehicle the company runs — what a driver picks when adding theirs
/// (`driver/vehicle-types`).
class VehicleTypeOption extends Equatable {
  const VehicleTypeOption({
    required this.id,
    required this.name,
    this.category,
    this.defaultCapacityKg,
    this.iconUrl,
  });

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) =>
      VehicleTypeOption(
        id: readString(json['id']) ?? '',
        name: readString(json['name']) ?? '—',
        category: readString(json['category']),
        defaultCapacityKg: readDouble(json['default_capacity_kg']),
        iconUrl: readString(json['icon_image_url']),
      );

  final String id;
  final String name;
  final String? category;
  final double? defaultCapacityKg;
  final String? iconUrl;

  String get categoryLabel => vehicleCategoryLabel(category);

  @override
  List<Object?> get props => [id, name, category, defaultCapacityKg, iconUrl];
}
