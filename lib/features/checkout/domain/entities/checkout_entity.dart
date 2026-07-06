import 'package:m_o_b_demand_side/shared/image_url.dart';

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

class RazorpayOrderEntity {
  const RazorpayOrderEntity({
    required this.razorpayOrderId,
    required this.platformOrderId,
    required this.key,
    required this.amount,
    required this.currency,
    this.name = 'MOB',
  });

  final String razorpayOrderId;
  final String platformOrderId;
  final String key;
  final int amount;
  final String currency;
  final String name;

  factory RazorpayOrderEntity.fromMap(Map<String, dynamic> map) {
    final amountRaw =
        (map['amount'] ?? map['amount_in_paise'] ?? 0);
    final amountDouble =
        amountRaw is num ? amountRaw.toDouble() : double.tryParse(amountRaw.toString()) ?? 0.0;
    // API returns rupees; Razorpay SDK expects paise (integer)
    final amountPaise = (amountDouble * 100).round();

    return RazorpayOrderEntity(
      razorpayOrderId:
          (map['razorpay_id'] ?? map['razorpay_order_id'] ?? map['id'] ?? '').toString(),
      platformOrderId:
          (map['order_id'] ?? map['mob_order_id'] ?? map['platform_order_id'] ?? '').toString(),
      key: (map['key'] ?? map['key_id'] ?? '').toString(),
      amount: amountPaise,
      currency: (map['currency'] ?? 'INR').toString(),
      name: (map['name'] ?? 'MOB').toString(),
    );
  }
}

class RupifiOrderEntity {
  const RupifiOrderEntity({required this.paymentUrl});

  final String paymentUrl;

  factory RupifiOrderEntity.fromMap(Map<String, dynamic> map) {
    return RupifiOrderEntity(
      paymentUrl: (map['payment_url'] ?? '').toString(),
    );
  }
}

class PlacedOrderProductEntity {
  const PlacedOrderProductEntity({
    required this.productName,
    required this.imageUrl,
    required this.mobSku,
    required this.vendor,
    required this.price,
    required this.quantity,
  });

  final String productName;
  final String imageUrl;
  final String mobSku;
  final String vendor;
  final double price;
  final int quantity;

  factory PlacedOrderProductEntity.fromMap(Map<String, dynamic> map) {
    final product = map['product'] is Map
        ? Map<String, dynamic>.from(map['product'] as Map)
        : map;
    return PlacedOrderProductEntity(
      productName: (product['product_name'] ?? '').toString(),
      imageUrl: sanitizeImageUrl((product['product_image'] ?? '').toString()),
      mobSku: (product['mob_sku'] ?? '').toString(),
      vendor: (product['vendor'] ?? '').toString(),
      price: double.tryParse(
            (map['price_after_tax'] ?? product['vendor_selling_price'] ?? '0').toString(),
          ) ??
          0,
      quantity: int.tryParse((map['quantity'] ?? '1').toString()) ?? 1,
    );
  }
}

class PlacedOrderAddressEntity {
  const PlacedOrderAddressEntity({
    required this.name,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
  });

  final String name;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;

  String get fullAddress => [
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
      ].where((e) => e.trim().isNotEmpty).join(', ');

  factory PlacedOrderAddressEntity.fromMap(Map<String, dynamic> map) {
    return PlacedOrderAddressEntity(
      name: (map['name'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ?? '').toString(),
      addressLine1: (map['address_line_1'] ?? '').toString(),
      addressLine2: (map['address_line_2'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      pincode: (map['pincode'] ?? '').toString(),
    );
  }
}

class PlacedOrderPaymentEntity {
  const PlacedOrderPaymentEntity({required this.gateway, required this.amount});

  final String gateway;
  final double amount;

  factory PlacedOrderPaymentEntity.fromMap(Map<String, dynamic> map) {
    return PlacedOrderPaymentEntity(
      gateway: (map['payment_gateway'] ?? '').toString(),
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0,
    );
  }
}

class PlacedOrderPointsEntity {
  const PlacedOrderPointsEntity({required this.totalPoints, required this.message});

  final int totalPoints;
  final String message;

  factory PlacedOrderPointsEntity.fromMap(Map<String, dynamic> map) {
    return PlacedOrderPointsEntity(
      totalPoints: int.tryParse((map['total_points'] ?? '0').toString()) ?? 0,
      message: (map['message'] ?? '').toString(),
    );
  }
}

class PlacedSubOrderEntity {
  const PlacedSubOrderEntity({
    required this.suborderId,
    required this.vendorName,
    required this.subTotal,
    required this.total,
    required this.status,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.products,
  });

  final String suborderId;
  final String vendorName;
  final double subTotal;
  final double total;
  final String status;
  final String deliveryDate;
  final String deliverySlot;
  final List<PlacedOrderProductEntity> products;

  factory PlacedSubOrderEntity.fromMap(Map<String, dynamic> map) {
    final productsRaw = map['products'] is List ? map['products'] as List : <dynamic>[];
    return PlacedSubOrderEntity(
      suborderId: (map['suborder_id'] ?? '').toString(),
      vendorName: (map['vendor_name'] ?? '').toString(),
      subTotal: double.tryParse((map['sub_total'] ?? '0').toString()) ?? 0,
      total: double.tryParse((map['total'] ?? '0').toString()) ?? 0,
      status: (map['status'] ?? '').toString(),
      deliveryDate: (map['delivery_date'] ?? '').toString(),
      deliverySlot: (map['delivery_slot'] ?? '').toString(),
      products: productsRaw
          .whereType<Map>()
          .map((e) => PlacedOrderProductEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PlacedOrderEntity {
  const PlacedOrderEntity({
    required this.orderId,
    required this.orderNumber,
    required this.message,
    this.numericId = '',
    this.status = '',
    this.createdAt = '',
    this.total = 0,
    this.subTotal = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.shippingFee = 0,
    this.deliveryAddress,
    this.items = const [],
    this.payments = const [],
    this.pointsSummary,
    this.suborders = const [],
  });

  final String orderId;
  final String orderNumber;
  final String message;
  final String numericId;
  final String status;
  final String createdAt;
  final double total;
  final double subTotal;
  final double sgst;
  final double cgst;
  final double shippingFee;
  final PlacedOrderAddressEntity? deliveryAddress;
  final List<PlacedOrderProductEntity> items;
  final List<PlacedOrderPaymentEntity> payments;
  final PlacedOrderPointsEntity? pointsSummary;
  final List<PlacedSubOrderEntity> suborders;

  factory PlacedOrderEntity.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'] is List ? map['items'] as List : <dynamic>[];
    final paymentsRaw = map['payments'] is List ? map['payments'] as List : <dynamic>[];
    final suborderRaw = map['suborders'] is List ? map['suborders'] as List : <dynamic>[];
    final addressMap = map['delivery_address'] is Map
        ? Map<String, dynamic>.from(map['delivery_address'] as Map)
        : null;
    final pointsMap = map['order_points_summary'] is Map
        ? Map<String, dynamic>.from(map['order_points_summary'] as Map)
        : null;

    return PlacedOrderEntity(
      orderId: (map['order_id'] ?? map['id'] ?? '').toString(),
      orderNumber: (map['order_number'] ?? map['order_no'] ?? map['order_id'] ?? map['id'] ?? '').toString(),
      message: (map['message'] ?? 'Order placed successfully.').toString(),
      numericId: (map['id'] ?? '').toString(),
      status: (map['order_status'] ?? map['status'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      total: double.tryParse((map['total'] ?? '0').toString()) ?? 0,
      subTotal: double.tryParse((map['sub_total'] ?? '0').toString()) ?? 0,
      sgst: double.tryParse((map['sgst'] ?? '0').toString()) ?? 0,
      cgst: double.tryParse((map['cgst'] ?? '0').toString()) ?? 0,
      shippingFee: double.tryParse((map['shipping_fee'] ?? '0').toString()) ?? 0,
      deliveryAddress: addressMap != null ? PlacedOrderAddressEntity.fromMap(addressMap) : null,
      items: itemsRaw
          .whereType<Map>()
          .map((e) => PlacedOrderProductEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      payments: paymentsRaw
          .whereType<Map>()
          .map((e) => PlacedOrderPaymentEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      pointsSummary: pointsMap != null ? PlacedOrderPointsEntity.fromMap(pointsMap) : null,
      suborders: suborderRaw
          .whereType<Map>()
          .map((e) => PlacedSubOrderEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
