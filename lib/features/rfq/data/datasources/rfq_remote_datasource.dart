import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/utils/magic_quote_status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract interface class RfqRemoteDatasource {
  Future<dynamic> getRfqList();
  Future<Map<String, dynamic>> getRfqDetail(String id);
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> submitMagicQuote({
    required Map<String, dynamic> payload,
    required List<FFUploadedFile> images,
  });

  /// Streams `magic_quote_status` updates for the request that produced
  /// [acceptedResponse]. Emits one decoded message per status update,
  /// including the terminal one (`is_processing: false`), then closes.
  Stream<Map<String, dynamic>> watchMagicQuoteStatus({
    required Map<String, dynamic> acceptedResponse,
    required String phoneNumber,
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
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/orders/rfq_quotecreate_offline/',
      data: payload,
    );
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

  static const _maxSocketReconnects = 5;
  static const _socketOverallTimeout = Duration(seconds: 120);

  @override
  Stream<Map<String, dynamic>> watchMagicQuoteStatus({
    required Map<String, dynamic> acceptedResponse,
    required String phoneNumber,
  }) {
    final socketUri = _magicQuoteSocketUri(
      websocketKey: magicQuoteWebsocketKeyOf(acceptedResponse),
      websocketUrl: magicQuoteWebsocketUrlOf(acceptedResponse),
      phoneNumber: phoneNumber,
    );
    if (socketUri == null) {
      return Stream.error(
        StateError('Unable to connect to Magic Quote updates.'),
      );
    }
    final acceptedRequestId = magicQuoteRequestIdOf(acceptedResponse);

    late StreamController<Map<String, dynamic>> controller;
    WebSocketChannel? channel;
    StreamSubscription<dynamic>? subscription;
    Timer? overallTimeoutTimer;
    Timer? reconnectTimer;
    var reconnectCount = 0;
    var isDone = false;

    void cleanup() {
      reconnectTimer?.cancel();
      subscription?.cancel();
      channel?.sink.close();
    }

    void finish({Object? error}) {
      if (isDone) return;
      isDone = true;
      overallTimeoutTimer?.cancel();
      cleanup();
      if (error != null) controller.addError(error);
      controller.close();
    }

    void connect() {
      if (isDone) return;
      try {
        channel = WebSocketChannel.connect(socketUri);
      } catch (error) {
        finish(error: error);
        return;
      }
      subscription = channel!.stream.listen(
        (raw) {
          if (isDone) return;
          final message = _decodeSocketMessage(raw);
          if (message == null) return;
          final messageRequestId = magicQuoteRequestIdOf(message);
          if (acceptedRequestId.isNotEmpty &&
              messageRequestId.isNotEmpty &&
              messageRequestId != acceptedRequestId) {
            return;
          }
          controller.add(message);
          if (magicQuoteIsProcessingOf(message) == false) {
            finish();
          }
        },
        onError: (_) {},
        onDone: () {
          if (isDone) return;
          if (reconnectCount >= _maxSocketReconnects) {
            finish(
              error: StateError(
                'Magic Quote updates are temporarily unavailable.',
              ),
            );
            return;
          }
          reconnectCount += 1;
          reconnectTimer = Timer(
            Duration(milliseconds: (reconnectCount * 1000).clamp(0, 5000)),
            connect,
          );
        },
      );
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        overallTimeoutTimer = Timer(_socketOverallTimeout, () {
          finish(
            error: StateError(
              'Magic Quote is taking longer than expected. Please try again.',
            ),
          );
        });
        connect();
      },
      onCancel: () {
        isDone = true;
        overallTimeoutTimer?.cancel();
        cleanup();
      },
    );
    return controller.stream;
  }

  Uri? _magicQuoteSocketUri({
    required String websocketKey,
    required String websocketUrl,
    required String phoneNumber,
  }) {
    if (websocketUrl.isNotEmpty) {
      return _toAbsoluteSocketUri(websocketUrl);
    }
    final digitsPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final identifier = websocketKey.isNotEmpty ? websocketKey : digitsPhone;
    if (identifier.isEmpty) return null;
    return _toAbsoluteSocketUri('/ws/magic-quote/$identifier/');
  }

  Uri? _toAbsoluteSocketUri(String value) {
    if (value.startsWith('ws://') || value.startsWith('wss://')) {
      return Uri.tryParse(value);
    }
    final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
    if (apiUri == null) return null;
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    final path = value.startsWith('/') ? value : '/$value';
    return Uri(
      scheme: scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: path,
    );
  }

  Map<String, dynamic>? _decodeSocketMessage(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
