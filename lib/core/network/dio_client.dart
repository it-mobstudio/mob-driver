import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/network/auth_interceptor.dart';

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
  }
}
