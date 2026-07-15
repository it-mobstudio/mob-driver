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
  final isGenericMessage =
      message.toLowerCase() == 'store open status fetched';
  final resolved = (message.isEmpty || isGenericMessage) ? fallback : message;

  return resolved == fallback ? '$resolved delivery' : resolved;
}
