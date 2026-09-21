import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/network/platform_header.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  Future<String?>? _refreshInFlight;

  static const _retriedKey = 'auth_retried';

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
    // A request that already went round once with a fresh token and still got
    // a 401 is genuinely unauthorised — don't refresh-and-retry forever.
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (err.response?.statusCode == 401 && !alreadyRetried) {
      // Several requests can 401 around the same moment right after a token
      // expires (e.g. two screens loading in parallel) — share a single
      // refresh attempt between them instead of letting only the first one
      // retry while the rest propagate a now-stale 401.
      _refreshInFlight ??= _refresh();
      final newToken = await _refreshInFlight;
      if (newToken != null && newToken.isNotEmpty) {
        try {
          final retryOptions = err.requestOptions;
          retryOptions.extra[_retriedKey] = true;
          // A multipart body can only be sent once — the first attempt already
          // consumed it. Without a fresh copy, a photo upload that happened to
          // land just as the access token expired would fail for good even
          // though the refresh worked.
          final body = retryOptions.data;
          if (body is FormData) retryOptions.data = body.clone();
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
        // The server refused the refresh token (or there isn't one): the
        // session is over.
        await AuthSession.instance.signOut();
      }
      return newToken;
    } catch (_) {
      // Couldn't reach the server, or it errored. That says nothing about
      // whether the session is still valid, so keep it — the original
      // request fails as an ordinary network error and can be retried.
      return null;
    } finally {
      _refreshInFlight = null;
    }
  }
}
