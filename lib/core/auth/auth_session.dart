import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/backend/api_requests/api_manager.dart';
import '/core/config/app_config.dart';

class AuthSession {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userDetailsKey = 'auth_user_details';
  static const String _isProFirstTimeKey = 'isProFirstTime';
  static const String _authRefreshPath = String.fromEnvironment(
    'AUTH_REFRESH_PATH',
    defaultValue: '/accounts/mob_user/auth/refresh/',
  );

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _userDetails;

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get userDetails =>
      _userDetails == null ? null : Map<String, dynamic>.from(_userDetails!);

  Future<bool> get isProFirstTime async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isProFirstTimeKey) ?? true;
  }

  Future<void> initialize() async {
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
      _accessToken = null;
      _refreshToken = null;
      _userDetails = null;
    }
    ApiManager.setAccessToken(_accessToken);
    ApiManager.setAuthRecoveryHandlers(
      refreshAccessToken: refreshAccessToken,
      onAuthFailed: signOut,
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken.trim();
    _refreshToken = refreshToken?.trim();

    await _storage.write(key: _accessTokenKey, value: _accessToken);
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    }

    ApiManager.setAccessToken(_accessToken);
  }

  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userDetails,
    bool? isProFirstTime,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await saveUserDetails(userDetails);
    if (isProFirstTime != null) {
      await setIsProFirstTime(isProFirstTime);
    }
  }

  Future<void> saveUserDetails(Map<String, dynamic>? userDetails) async {
    _userDetails =
        userDetails == null ? null : Map<String, dynamic>.from(userDetails);
    if (_userDetails == null || _userDetails!.isEmpty) {
      await _storage.delete(key: _userDetailsKey);
      return;
    }
    await _storage.write(
      key: _userDetailsKey,
      value: jsonEncode(_userDetails),
    );
  }

  Future<void> setIsProFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProFirstTimeKey, value);
  }

  Future<void> signOut() async {
    _accessToken = null;
    _refreshToken = null;
    _userDetails = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDetailsKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isProFirstTimeKey);
    ApiManager.setAccessToken(null);
    ApiManager.clearCache('homeData');
    ApiManager.clearCache('browseProducts');
    ApiManager.clearCache('productDetails');
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
}
