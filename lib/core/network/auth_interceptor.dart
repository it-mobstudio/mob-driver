import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/network/platform_header.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  Future<String?>? _refreshInFlight;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    addPlatformHeader(options.headers);
    final token = AuthSession.instance.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Several requests can 401 around the same moment right after a token
      // expires (e.g. two screens loading in parallel) — share a single
      // refresh attempt between them instead of letting only the first one
      // retry while the rest propagate a now-stale 401.
      _refreshInFlight ??= _refresh();
      final newToken = await _refreshInFlight;
      if (newToken != null && newToken.isNotEmpty) {
        try {
          final retryOptions = err.requestOptions;
          addPlatformHeader(retryOptions.headers);
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch<dynamic>(retryOptions);
          handler.resolve(response);
          return;
        } catch (_) {
          // The retry itself failed — fall through and propagate the
          // original error instead of throwing out of the interceptor.
        }
      }
    }
    handler.next(err);
  }

  Future<String?> _refresh() async {
    try {
      final newToken = await AuthSession.instance.refreshAccessToken();
      if (newToken == null || newToken.isEmpty) {
        await AuthSession.instance.signOut();
      }
      return newToken;
    } catch (_) {
      await AuthSession.instance.signOut();
      return null;
    } finally {
      _refreshInFlight = null;
    }
  }
}
