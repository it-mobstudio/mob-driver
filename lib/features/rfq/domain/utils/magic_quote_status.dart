/// Shared helpers for parsing Magic Quote create-API responses and
/// `magic_quote_status` websocket messages. Mirrors the web app's
/// `MagicQuote/utils.js`, which already handles the backend's various
/// nesting shapes (`payload.data`, `data.data`, etc.) in production.
library;

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic>? _nestedMap(
  Map<String, dynamic>? map,
  String key1,
  String key2,
) {
  return _asMap(_asMap(map?[key1])?[key2]);
}

bool _looksLikeRfqOrder(Map<String, dynamic> value) {
  return value['rfq_id'] != null || value['id'] != null;
}

/// Extracts the `{rfq_order, quote, items, ...}` payload from a create-API
/// response or a socket message, regardless of how deeply it's nested.
Map<String, dynamic> magicQuotePayloadOf(Map<String, dynamic>? response) {
  if (response == null) return const <String, dynamic>{};
  final payload = _nestedMap(response, 'payload', 'data') ??
      _asMap(response['payload']) ??
      _nestedMap(response, 'data', 'data') ??
      _asMap(response['data']) ??
      response;
  if (payload['rfq_order'] != null ||
      payload['quote'] != null ||
      payload['items'] is List) {
    return payload;
  }
  if (_looksLikeRfqOrder(payload)) {
    return {'rfq_order': payload, 'quote': null, 'items': const <dynamic>[]};
  }
  return payload;
}

dynamic _stringStatusOf(Map<String, dynamic>? map) {
  final value = map?['status'];
  return value is String ? value : null;
}

/// The human-readable progress label (e.g. "Reading text", "Fetching prices").
String magicQuoteStatusOf(Map<String, dynamic>? message) {
  if (message == null) return '';
  final payload = _asMap(message['payload']);
  final data = _asMap(message['data']);
  final candidates = <dynamic>[
    message['current_status'],
    _stringStatusOf(message),
    message['status_text'],
    payload?['current_status'],
    _stringStatusOf(payload),
    payload?['status_text'],
    data?['current_status'],
    _stringStatusOf(data),
    data?['status_text'],
  ];
  for (final candidate in candidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }
  return '';
}

/// The request id used to filter out unrelated broadcasts on a shared socket.
String magicQuoteRequestIdOf(Map<String, dynamic>? message) {
  if (message == null) return '';
  final payload = _asMap(message['payload']);
  final data = _asMap(message['data']);
  final candidates = <dynamic>[
    message['request_id'],
    message['websocket_key'],
    payload?['request_id'],
    payload?['websocket_key'],
    _asMap(payload?['data'])?['request_id'],
    _asMap(payload?['data'])?['websocket_key'],
    data?['request_id'],
    data?['websocket_key'],
  ];
  for (final candidate in candidates) {
    final text = candidate?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// `true` while the backend is still working, `false` once the final result
/// (success or "no items found") is ready, `null` if the message doesn't
/// carry this field at all (older/non-status messages).
bool? magicQuoteIsProcessingOf(Map<String, dynamic>? message) {
  if (message == null) return null;
  final payload = _asMap(message['payload']);
  final data = _asMap(message['data']);
  final candidates = <dynamic>[
    message['is_processing'],
    payload?['is_processing'],
    _asMap(payload?['data'])?['is_processing'],
    data?['is_processing'],
  ];
  for (final candidate in candidates) {
    if (candidate is bool) return candidate;
  }
  return null;
}

/// The websocket connection identifier returned by the create API, if any.
String magicQuoteWebsocketKeyOf(Map<String, dynamic>? response) {
  final payload = magicQuotePayloadOf(response);
  final candidate = payload['websocket_key'] ?? response?['websocket_key'];
  return candidate?.toString().trim() ?? '';
}

/// A fully-qualified websocket URL returned by the create API, if any.
String magicQuoteWebsocketUrlOf(Map<String, dynamic>? response) {
  final payload = magicQuotePayloadOf(response);
  final candidate = payload['websocket_url'] ?? response?['websocket_url'];
  return candidate?.toString().trim() ?? '';
}

/// `true` once the payload contains a quote with at least one matched item.
bool magicQuoteHasGeneratedItems(Map<String, dynamic>? response) {
  final payload = magicQuotePayloadOf(response);
  final items = payload['items'];
  return payload['quote'] != null && items is List && items.isNotEmpty;
}
