import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';

abstract interface class RfqRemoteDatasource {
  Future<dynamic> getRfqList();
  Future<Map<String, dynamic>> getRfqDetail(String id);
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> submitMagicQuote({
    required Map<String, dynamic> payload,
    required List<FFUploadedFile> images,
  });
}

class RfqRemoteDatasourceImpl implements RfqRemoteDatasource {
  RfqRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getRfqList() async {
    final response = await _dio.get<dynamic>(
      '/rfq/get_rfqs/',
      queryParameters: {'page': 1},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getRfqDetail(String id) async {
    final response = await _dio.get<dynamic>('/rfq/$id/get_rfq_details/');
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
    required List<FFUploadedFile> images,
  }) async {
    if (images.isEmpty) {
      throw ArgumentError('Magic Quote image is required.');
    }

    final formData = FormData();
    formData.fields.addAll(
      payload.entries.map(
        (entry) => MapEntry(entry.key, entry.value?.toString() ?? ''),
      ),
    );
    for (final image in images) {
      final bytes = image.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      formData.files.add(
        MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name ?? 'magic-quote-upload',
          ),
        ),
      );
    }
    if (formData.files.isEmpty) {
      throw ArgumentError('Unable to read the selected Magic Quote files.');
    }
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
