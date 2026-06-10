class CheckoutSummaryEntity {
  const CheckoutSummaryEntity({
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.shippingAddress,
    required this.paymentMethods,
  });

  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final String shippingAddress;
  final List<String> paymentMethods;

  factory CheckoutSummaryEntity.fromMap(Map<String, dynamic> map) {
    final addrRaw = map['shipping_address'] is Map
        ? Map<String, dynamic>.from(map['shipping_address'] as Map)
        : <String, dynamic>{};
    final addrParts = [
      addrRaw['address_line_1']?.toString() ?? '',
      addrRaw['city']?.toString() ?? '',
      addrRaw['state']?.toString() ?? '',
      addrRaw['pincode']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();

    final paymentRaw = map['payment_methods'] is List
        ? (map['payment_methods'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return CheckoutSummaryEntity(
      subtotal: double.tryParse(
            (map['subtotal'] ?? map['sub_total'] ?? '0').toString(),
          ) ??
          0,
      shipping: double.tryParse(
            (map['shipping'] ?? map['shipping_charge'] ?? '0').toString(),
          ) ??
          0,
      tax: double.tryParse((map['tax'] ?? '0').toString()) ?? 0,
      total: double.tryParse(
            (map['total'] ?? map['grand_total'] ?? '0').toString(),
          ) ??
          0,
      shippingAddress: addrParts.join(', '),
      paymentMethods: paymentRaw,
    );
  }
}

class PlacedOrderEntity {
  const PlacedOrderEntity({
    required this.orderId,
    required this.orderNumber,
    required this.message,
  });

  final String orderId;
  final String orderNumber;
  final String message;

  factory PlacedOrderEntity.fromMap(Map<String, dynamic> map) {
    return PlacedOrderEntity(
      orderId: (map['id'] ?? map['order_id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? map['order_no'] ?? map['id'] ?? '').toString(),
      message: (map['message'] ?? 'Order placed successfully.').toString(),
    );
  }
}
