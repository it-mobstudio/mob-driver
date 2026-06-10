import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newToken = await AuthSession.instance.refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch<dynamic>(retryOptions);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // refresh failed — fall through to sign out
      } finally {
        _isRefreshing = false;
      }
      await AuthSession.instance.signOut();
    }
    handler.next(err);
  }
}
