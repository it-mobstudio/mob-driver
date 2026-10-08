import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hand-offs to other apps on the phone.
abstract final class Launchers {
  /// Turn-by-turn directions to [stop] in the phone's maps app. The plain
  /// https Google Maps link opens the Maps app when it's installed and the
  /// browser otherwise, on both platforms.
  static Future<bool> navigateTo(TripStop stop) => stop.hasCoordinates
      ? navigateToPoint(stop.latitude!, stop.longitude!)
      : Future.value(false);

  static Future<bool> navigateToPoint(double latitude, double longitude) {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call(String? phone) {
    final number = phone?.trim() ?? '';
    if (number.isEmpty) return Future.value(false);
    return launchUrl(Uri(scheme: 'tel', path: number));
  }
}
