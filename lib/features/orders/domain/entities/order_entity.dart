class OrderItemEntity {
  const OrderItemEntity({
    required this.title,
    required this.imageUrl,
    required this.qty,
    required this.unitPrice,
    required this.mobSku,
  });

  final String title;
  final String imageUrl;
  final int qty;
  final double unitPrice;
  final String mobSku;

  double get lineTotal => unitPrice * qty;

  factory OrderItemEntity.fromMap(Map<String, dynamic> map) {
    return OrderItemEntity(
      title: (map['item_name_title'] ?? map['title'] ?? map['name'] ?? '').toString(),
      imageUrl: (map['image'] ?? map['product_image'] ?? '').toString(),
      qty: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: double.tryParse(
            (map['vendor_selling_price'] ?? map['selling_price'] ?? map['price'] ?? '0').toString(),
          ) ??
          0,
      mobSku: (map['mob_sku'] ?? '').toString(),
    );
  }
}

class OrderEntity {
  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.items,
    required this.shippingAddress,
    this.pointsEarned = 0,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String createdAt;
  final double total;
  final List<OrderItemEntity> items;
  final String shippingAddress;
  final int pointsEarned;

  factory OrderEntity.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'] is List ? map['items'] as List : <dynamic>[];
    final addr = map['shipping_address'] is Map
        ? Map<String, dynamic>.from(map['shipping_address'] as Map)
        : <String, dynamic>{};
    final addrParts = [
      addr['address_line_1']?.toString() ?? '',
      addr['city']?.toString() ?? '',
      addr['state']?.toString() ?? '',
      addr['pincode']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    return OrderEntity(
      id: (map['id'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? map['order_no'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? map['order_status'] ?? '').toString(),
      createdAt: (map['created_at'] ?? map['date'] ?? '').toString(),
      total: double.tryParse(
            (map['total'] ?? map['order_total'] ?? map['grand_total'] ?? '0').toString(),
          ) ??
          0,
      items: itemsRaw
          .whereType<Map>()
          .map((e) => OrderItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      shippingAddress: addrParts.join(', '),
      pointsEarned: int.tryParse(
            (map['points_earned'] ?? map['reward_points_earned'] ?? map['mobstar_points_earned'] ?? '0').toString(),
          ) ??
          0,
    );
  }
}
