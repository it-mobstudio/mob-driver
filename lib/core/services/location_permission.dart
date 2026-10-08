import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';

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
  if (permission == LocationPermission.denied) {
    if (!context.mounted) return false;
    TopSnackBar.show(
      context,
      message:
          tr('Location permission is needed to go on duty and receive trips.'),
      type: TopSnackBarType.error,
    );
    return false;
  }
  if (permission == LocationPermission.deniedForever) {
    if (!context.mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Location permission needed')),
        content: Text(
          tr('You\'ve turned off location access for MOB Go. Enable it in Settings so you can go on duty and receive trips.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('OPEN SETTINGS')),
          ),
        ],
      ),
    );
    if (openSettings == true) await Geolocator.openAppSettings();
    return false;
  }
  final granted = permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;
  if (!granted) return false;

  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (serviceEnabled) return true;

  if (!context.mounted) return false;
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr('Turn on location services')),
      content: Text(
        tr('Location services are turned off on this device. Turn them on to go on duty and receive trips.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(tr('CANCEL')),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(tr('OPEN SETTINGS')),
        ),
      ],
    ),
  );
  if (openSettings == true) await Geolocator.openLocationSettings();
  return false;
}
