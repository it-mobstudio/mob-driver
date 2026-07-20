import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';

/// Mirrors web's getStoreOpenDeliveryMessage (Functions/reusableFunction.js):
/// trust the backend's raw message regardless of open/closed state, only
/// falling back to the generic estimate when the message is empty or the
/// API's generic placeholder ("Store open status fetched") — no hardcoded
/// "Currently closed" override.
String storeDeliveryLabel(
  StoreOpenStatusEntity? status, {
  String fallback = '1-4 hrs',
}) {
  if (status == null) return '';

  final message = status.message.trim();
  final isGenericMessage = message.toLowerCase() == 'store open status fetched';
  final resolved = (message.isEmpty || isGenericMessage) ? fallback : message;

  return resolved == fallback ? '$resolved delivery' : resolved;
}

({String title, String subtitle}) storeClosedDeliveryParts(
  StoreOpenStatusEntity? status,
) {
  final message = status?.message.trim() ?? '';
  if (message.isEmpty) return (title: 'Currently closed', subtitle: '');

  final afterMatch =
      RegExp(r'\bafter\b', caseSensitive: false).firstMatch(message);
  if (afterMatch == null) return (title: message, subtitle: '');

  final title = message.substring(0, afterMatch.start).trim();
  final afterClause = message.substring(afterMatch.start).trim();
  return (
    title: title.isEmpty ? message : title,
    subtitle: 'Scheduled $afterClause',
  );
}
