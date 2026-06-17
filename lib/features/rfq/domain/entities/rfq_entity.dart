class RfqItemEntity {
  const RfqItemEntity({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.notes,
    required this.imageUrl,
  });

  final String productName;
  final int quantity;
  final String unit;
  final String notes;
  final String imageUrl;

  factory RfqItemEntity.fromMap(Map<String, dynamic> map) {
    return RfqItemEntity(
      productName:
          (map['product_name'] ?? map['name'] ?? map['title'] ?? '').toString(),
      quantity:
          int.tryParse((map['quantity'] ?? map['qty'] ?? '1').toString()) ?? 1,
      unit: (map['unit'] ?? map['uom'] ?? '').toString(),
      notes: (map['notes'] ?? map['description'] ?? '').toString(),
      imageUrl: (map['image'] ?? map['product_image'] ?? '').toString(),
    );
  }
}

class RfqEntity {
  const RfqEntity({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
  });

  final String id;
  final String status;
  final String createdAt;
  final List<RfqItemEntity> items;
  final double totalAmount;

  factory RfqEntity.fromMap(Map<String, dynamic> map) {
    final itemsRaw = switch (map['items'] ??
        map['products'] ??
        map['rfq_items'] ??
        map['quote_items']) {
      final List value => value,
      _ => <dynamic>[],
    };
    return RfqEntity(
      id: (map['id'] ??
              map['rfq_id'] ??
              map['rfq_number'] ??
              map['rfq_no'] ??
              map['quote_id'] ??
              '')
          .toString(),
      status: (map['status'] ?? map['rfq_status'] ?? 'pending').toString(),
      createdAt: (map['created_at'] ??
              map['created_on'] ??
              map['requested_at'] ??
              map['date'] ??
              '')
          .toString(),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => RfqItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      totalAmount: double.tryParse((map['total'] ??
                  map['total_amount'] ??
                  map['amount'] ??
                  map['quote_total'] ??
                  '0')
              .toString()) ??
          0,
    );
  }
}
