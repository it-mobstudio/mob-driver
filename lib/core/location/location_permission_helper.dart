import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Requests location permission, showing the native OS prompt when Android
/// can still ask. When permission was permanently denied (Android won't
/// re-show its own dialog at that point), shows an in-app rationale with a
/// button to deep-link into the app's system settings instead of dead-ending
/// on a snackbar the user has no way to act on.
Future<bool> ensureLocationPermission(BuildContext context) async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    if (!context.mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location permission needed'),
        content: const Text(
          "You've turned off location access for MOB. Enable it in "
          "Settings to use your current location.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
    if (openSettings == true) await Geolocator.openAppSettings();
    return false;
  }
  return permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
}
