import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mob_driver/core/config/app_config.dart';
import 'package:mob_driver/core/network/platform_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in driver: their tokens and the little we know about them
/// before the profile loads (id, name, phone). Survives app restarts.
///
/// Listeners are told when the driver signs in or out — the router uses that
/// to switch between the login flow and the app.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const _refreshPath = 'driver/auth/refresh';

  final _store = _SessionStore();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userDetails;

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Map<String, dynamic>? get userDetails =>
      _userDetails == null ? null : Map.of(_userDetails!);

  String? get phoneNumber {
    final value = _userDetails?['phone_number']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Restores the last session. If only the refresh token survived, trades it
  /// for a new access token straight away.
  Future<void> initialize() async {
    _accessToken = await _store.read(_SessionStore.accessTokenKey);
    _refreshToken = await _store.read(_SessionStore.refreshTokenKey);
    _userDetails = _decode(await _store.read(_SessionStore.userDetailsKey));

    if (_accessToken == null && _refreshToken != null) {
      try {
        await refreshAccessToken();
      } catch (_) {
        // Offline at launch: the first request retries the refresh.
      }
    }
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userDetails,
  }) async {
    _accessToken = _clean(accessToken);
    _refreshToken = _clean(refreshToken);
    _userDetails = userDetails == null ? null : Map.of(userDetails);

    await _store.write(_SessionStore.accessTokenKey, _accessToken);
    await _store.write(_SessionStore.refreshTokenKey, _refreshToken);
    await _store.write(
      _SessionStore.userDetailsKey,
      _userDetails == null || _userDetails!.isEmpty
          ? null
          : jsonEncode(_userDetails),
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _userDetails = null;
    await _store.clear();
    notifyListeners();
  }

  /// Trades the refresh token for a new access token.
  ///
  /// Returns null only when there is definitively no way to continue: no
  /// refresh token, or the server rejected it (revoked/expired/driver
  /// disabled). A network failure or a 5xx is *not* that — it throws, so the
  /// caller can keep the session and retry later instead of signing a driver
  /// out in a dead spot on the road.
  Future<String?> refreshAccessToken() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) return null;

    // A bare client: the app's own one would try to refresh on a 401 here.
    final response = await Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (_) => true,
      headers: {if (appPlatformHeaderValue() case final p?) 'platform': p},
    )).post<Object?>(_refreshPath, data: {'refreshToken': refreshToken});

    final status = response.statusCode ?? 0;
    if (status >= 500) {
      throw StateError('Token refresh unavailable ($status).');
    }
    final body = response.data;
    if (status < 200 || status >= 300 || body is! Map) return null;

    final newAccess =
        _firstString(body, const ['accessToken', 'access_token', 'access']);
    if (newAccess == null) return null;
    final newRefresh =
        _firstString(body, const ['refreshToken', 'refresh_token', 'refresh']);

    _accessToken = newAccess;
    _refreshToken = newRefresh ?? refreshToken;
    await _store.write(_SessionStore.accessTokenKey, _accessToken);
    await _store.write(_SessionStore.refreshTokenKey, _refreshToken);
    notifyListeners();
    return newAccess;
  }

  static String? _firstString(Map<Object?, Object?> body, List<String> keys) {
    for (final key in keys) {
      final value = _clean(body[key]?.toString());
      if (value != null) return value;
    }
    return null;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}

/// Where the session is kept: the OS keychain/keystore first, with a copy in
/// shared preferences for devices whose secure storage is unreliable (a
/// failing keystore would otherwise sign the driver out on every launch).
class _SessionStore {
  static const accessTokenKey = 'auth_access_token';
  static const refreshTokenKey = 'auth_refresh_token';
  static const userDetailsKey = 'auth_user_details';
  static const _fallbackPrefix = 'prefs_';

  static const _secure = FlutterSecureStorage();

  Future<String?> read(String key) async {
    String? value;
    try {
      value = await _secure.read(key: key);
    } catch (_) {}
    if (value == null || value.trim().isEmpty) {
      value = (await _prefs())?.getString('$_fallbackPrefix$key');
    }
    return value == null || value.trim().isEmpty ? null : value.trim();
  }

  /// Writes [value], or removes the key when it's null.
  Future<void> write(String key, String? value) async {
    final prefs = await _prefs();
    try {
      value == null
          ? await _secure.delete(key: key)
          : await _secure.write(key: key, value: value);
    } catch (_) {}
    value == null
        ? await prefs?.remove('$_fallbackPrefix$key')
        : await prefs?.setString('$_fallbackPrefix$key', value);
  }

  Future<void> clear() async {
    for (final key in const [accessTokenKey, refreshTokenKey, userDetailsKey]) {
      await write(key, null);
    }
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
