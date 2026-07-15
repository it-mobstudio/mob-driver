import 'dart:async';
import 'dart:convert';

import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderNotificationSocketDatasource {
  const OrderNotificationSocketDatasource();

  static const _maxReconnects = 5;

  Stream<List<OrderNotificationPreview>> watch({
    required String phoneNumber,
  }) {
    final socketUri = _socketUri(phoneNumber);
    if (socketUri == null) return const Stream.empty();

    late StreamController<List<OrderNotificationPreview>> controller;
    WebSocketChannel? channel;
    StreamSubscription<dynamic>? subscription;
    Timer? reconnectTimer;
    var reconnectCount = 0;
    var isClosed = false;

    void cleanup() {
      reconnectTimer?.cancel();
      subscription?.cancel();
      channel?.sink.close();
    }

    void connect() {
      if (isClosed) return;
      try {
        channel = WebSocketChannel.connect(socketUri);
      } catch (_) {
        return;
      }
      subscription = channel!.stream.listen(
        (raw) {
          reconnectCount = 0;
          final message = _decodeSocketMessage(raw);
          if (message == null) return;
          final orders = _notificationsFromMessage(message);
          if (orders.isNotEmpty && !controller.isClosed) {
            controller.add(orders);
          }
        },
        onError: (_) {},
        onDone: () {
          if (isClosed || reconnectCount >= _maxReconnects) return;
          reconnectCount += 1;
          reconnectTimer = Timer(
            Duration(
              milliseconds: (reconnectCount * 1000).clamp(1000, 5000).toInt(),
            ),
            connect,
          );
        },
      );
    }

    controller = StreamController<List<OrderNotificationPreview>>(
      onListen: connect,
      onCancel: () {
        isClosed = true;
        cleanup();
      },
    );
    return controller.stream;
  }

  Uri? _socketUri(String phoneNumber) {
    final digitsPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsPhone.isEmpty) return null;
    return _toAbsoluteSocketUri('/ws/notifications_$digitsPhone/');
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

  List<OrderNotificationPreview> _notificationsFromMessage(
    Map<String, dynamic> message,
  ) {
    final raw = _firstList([
      message['orders'],
      message['notifications'],
      message['order_notifications'],
      message['results'],
      _asMap(message['data'])?['orders'],
      _asMap(message['data'])?['notifications'],
      _asMap(message['payload'])?['orders'],
      _asMap(message['payload'])?['notifications'],
    ]);
    if (raw != null) {
      return raw
          .whereType<Map>()
          .map((item) => OrderNotificationPreview.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.title.isNotEmpty)
          .toList();
    }

    final single = _singleNotificationMap(message);
    if (single == null) return const [];
    final item = OrderNotificationPreview.fromMap(single);
    return item.title.isEmpty ? const [] : [item];
  }

  Map<String, dynamic>? _singleNotificationMap(Map<String, dynamic> message) {
    for (final candidate in [
      message,
      _asMap(message['data']),
      _asMap(message['payload']),
      _asMap(_asMap(message['data'])?['data']),
    ]) {
      if (candidate == null) continue;
      if (_hasNotificationKeys(candidate)) return candidate;
    }
    return null;
  }

  bool _hasNotificationKeys(Map<String, dynamic> map) {
    return map.containsKey('arriving_in') ||
        map.containsKey('order_status') ||
        map.containsKey('order_status_text') ||
        map.containsKey('status') ||
        map.containsKey('suborder_id') ||
        map.containsKey('sub_order_id');
  }

  List<dynamic>? _firstList(List<dynamic> values) {
    for (final value in values) {
      if (value is List) return value;
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class OrderNotificationPreview {
  const OrderNotificationPreview({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.orderId,
    required this.suborderId,
  });

  final String title;
  final String subtitle;
  final String status;
  final String orderId;
  final String suborderId;

  factory OrderNotificationPreview.fromMap(Map<String, dynamic> map) {
    final status = _firstString([
      map['order_status'],
      map['status'],
      map['state'],
    ]);
    final title = _titleFrom(map, status);
    return OrderNotificationPreview(
      title: title,
      subtitle: _subtitleFrom(map),
      status: status,
      orderId: _firstString([map['order_id'], map['order_number']]),
      suborderId: _firstString([
        map['suborder_id'],
        map['sub_order_id'],
        map['sub_order_number'],
        map['shipment_id'],
      ]),
    );
  }

  static String _titleFrom(Map<String, dynamic> map, String status) {
    final arrivingIn = _firstString([
      map['arriving_in'],
      map['eta'],
      map['estimated_time'],
      map['delivery_time'],
    ]);
    if (arrivingIn.isNotEmpty) return 'Arriving in $arrivingIn';

    final text = _firstString([
      map['title'],
      map['order_status_text'],
      map['status_text'],
      map['message'],
      status,
    ]);
    if (text.isEmpty) return '';
    return _sentenceCase(text);
  }

  static String _subtitleFrom(Map<String, dynamic> map) {
    final firstItem = _firstItemName(map);
    final itemCount = _asInt(map['item_count'] ?? map['items_count']);
    if (firstItem.isEmpty) return itemCount > 0 ? '$itemCount items' : '';
    if (itemCount <= 1) return firstItem;
    return '$firstItem +${itemCount - 1} items';
  }

  static String _firstItemName(Map<String, dynamic> map) {
    final direct = _firstString([
      map['item_name'],
      map['product_name'],
      map['product'],
      map['first_item'],
    ]);
    if (direct.isNotEmpty) return direct;

    final items = map['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is String) return first;
      if (first is Map) {
        return _firstString([
          first['name'],
          first['product_name'],
          first['title'],
        ]);
      }
    }
    return '';
  }

  static String _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _sentenceCase(String text) {
    final clean = text.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return '';
    return clean[0].toUpperCase() + clean.substring(1);
  }
}
