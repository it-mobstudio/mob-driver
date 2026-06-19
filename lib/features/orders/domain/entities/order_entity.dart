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
    final product = map['product'] is Map
        ? Map<String, dynamic>.from(map['product'] as Map)
        : <String, dynamic>{};

    return OrderItemEntity(
      title: (map['item_name_title'] ??
              map['title'] ??
              map['name'] ??
              map['product_name'] ??
              product['product_name'] ??
              '')
          .toString(),
      imageUrl: (map['image'] ??
              map['product_image'] ??
              product['product_image'] ??
              '')
          .toString(),
      qty: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      unitPrice: double.tryParse(
            (map['vendor_selling_price'] ??
                    map['selling_price'] ??
                    map['price'] ??
                    map['price_after_tax'] ??
                    product['vendor_selling_price'] ??
                    product['selling_price'] ??
                    product['price'] ??
                    product['price_after_tax'] ??
                    '0')
                .toString(),
          ) ??
          0,
      mobSku: (map['mob_sku'] ?? product['mob_sku'] ?? '').toString(),
    );
  }
}

class OrderShipmentEntity {
  const OrderShipmentEntity({
    required this.id,
    required this.status,
    required this.deliveryDate,
    required this.items,
  });

  final String id;
  final String status;
  final String deliveryDate;
  final List<OrderItemEntity> items;

  factory OrderShipmentEntity.fromMap(Map<String, dynamic> map) {
    final productsRaw =
        map['products'] is List ? map['products'] as List : <dynamic>[];

    return OrderShipmentEntity(
      id: (map['suborder_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      deliveryDate: (map['delivery_date'] ?? '').toString(),
      items: productsRaw
          .whereType<Map>()
          .map((e) => OrderItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
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
    required this.projectName,
    required this.rewardMessage,
    required this.isQuickCommerceOrder,
    required this.shipments,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String createdAt;
  final double total;
  final List<OrderItemEntity> items;
  final String shippingAddress;
  final String projectName;
  final String rewardMessage;
  final bool isQuickCommerceOrder;
  final List<OrderShipmentEntity> shipments;

  factory OrderEntity.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'] is List ? map['items'] as List : <dynamic>[];
    final subordersRaw =
        map['suborders'] is List ? map['suborders'] as List : <dynamic>[];
    final addr = map['delivery_address'] is Map
        ? Map<String, dynamic>.from(map['delivery_address'] as Map)
        : map['shipping_address'] is Map
            ? Map<String, dynamic>.from(map['shipping_address'] as Map)
            : <String, dynamic>{};
    final addressProject = addr['project'] is Map
        ? Map<String, dynamic>.from(addr['project'] as Map)
        : <String, dynamic>{};
    final addrParts = [
      addr['address_line_1']?.toString() ?? '',
      addr['address_line_2']?.toString() ?? '',
      addr['city']?.toString() ?? '',
      addr['state']?.toString() ?? '',
      addr['pincode']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    final project = map['project'] is Map
        ? Map<String, dynamic>.from(map['project'] as Map)
        : <String, dynamic>{};
    final pointsSummary = map['order_points_summary'] is Map
        ? Map<String, dynamic>.from(map['order_points_summary'] as Map)
        : <String, dynamic>{};

    return OrderEntity(
      id: (map['order_id'] ??
              map['order_number'] ??
              map['order_no'] ??
              map['id'] ??
              '')
          .toString(),
      orderNumber: (map['order_id'] ??
              map['order_number'] ??
              map['order_no'] ??
              map['id'] ??
              '')
          .toString(),
      status: (map['status'] ?? map['order_status'] ?? '').toString(),
      createdAt: (map['created_at'] ?? map['date'] ?? '').toString(),
      total: double.tryParse(
            (map['total'] ?? map['order_total'] ?? map['grand_total'] ?? '0')
                .toString(),
          ) ??
          0,
      items: itemsRaw
          .whereType<Map>()
          .map((e) => OrderItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      shippingAddress: addrParts.join(', '),
      projectName: (addr['project_name'] ??
              addressProject['project_name'] ??
              addressProject['name'] ??
              project['project_name'] ??
              project['name'] ??
              map['project_name'] ??
              '')
          .toString(),
      rewardMessage: (pointsSummary['message'] ?? '').toString(),
      isQuickCommerceOrder: map['is_quick_commerce_order'] == true ||
          map['order_type']?.toString().toUpperCase() == 'QUICK_ORDER',
      shipments: subordersRaw
          .whereType<Map>()
          .map((e) => OrderShipmentEntity.fromMap(Map<String, dynamic>.from(e)))
          .where((shipment) => shipment.items.isNotEmpty)
          .toList(),
    );
  }
}
