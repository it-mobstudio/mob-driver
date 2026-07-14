import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';

String storeDeliveryLabel(StoreOpenStatusEntity? status) {
  if (status == null) return '';

  final message = status.message.trim();
  if (!status.isOpen) {
    return 'Currently closed';
  }
  if (message.isEmpty) return '';
  return '$message delivery';
}
