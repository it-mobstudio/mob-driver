import 'package:dio/dio.dart';

sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

final class AuthFailure extends AppFailure {
  const AuthFailure([
    super.message = 'Authentication required. Please log in.',
  ]);
}

final class BusinessFailure extends AppFailure {
  const BusinessFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred.',
  ]);
}

extension DioExceptionMapper on DioException {
  AppFailure toAppFailure() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badCertificate:
        return const NetworkFailure('SSL certificate error.');
      case DioExceptionType.cancel:
        return const UnknownFailure('Request was cancelled.');
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        if (statusCode == 401) return const AuthFailure();
        final data = response?.data;
        if (data is Map) {
          final apiStatus = data['status'];
          final apiMessage = data['message']?.toString().trim();
          if (apiStatus == false &&
              apiMessage != null &&
              apiMessage.isNotEmpty) {
            return BusinessFailure(apiMessage);
          }
          if (apiMessage != null && apiMessage.isNotEmpty) {
            return ServerFailure(apiMessage, statusCode: statusCode);
          }
        }
        return ServerFailure(
          'Server error (${statusCode ?? 'unknown'}).',
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        final msg = error?.toString() ?? '';
        if (msg.contains('SocketException') ||
            msg.contains('Connection refused') ||
            msg.contains('Network is unreachable')) {
          return const NetworkFailure();
        }
        final errMessage = message;
        return UnknownFailure(
          (errMessage != null && errMessage.isNotEmpty)
              ? errMessage
              : 'An unexpected error occurred.',
        );
    }
  }
}
