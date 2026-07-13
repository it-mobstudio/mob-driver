import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `getToken()` throws `apns-token-not-set` if called before iOS finishes
/// delivering the APNs token — which happens asynchronously right after
/// permission is requested, so a call right at app startup routinely loses
/// this race. Android/web have no such handshake, so only iOS needs to wait.
/// Polls briefly rather than failing outright, since the token typically
/// shows up within a second or two of requesting notification permission.
Future<String?> resolveFcmToken() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    var apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    var attempts = 0;
    while (apnsToken == null && attempts < 10) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      attempts++;
    }
    if (apnsToken == null) return null;
  }
  return FirebaseMessaging.instance.getToken();
}

/// Keeps the backend's `fcm_token` for the signed-in user in sync with the
/// device's current Firebase token — without spamming `update_user` on
/// every app launch. The standard rule: only call the API when the
/// (user, token) pair actually differs from the last one we successfully
/// sent, tracked as a cached marker in SharedPreferences. Callers are:
///   - [start] once at app bootstrap (initial sync + subscribes to Firebase's
///     own onTokenRefresh, which itself only fires when the token actually
///     rotates — a rare, Firebase-driven event, not a polling loop).
///   - [syncCurrentToken] again right after a fresh login, since the signed-in
///     identifier may only become known at that point.
class FcmTokenSync {
  FcmTokenSync._();

  static final FcmTokenSync instance = FcmTokenSync._();

  static const _prefsKey = 'fcm_synced_token_for_user';

  StreamSubscription<String>? _refreshSubscription;

  Future<void> start() async {
    // FCM on web needs a VAPID key we haven't configured; skip rather than
    // throw. Desktop targets aren't push-capable either.
    if (kIsWeb) return;
    _refreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => unawaited(_sync(token)),
    );
    await syncCurrentToken();
  }

  Future<void> syncCurrentToken() async {
    if (kIsWeb) return;
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      // Permission is requested by PushNotificationService — getToken()
      // still resolves without it on Android. On iOS it additionally needs
      // the APNs token, which [resolveFcmToken] waits for.
      final token = await resolveFcmToken();
      if (token == null || token.trim().isEmpty) return;
      await _sync(token.trim());
    } catch (_) {
      // A push-token hiccup must never break login/app startup.
    }
  }

  Future<void> _sync(String token) async {
    final emailOrPhone = AuthSession.instance.emailOrPhone;
    if (emailOrPhone == null) return;

    final prefs = await SharedPreferences.getInstance();
    final marker = '$emailOrPhone|$token';
    if (prefs.getString(_prefsKey) == marker) return;

    final (success, _) = await sl<AuthRepository>().updateFcmToken(
      emailOrPhone: emailOrPhone,
      fcmToken: token,
    );
    if (success) {
      await prefs.setString(_prefsKey, marker);
    }
  }
}
