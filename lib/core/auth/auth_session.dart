import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/api_requests/api_manager.dart';
import '/core/config/app_config.dart';
import '/features/address/data/local/selected_address_store.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userDetailsKey = 'auth_user_details';
  static const String _prefsAccessTokenKey = 'prefs_auth_access_token';
  static const String _prefsRefreshTokenKey = 'prefs_auth_refresh_token';
  static const String _prefsUserDetailsKey = 'prefs_auth_user_details';
  static const String _isProFirstTimeKey = 'isProFirstTime';
  static const String _needsRegistrationKey = 'auth_needs_registration';
  static const String _authRefreshPath = String.fromEnvironment(
    'AUTH_REFRESH_PATH',
    defaultValue: '/accounts/mob_user/auth/refresh/',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userDetails;
  bool _needsRegistration = false;

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userDetails =>
      _userDetails == null ? null : Map<String, dynamic>.from(_userDetails!);
  // True when the user has a valid session (e.g. just verified OTP) but
  // hasn't completed the signup form yet — used to keep them on /signup
  // instead of routes that gate on isAuthenticated alone.
  bool get needsRegistration => _needsRegistration;

  /// Signed-in user's phone number, wherever the user_details payload put
  /// it (the backend hasn't been consistent about the key name).
  String? get phoneNumber {
    final details = _userDetails;
    if (details == null) return null;
    for (final key in const ['phone_number', 'phone', 'mobile']) {
      final value = details[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  /// The identifier several backend endpoints require as `email_or_phone`
  /// (login/OTP, update_user, FCM token sync) — whichever of the login
  /// credential or a phone/email fallback is actually present in
  /// user_details.
  String? get emailOrPhone {
    final details = _userDetails;
    if (details == null) return null;
    for (final key in const [
      'email_or_phone',
      'phone_number',
      'phone',
      'mobile',
      'email',
    ]) {
      final value = details[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  Future<bool> get isProFirstTime async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isProFirstTimeKey) ?? true;
  }

  Future<void> initialize() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    try {
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
      final userDetailsRaw = await _storage.read(key: _userDetailsKey);
      if (userDetailsRaw != null && userDetailsRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(userDetailsRaw);
          if (decoded is Map) {
            _userDetails = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          _userDetails = null;
        }
      }
    } catch (_) {
      // Fallback to shared preferences below.
    }

    _accessToken = _normalizeString(_accessToken) ??
        _normalizeString(prefs?.getString(_prefsAccessTokenKey));
    _refreshToken = _normalizeString(_refreshToken) ??
        _normalizeString(prefs?.getString(_prefsRefreshTokenKey));

    final secureUserDetailsRaw = await _readSecureUserDetailsRaw();
    final fallbackUserDetailsRaw = prefs?.getString(_prefsUserDetailsKey);
    _userDetails = _decodeUserDetails(secureUserDetailsRaw) ??
        _decodeUserDetails(fallbackUserDetailsRaw);

    // Keep secure storage in sync when fallback values were recovered.
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      await _storage.write(key: _accessTokenKey, value: _accessToken);
      await prefs?.setString(_prefsAccessTokenKey, _accessToken!);
    }
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
      await prefs?.setString(_prefsRefreshTokenKey, _refreshToken!);
    }
    if (_userDetails != null && _userDetails!.isNotEmpty) {
      final encoded = jsonEncode(_userDetails);
      await _storage.write(key: _userDetailsKey, value: encoded);
      await prefs?.setString(_prefsUserDetailsKey, encoded);
    }

    _needsRegistration = prefs?.getBool(_needsRegistrationKey) ?? false;

    ApiManager.setAccessToken(_accessToken);
    ApiManager.setAuthRecoveryHandlers(
      refreshAccessToken: refreshAccessToken,
      onAuthFailed: signOut,
    );

    // If access token is unavailable but refresh token exists, recover session.
    if ((_accessToken == null || _accessToken!.isEmpty) &&
        _refreshToken != null &&
        _refreshToken!.isNotEmpty) {
      await refreshAccessToken();
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = accessToken.trim();
    _refreshToken = refreshToken?.trim();

    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await prefs.setString(_prefsAccessTokenKey, _accessToken!);
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
      await prefs.setString(_prefsRefreshTokenKey, _refreshToken!);
    }

    ApiManager.setAccessToken(_accessToken);
    notifyListeners();
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userDetails,
    bool? isProFirstTime,
    bool needsRegistration = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = accessToken.trim();
    _refreshToken = _normalizeString(refreshToken);
    _userDetails =
        userDetails == null ? null : Map<String, dynamic>.from(userDetails);
    _needsRegistration = needsRegistration;

    // A fresh session may belong to a different account than whatever was
    // last signed in on this device — drop any address cached for the
    // previous identity so it doesn't leak into the new session.
    await SelectedAddressStore.clear();

    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await prefs.setString(_prefsAccessTokenKey, _accessToken!);
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
      await prefs.setString(_prefsRefreshTokenKey, _refreshToken!);
    } else {
      await _storage.delete(key: _refreshTokenKey);
      await prefs.remove(_prefsRefreshTokenKey);
    }

    if (_userDetails != null && _userDetails!.isNotEmpty) {
      final encoded = jsonEncode(_userDetails);
      await _storage.write(key: _userDetailsKey, value: encoded);
      await prefs.setString(_prefsUserDetailsKey, encoded);
    } else {
      await _storage.delete(key: _userDetailsKey);
      await prefs.remove(_prefsUserDetailsKey);
    }

    if (isProFirstTime != null) {
      await setIsProFirstTime(isProFirstTime);
    }
    await prefs.setBool(_needsRegistrationKey, needsRegistration);
    ApiManager.setAccessToken(_accessToken);
    notifyListeners();
  }

  Future<void> setNeedsRegistration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _needsRegistration = value;
    await prefs.setBool(_needsRegistrationKey, value);
    notifyListeners();
  }

  Future<void> saveUserDetails(Map<String, dynamic>? userDetails) async {
    final prefs = await SharedPreferences.getInstance();
    _userDetails =
        userDetails == null ? null : Map<String, dynamic>.from(userDetails);
    if (_userDetails == null || _userDetails!.isEmpty) {
      await _storage.delete(key: _userDetailsKey);
      await prefs.remove(_prefsUserDetailsKey);
      return;
    }
    final encoded = jsonEncode(_userDetails);
    await _storage.write(
      key: _userDetailsKey,
      value: encoded,
    );
    await prefs.setString(_prefsUserDetailsKey, encoded);
  }

  Future<void> setIsProFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProFirstTimeKey, value);
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _userDetails = null;
    _needsRegistration = false;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDetailsKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAccessTokenKey);
    await prefs.remove(_prefsRefreshTokenKey);
    await prefs.remove(_prefsUserDetailsKey);
    await prefs.remove(_isProFirstTimeKey);
    await prefs.remove(_needsRegistrationKey);
    ApiManager.setAccessToken(null);
    ApiManager.clearCache('homeData');
    ApiManager.clearCache('browseProducts');
    ApiManager.clearCache('productDetails');
    await SelectedAddressStore.clear();
    notifyListeners();
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    final uri = AppConfig.apiUri(_authRefreshPath);
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refresh_token': refreshToken,
        'refreshToken': refreshToken,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    final body = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};

    final newAccessToken = _readFirstString(
      data.isNotEmpty ? data : body,
      const ['access_token', 'accessToken', 'token', 'jwt'],
    );
    final newRefreshToken = _readFirstString(
      data.isNotEmpty ? data : body,
      const ['refresh_token', 'refreshToken'],
    );

    if (newAccessToken == null || newAccessToken.isEmpty) {
      return null;
    }
    await saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken ?? _refreshToken,
    );
    return newAccessToken;
  }

  String? _readFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _normalizeString(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> _readSecureUserDetailsRaw() async {
    try {
      return await _storage.read(key: _userDetailsKey);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeUserDetails(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }
}
