import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

sealed class AppFailure {
  const AppFailure(this.message, {this.code});
  final String message;

  /// Machine-readable reason from the backend (e.g. `INVALID_DELIVERY_OTP`,
  /// `ALREADY_PAID`) when it sent one, so callers can react to a specific
  /// rejection instead of string-matching [message].
  final String? code;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

final class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {this.statusCode, super.code});
  final int? statusCode;
}

final class AuthFailure extends AppFailure {
  const AuthFailure([
    super.message = 'Authentication required. Please log in.',
    String? code,
  ]) : super(code: code);
}

final class BusinessFailure extends AppFailure {
  const BusinessFailure(super.message, {super.code});
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
        return NetworkFailure(_networkMessage(this));
      case DioExceptionType.badCertificate:
        return const NetworkFailure('SSL certificate error.');
      case DioExceptionType.cancel:
        return const UnknownFailure('Request was cancelled.');
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final data = response?.data;
        final envelope = data is Map ? _parseErrorEnvelope(data) : null;

        if (statusCode == 401) {
          return AuthFailure(
            envelope?.message ?? 'Authentication required. Please log in.',
            envelope?.code,
          );
        }
        if (envelope != null) {
          // 4xx are the backend telling the driver why the action can't
          // happen (wrong OTP, trip already cancelled, ...) — show it as-is.
          // 5xx are our problem, not theirs.
          return (statusCode ?? 500) >= 500
              ? ServerFailure(envelope.message,
                  statusCode: statusCode, code: envelope.code)
              : BusinessFailure(envelope.message, code: envelope.code);
        }
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
          return NetworkFailure(_networkMessage(this));
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

/// What a driver sees when the server can't be reached. In debug builds it also
/// says *which* server and the usual causes — because the generic text is a
/// poor guide for a developer: a browser blocking the response over CORS, or an
/// emulator that can't see `localhost`, both surface as "no internet" even
/// though the network is fine.
String _networkMessage(DioException e) {
  const generic = 'No internet connection. Please check your network.';
  if (!kDebugMode) return generic;
  final host = e.requestOptions.uri.authority;
  final hint = kIsWeb
      ? 'In a browser this is also what a CORS block looks like: the backend '
          'must send Access-Control-Allow-Origin (it does when DEBUG=True).'
      : 'Is the backend running, and reachable from this device? (Android '
          'emulator: 10.0.2.2; a real phone: your computer\'s LAN IP, and '
          'runserver on 0.0.0.0.)';
  return '$generic\n\n[debug] Could not reach $host. $hint';
}

class _ErrorEnvelope {
  const _ErrorEnvelope(this.message, this.code);
  final String message;
  final String? code;
}

/// The backend renders every error as
/// `{"success": false, "error": {"code", "message", "details"?}}`.
/// For field-validation errors `message` is a generic "Request could not be
/// processed." and the useful text lives in `details`
/// (`{"otp": ["OTP must be exactly 4 digits."]}`), so prefer that.
_ErrorEnvelope? _parseErrorEnvelope(Map<dynamic, dynamic> body) {
  final error = body['error'];
  if (error is! Map) return null;

  final code = error['code']?.toString();
  final detailMessage = _firstDetailMessage(error['details']);
  final message = detailMessage ?? error['message']?.toString().trim() ?? '';
  return _ErrorEnvelope(
    message.isEmpty ? 'Something went wrong. Please try again.' : message,
    code,
  );
}

String? _firstDetailMessage(dynamic details, [String? field]) {
  if (details is String) {
    final text = details.trim();
    if (text.isEmpty) return null;
    // DRF's "This field is required." is meaningless without the field name.
    if (field != null &&
        field != 'non_field_errors' &&
        text.startsWith('This field')) {
      return '${_humanize(field)}: $text';
    }
    return text;
  }
  if (details is List) {
    for (final item in details) {
      final found = _firstDetailMessage(item, field);
      if (found != null) return found;
    }
  }
  if (details is Map) {
    for (final entry in details.entries) {
      final found = _firstDetailMessage(entry.value, entry.key.toString());
      if (found != null) return found;
    }
  }
  return null;
}

String _humanize(String field) {
  final spaced = field.replaceAll('_', ' ').trim();
  return spaced.isEmpty
      ? field
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
