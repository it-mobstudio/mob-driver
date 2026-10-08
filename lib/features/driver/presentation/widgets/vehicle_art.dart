import 'package:flutter/material.dart';

import 'package:mob_driver/core/constants/app_assets.dart';

/// The picture for a kind of vehicle, chosen from its name first ("Tata Ace",
/// "Truck 14 ft") and its category second — the same rules and the same 3D
/// pictures (Microsoft Fluent Emoji, MIT) as the customer booking web app
/// (`booking.services.vehicle_art`), so everyone sees the same vehicle.
String vehicleArtAsset({String? category, String? name}) {
  final n = (name ?? '').toLowerCase();
  String art;
  if (RegExp(r'lorry|trailer|container|\b(14|17|19|20|22|24|32)\s*ft')
      .hasMatch(n)) {
    art = 'lorry';
  } else if (RegExp(r'mini|\bace\b|tempo|bolero|dost|\bvan\b|chhota')
      .hasMatch(n)) {
    art = 'pickup';
  } else if (RegExp(r'truck|tonne|\bton\b|eicher|407|canter|\bft\b')
      .hasMatch(n)) {
    art = 'truck';
  } else if (RegExp(r'pickup|pick-up|4 ?wheel').hasMatch(n)) {
    art = 'pickup';
  } else if (RegExp(r'auto|rickshaw|3 ?wheel|loader|e-?rick').hasMatch(n)) {
    art = 'auto';
  } else if (RegExp(r'bike|scoot|2 ?wheel|motor|activa').hasMatch(n)) {
    art = 'scooter';
  } else {
    art = switch (category) {
      'two_wheeler' => 'scooter',
      'three_wheeler' => 'auto',
      _ => 'pickup',
    };
  }
  return AppAssets.vehicle(art);
}

class VehicleArt extends StatelessWidget {
  const VehicleArt({super.key, this.category, this.name, this.width = 72});

  final String? category;
  final String? name;
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
        vehicleArtAsset(category: category, name: name),
        width: width,
        height: width * .8,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
}
