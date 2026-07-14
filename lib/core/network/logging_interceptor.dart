import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints method/path/status/duration for every request to the debug
/// console — purely a local developer aid, separate from what Sentry
/// captures. A complete no-op outside debug builds (no formatting, no
/// timing, nothing), and every callback swallows its own errors: a bug in
/// this logger must never break the actual request/response it's observing.
class LoggingInterceptor extends Interceptor {
  static const _startTimeKey = 'logging_interceptor_start_time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      try {
        options.extra[_startTimeKey] = DateTime.now();
        debugPrint('--> ${options.method} ${options.uri}');
      } catch (_) {}
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      try {
        final elapsed = _elapsedSince(response.requestOptions);
        debugPrint(
          '<-- ${response.statusCode} ${response.requestOptions.uri}'
          '${elapsed != null ? ' (${elapsed.inMilliseconds}ms)' : ''}',
        );
      } catch (_) {}
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      try {
        final elapsed = _elapsedSince(err.requestOptions);
        debugPrint(
          '<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}'
          '${elapsed != null ? ' (${elapsed.inMilliseconds}ms)' : ''}: '
          '${err.message}',
        );
      } catch (_) {}
    }
    handler.next(err);
  }

  Duration? _elapsedSince(RequestOptions options) {
    final start = options.extra[_startTimeKey];
    if (start is! DateTime) return null;
    return DateTime.now().difference(start);
  }
}
