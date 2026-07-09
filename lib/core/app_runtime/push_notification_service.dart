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

    // Fire-and-forget: the OS permission prompt can sit unanswered
    // indefinitely and must never block app startup.
    unawaited(
      FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      ),
    );
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
