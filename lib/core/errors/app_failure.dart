import 'package:dio/dio.dart';
import 'package:mob_driver/core/l10n/tr.dart';

sealed class AppFailure {
  const AppFailure(this._message, {this.code});

  final String _message;

  /// Backend error code, e.g. `INVALID_DELIVERY_OTP`.
  final String? code;

  String get message => tr(_message);
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
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}

extension DioExceptionMapper on DioException {
  AppFailure toAppFailure() => switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout ||
        DioExceptionType.connectionError =>
          const NetworkFailure(),
        DioExceptionType.badCertificate =>
          const NetworkFailure('SSL certificate error.'),
        DioExceptionType.cancel =>
          const UnknownFailure('Request was cancelled.'),
        DioExceptionType.badResponse => _fromResponse(),
        DioExceptionType.unknown => _fromUnknown(),
      };

  AppFailure _fromResponse() {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final body = data is Map ? data : const <dynamic, dynamic>{};
    final error = _parseError(body);

    if (statusCode == 401) {
      return error == null
          ? const AuthFailure()
          : AuthFailure(error.message, error.code);
    }
    if (error != null) {
      return (statusCode ?? 500) >= 500
          ? ServerFailure(error.message,
              statusCode: statusCode, code: error.code)
          : BusinessFailure(error.message, code: error.code);
    }

    final message = body['message']?.toString().trim() ?? '';
    if (message.isNotEmpty) {
      return body['status'] == false
          ? BusinessFailure(message)
          : ServerFailure(message, statusCode: statusCode);
    }
    return ServerFailure(
      tr('Server error ({p0}).', {'p0': statusCode ?? 'unknown'}),
      statusCode: statusCode,
    );
  }

  AppFailure _fromUnknown() {
    final details = error?.toString() ?? '';
    if (details.contains('SocketException') ||
        details.contains('Connection refused') ||
        details.contains('Network is unreachable')) {
      return const NetworkFailure();
    }
    final text = message ?? '';
    return text.isEmpty ? const UnknownFailure() : UnknownFailure(text);
  }
}

/// Reads `{"error": {"code", "message", "details"?}}`, preferring the first
/// field-level message in `details` over the generic `message`.
({String message, String? code})? _parseError(Map<dynamic, dynamic> body) {
  final error = body['error'];
  if (error is! Map) return null;

  final message = _firstDetail(error['details']) ??
      error['message']?.toString().trim() ??
      '';
  return (
    message:
        message.isEmpty ? 'Something went wrong. Please try again.' : message,
    code: error['code']?.toString(),
  );
}

String? _firstDetail(dynamic details, [String? field]) {
  if (details is String) {
    final text = details.trim();
    if (text.isEmpty) return null;
    if (field != null &&
        field != 'non_field_errors' &&
        text.startsWith('This field')) {
      return '${_humanize(field)}: $text';
    }
    return text;
  }
  final children = switch (details) {
    List() => details.map((item) => _firstDetail(item, field)),
    Map() => details.entries
        .map((entry) => _firstDetail(entry.value, entry.key.toString())),
    _ => const <String?>[],
  };
  return children.firstWhere((text) => text != null, orElse: () => null);
}

String _humanize(String field) {
  final spaced = field.replaceAll('_', ' ').trim();
  return spaced.isEmpty
      ? field
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
