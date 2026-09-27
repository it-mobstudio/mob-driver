import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The picture for a kind of vehicle — bike, auto, mini truck or truck —
/// chosen from its name first ("Tata Ace", "14 ft truck") and its category
/// second. The same four drawings are used by the console and the customer
/// booking page, so everyone sees the same vehicle for the same type.
String vehicleArtAsset({String? category, String? name}) {
  final n = (name ?? '').toLowerCase();
  if (RegExp(r'truck|lorry|eicher|407|tonne|ton\b|ft\b|container').hasMatch(n) && !n.contains('mini')) {
    return 'assets/images/vehicles/truck.svg';
  }
  if (RegExp(r'mini|ace|tempo|pickup|pick-up|van|dost|4 ?wheel').hasMatch(n)) {
    return 'assets/images/vehicles/mini_truck.svg';
  }
  if (RegExp(r'auto|rickshaw|3 ?wheel|e-?loader|loader').hasMatch(n)) {
    return 'assets/images/vehicles/auto.svg';
  }
  if (RegExp(r'bike|scooter|scooty|2 ?wheel|motor').hasMatch(n)) {
    return 'assets/images/vehicles/bike.svg';
  }
  return switch (category) {
    'two_wheeler' => 'assets/images/vehicles/bike.svg',
    'three_wheeler' => 'assets/images/vehicles/auto.svg',
    _ => 'assets/images/vehicles/mini_truck.svg',
  };
}

class VehicleArt extends StatelessWidget {
  const VehicleArt({super.key, this.category, this.name, this.width = 72});

  final String? category;
  final String? name;
  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        vehicleArtAsset(category: category, name: name),
        width: width,
        height: width * 100 / 160,
        fit: BoxFit.contain,
      );
}
