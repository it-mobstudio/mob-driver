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
      productName: (map['product_name'] ?? map['name'] ?? map['title'] ?? '').toString(),
      quantity: int.tryParse((map['quantity'] ?? map['qty'] ?? '1').toString()) ?? 1,
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
    final itemsRaw = map['items'] is List ? map['items'] as List : <dynamic>[];
    return RfqEntity(
      id: (map['id'] ?? map['rfq_id'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      items: itemsRaw
          .whereType<Map>()
          .map((e) => RfqItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      totalAmount:
          double.tryParse((map['total'] ?? map['total_amount'] ?? '0').toString()) ?? 0,
    );
  }
}
