import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';

DioException _bad(int status, dynamic body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  test('a domain error (409) surfaces the backend message and code', () {
    final failure = _bad(409, {
      'success': false,
      'error': {
        'code': 'VEHICLE_IN_USE',
        'message': 'This vehicle is being used by another driver.',
      },
    }).toAppFailure();

    expect(failure, isA<BusinessFailure>());
    expect(failure.message, 'This vehicle is being used by another driver.');
    expect(failure.code, 'VEHICLE_IN_USE');
  });

  test('a wrong delivery OTP (400) keeps its code so the UI can react to it', () {
    final failure = _bad(400, {
      'success': false,
      'error': {'code': 'INVALID_DELIVERY_OTP', 'message': 'The delivery OTP is invalid or has expired.'},
    }).toAppFailure();
    expect(failure.code, 'INVALID_DELIVERY_OTP');
  });

  test('field-validation details win over the generic message', () {
    final failure = _bad(400, {
      'success': false,
      'error': {
        'code': 'INVALID',
        'message': 'Request could not be processed.',
        'details': {'otp': ['OTP must be exactly 6 digits.']},
      },
    }).toAppFailure();
    expect(failure.message, 'OTP must be exactly 6 digits.');
  });

  test('"This field is required." is prefixed with the field so it makes sense', () {
    final failure = _bad(400, {
      'success': false,
      'error': {
        'code': 'REQUIRED',
        'message': 'Request could not be processed.',
        'details': {'reason': ['This field is required.']},
      },
    }).toAppFailure();
    expect(failure.message, 'Reason: This field is required.');
  });

  test('401 is an AuthFailure', () {
    final failure = _bad(401, {
      'success': false,
      'error': {'code': 'INVALID_REFRESH_TOKEN', 'message': 'Your session has expired. Please sign in again.'},
    }).toAppFailure();
    expect(failure, isA<AuthFailure>());
    expect(failure.code, 'INVALID_REFRESH_TOKEN');
  });

  test('a 5xx is a ServerFailure, not something to blame the driver for', () {
    final failure = _bad(503, {
      'success': false,
      'error': {'code': 'ROUTING_UNAVAILABLE', 'message': 'Could not compute a route for this pickup/drop pair.'},
    }).toAppFailure();
    expect(failure, isA<ServerFailure>());
    expect((failure as ServerFailure).statusCode, 503);
  });

  test('a non-JSON error page falls back to a generic message', () {
    final failure = _bad(502, '<html>Bad gateway</html>').toAppFailure();
    expect(failure.message, 'Server error (502).');
  });

  test('legacy {status:false, message} bodies still work', () {
    final failure = _bad(400, {'status': false, 'message': 'Nope'}).toAppFailure();
    expect(failure, isA<BusinessFailure>());
    expect(failure.message, 'Nope');
  });

  test('in debug builds a connection failure names the server it could not reach', () {
    final failure = DioException(
      requestOptions: RequestOptions(path: '/driver/auth/otp/request', baseUrl: 'http://127.0.0.1:8000/api/v1/'),
      type: DioExceptionType.connectionError,
    ).toAppFailure();

    expect(failure, isA<NetworkFailure>());
    expect(failure.message, startsWith('No internet connection.'), reason: 'the driver-facing text is unchanged');
    expect(failure.message, contains('127.0.0.1:8000'));
  });

  test('connection problems are NetworkFailures', () {
    final failure = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    ).toAppFailure();
    expect(failure, isA<NetworkFailure>());
  });
}
