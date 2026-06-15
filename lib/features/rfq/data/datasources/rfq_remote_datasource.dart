import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';

abstract interface class RfqRemoteDatasource {
  Future<dynamic> getRfqList();
  Future<Map<String, dynamic>> getRfqDetail(String id);
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> submitMagicQuote({
    required Map<String, dynamic> payload,
    required FFUploadedFile image,
  });
}

class RfqRemoteDatasourceImpl implements RfqRemoteDatasource {
  RfqRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getRfqList() async {
    final response = await _dio.get<dynamic>('/rfq/');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getRfqDetail(String id) async {
    final response = await _dio.get<dynamic>('/rfq/$id/');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>('/rfq/submit/', data: payload);
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> submitMagicQuote({
    required Map<String, dynamic> payload,
    required FFUploadedFile image,
  }) async {
    final bytes = image.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw ArgumentError('Magic Quote image is required.');
    }

    final formData = FormData.fromMap({
      ...payload,
      'image': MultipartFile.fromBytes(
        bytes,
        filename: image.name ?? 'magic-quote-upload',
      ),
    });
    final response = await _dio.post<dynamic>(
      '/quote-builder/magic-quote/',
      data: formData,
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{'data': raw};
  }
}
