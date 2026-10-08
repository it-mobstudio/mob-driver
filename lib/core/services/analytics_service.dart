import 'package:firebase_analytics/firebase_analytics.dart';

/// Product analytics (Firebase). Screen views are logged by [observer] on the
/// router; anything else the app wants to know about goes through a method
/// here, so event names live in one place.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  late final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> enableCollection() =>
      _analytics.setAnalyticsCollectionEnabled(true);

  Future<void> logLogin({required String method}) =>
      _analytics.logLogin(loginMethod: method);
}
