import 'dart:async';

import '/backend/api_requests/api_manager.dart';

class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}

AppException appExceptionFromApiResponse(
  ApiCallResponse response, {
  String fallbackMessage = 'Something went wrong. Please try again.',
}) {
  final statusCode = response.statusCode;
  final exception = response.exception;

  if (_isSocketException(exception)) {
    return AppException(
      'No internet connection. Check your network and retry.',
      statusCode: statusCode,
      cause: exception,
    );
  }

  if (exception is TimeoutException) {
    return AppException(
      'Request timed out. Please try again.',
      statusCode: statusCode,
      cause: exception,
    );
  }

  if (statusCode == 408) {
    return AppException('Server is taking too long to respond. Retry in a moment.',
        statusCode: statusCode);
  }

  if (statusCode == 429) {
    return AppException('Too many requests. Please wait and try again.',
        statusCode: statusCode);
  }

  if (statusCode == 401 || statusCode == 403) {
    return AppException('Your session expired. Please log in again.',
        statusCode: statusCode);
  }

  if (statusCode >= 500) {
    return AppException('Server error. Please try again shortly.',
        statusCode: statusCode);
  }

  return AppException(fallbackMessage, statusCode: statusCode, cause: exception);
}

String userMessageFromError(
  Object error, {
  String fallbackMessage = 'Something went wrong. Please try again.',
}) {
  if (error is AppException) {
    return error.message;
  }
  if (_isSocketException(error)) {
    return 'No internet connection. Check your network and retry.';
  }
  if (error is TimeoutException) {
    return 'Request timed out. Please try again.';
  }
  return fallbackMessage;
}

bool _isSocketException(Object? error) =>
    error?.runtimeType.toString() == 'SocketException';
