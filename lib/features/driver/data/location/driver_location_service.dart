import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:geolocator/geolocator.dart';

class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Where the driver is. An interface so the duty/trip logic can be tested
/// without a GPS, and so the platform specifics stay in one place.
abstract interface class DriverLocationService {
  /// A single fix, or null when none can be had (permission denied, GPS off,
  /// timeout).
  Future<GeoPoint?> currentPosition();

  /// Continuous fixes while on duty. Errors (permission revoked, GPS turned
  /// off) arrive as stream errors.
  Stream<GeoPoint> positionStream();
}

class GeolocatorLocationService implements DriverLocationService {
  const GeolocatorLocationService();

  @override
  Future<GeoPoint?> currentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      if (kIsWeb) return null;
      try {
        // A slightly stale fix beats no fix (e.g. indoors at the depot).
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : GeoPoint(last.latitude, last.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<GeoPoint> positionStream() => Geolocator.getPositionStream(
        locationSettings: _settings(),
      ).map((p) => GeoPoint(p.latitude, p.longitude));

  LocationSettings _settings() {
    if (kIsWeb) {
      return const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 5),
          // Keeps location (and with it trip polling) alive when the driver
          // switches to their maps app to navigate.
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'MOB Driver is on duty',
            notificationText: 'Sharing your location so trips can be assigned.',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      default:
        return const LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10);
    }
  }
}
