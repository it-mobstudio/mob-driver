import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:m_o_b_demand_side/core/app_runtime/nav/nav.dart';

/// Background messages arrive on a separate isolate with no access to any
/// app state, so this must be a top-level (or static) function — it can
/// only do isolate-local work like logging; anything that needs the running
/// app (navigation, in-memory state) is handled when the user taps the
/// notification instead (see [PushNotificationService._handleMessageOpen]).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[Push] Background message: ${message.messageId}');
  }
}

/// Wires up push notification display + tap-to-navigate. Separate from
/// [FcmTokenSync], which only keeps the backend's copy of the device token
/// current — this owns everything about what happens once a message
/// actually arrives.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _androidChannel = AndroidNotificationChannel(
    'mob_default_channel',
    'General notifications',
    description: 'Order updates, offers, and account alerts.',
    importance: Importance.high,
  );

  static const _tripChannel = AndroidNotificationChannel(
    'mob_driver_active_trip',
    'Active delivery tracking',
    description: 'Persistent status for the driver’s active delivery.',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );
  static const _ongoingTripNotificationId = 2048;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;

    await _setupLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages don't auto-display anything on either platform —
    // FCM only shows a system notification when the app is backgrounded or
    // terminated, so the foreground case is shown manually via the local
    // notifications plugin below.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // App was backgrounded (not terminated) and the user tapped the
    // OS-shown notification to bring it back to the foreground.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleMessageOpen(message.data),
    );

    // App was terminated and got launched by tapping a notification —
    // only available once, right after a cold start.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage.data);
    }
  }

  /// Requests notification permission only after an in-app explanation.
  /// Driver startup deliberately does not trigger an OS permission prompt.
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(
            jsonDecode(payload) as Map,
          );
          _handleMessageOpen(data);
        } catch (_) {
          // Malformed/unexpected payload — nothing sensible to navigate to.
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_tripChannel);
  }

  /// Shows an Android ongoing trip card similar to delivery-partner apps.
  /// Calling this again updates the same notification without making sound.
  Future<void> showOngoingTrip({
    required String tripId,
    required String destination,
    required String eta,
    String? title,
    String route = '/driver/trips',
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await initialize();
      await _localNotifications.show(
        _ongoingTripNotificationId,
        title ??
            (eta == 'Tracking paused' ? 'Trip paused' : 'On the way · $eta'),
        '$tripId  •  Delivery to $destination',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _tripChannel.id,
            _tripChannel.name,
            channelDescription: _tripChannel.description,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            category: AndroidNotificationCategory.navigation,
            visibility: NotificationVisibility.public,
            subText: 'MOB Driver',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: jsonEncode({'route': route, 'trip_id': tripId}),
      );
    } catch (error) {
      // The plugin has no platform implementation in widget tests and on a
      // few unsupported desktop targets. Trip UI must remain fully usable.
      if (kDebugMode) debugPrint('[Push] Ongoing trip unavailable: $error');
    }
  }

  /// A one-off, sound-and-vibration alert — a new trip assigned, or one the
  /// company cancelled. Tapping it opens [route].
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    String? route,
  }) async {
    if (kIsWeb) return;
    try {
      if (!_initialized) await initialize();
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.event,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route == null ? null : jsonEncode({'route': route}),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('[Push] Alert unavailable: $error');
    }
  }

  Future<void> hideOngoingTrip() async {
    if (kIsWeb || !_initialized) return;
    await _localNotifications.cancel(_ongoingTripNotificationId);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // Generic on purpose — the backend's notification payload shape isn't
  // fixed yet, so this tries the common deep-link key names and otherwise
  // just leaves the app open on whatever screen it already launched to
  // rather than guessing at a route that doesn't exist.
  void _handleMessageOpen(Map<String, dynamic> data) {
    final route = (data['route'] ?? data['screen'] ?? data['deep_link'])
        ?.toString()
        .trim();
    if (route == null || route.isEmpty) return;
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).push(route);
  }
}
