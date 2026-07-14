import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/network/auth_interceptor.dart';
import 'package:m_o_b_demand_side/core/network/logging_interceptor.dart';
import 'package:sentry_dio/sentry_dio.dart';

class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late Dio _dio;
  Dio get dio => _dio;

  void initialize({required String baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
    // Breadcrumbs + performance spans + failed-request capture for every
    // request through this client — the SDK guards its own instrumentation
    // internally, so a Sentry-side hiccup here can't break a real request.
    _dio.addSentry();
    _dio.interceptors.add(LoggingInterceptor());
  }
}
