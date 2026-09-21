import 'dart:convert';

import 'package:dio/dio.dart';

/// A Dio adapter that answers from a script and records every request, so the
/// real datasource/repository code runs against canned backend responses and
/// tests can assert on exactly what was sent (method, path, query, body).
class ScriptedAdapter implements HttpClientAdapter {
  final Map<String, ({dynamic body, int status})> _routes = {};
  final List<RequestOptions> requests = [];

  /// Script a response. [body] is JSON-encoded unless it's already a String.
  void on(String method, String path, dynamic body, {int status = 200}) =>
      _routes['$method $path'] = (body: body, status: status);

  RequestOptions lastRequest(String method, String path) =>
      requests.lastWhere((r) => r.method == method && r.path == path);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = _routes['${options.method} ${options.path}'];
    final (body, status) =
        route == null ? ('{"detail":"no route"}', 404) : (_encode(route.body), route.status);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  static String _encode(dynamic body) => body is String ? body : jsonEncode(body);

  @override
  void close({bool force = false}) {}
}

Dio scriptedDio(ScriptedAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://test/api/v1/'))..httpClientAdapter = adapter;
