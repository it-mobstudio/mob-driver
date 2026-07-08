import 'package:m_o_b_demand_side/shared/image_url.dart';

String orderStatusIconAsset(String status) {
  final s = status.toLowerCase();
  if (s.contains('delivered') && !s.contains('partially')) {
    return 'assets/images/orderdeliveredicon.svg';
  }
  if (s.contains('cancelled')) {
    return 'assets/images/cancelledIcon.svg';
  }
  if (s.contains('out for delivery') || s.contains('transit')) {
    return 'assets/images/outfordeliveryicon.svg';
  }
  if (s.contains('partially')) {
    return 'assets/images/partiallydelivered.svg';
  }
  return 'assets/images/packingicon.svg';
}

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
      imageUrl: sanitizeImageUrl(
        (map['image'] ??
                map['product_image'] ??
                product['product_image'] ??
                '')
            .toString(),
      ),
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

class OrderShipmentFileEntity {
  const OrderShipmentFileEntity({
    required this.id,
    required this.fileName,
    required this.fileUrl,
  });

  final String id;
  final String fileName;
  final String fileUrl;

  factory OrderShipmentFileEntity.fromMap(Map<String, dynamic> map) {
    return OrderShipmentFileEntity(
      id: (map['id'] ?? '').toString(),
      fileName: (map['file_name'] ?? '').toString(),
      fileUrl: sanitizeImageUrl((map['file'] ?? '').toString()),
    );
  }
}

class OrderShipmentEntity {
  const OrderShipmentEntity({
    required this.id,
    required this.status,
    required this.deliveryDate,
    required this.items,
    this.vendorName = '',
    this.deliverySlot = '',
    this.subTotal = 0,
    this.total = 0,
    this.proformaInvoiceUrl = '',
    this.vehicleAssigned = false,
    this.rewardPoints = 0,
    this.rewardMessage = '',
    this.files = const <OrderShipmentFileEntity>[],
    this.hasReview = false,
  });

  final String id;
  final String status;
  final String deliveryDate;
  final List<OrderItemEntity> items;
  final String vendorName;
  final String deliverySlot;
  final double subTotal;
  final double total;
  final String proformaInvoiceUrl;
  final bool vehicleAssigned;
  final int rewardPoints;
  final String rewardMessage;
  final List<OrderShipmentFileEntity> files;
  // "review" is only ever present once the customer has actually submitted
  // one — its mere presence (not its contents) is what should hide the
  // "Rate now" prompt on the tracking page.
  final bool hasReview;

  factory OrderShipmentEntity.fromMap(Map<String, dynamic> map) {
    final productsRaw =
        map['products'] is List ? map['products'] as List : <dynamic>[];

    return OrderShipmentEntity(
      id: (map['suborder_id'] ?? map['id'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      deliveryDate: (map['delivery_date'] ?? '').toString(),
      vendorName: (map['vendor_name'] ?? '').toString(),
      deliverySlot: (map['delivery_slot'] ?? '').toString(),
      subTotal: double.tryParse(
              (map['sub_total'] ?? map['subTotal'] ?? '0').toString()) ??
          0,
      total: double.tryParse((map['total'] ?? '0').toString()) ?? 0,
      vehicleAssigned: map['vehicle_assigned'] == true,
      proformaInvoiceUrl: () {
        final proforma = map['proforma_invoices'] is List
            ? map['proforma_invoices'] as List
            : <dynamic>[];
        final invoices = proforma.isNotEmpty
            ? proforma
            : (map['invoices'] is List ? map['invoices'] as List : <dynamic>[]);
        final first = invoices.whereType<Map>().firstOrNull;
        if (first == null) return '';
        return (first['short_url'] ?? first['file'] ?? '').toString();
      }(),
      rewardPoints: () {
        final ps = map['sub_order_points_summary'] is Map
            ? Map<String, dynamic>.from(map['sub_order_points_summary'] as Map)
            : <String, dynamic>{};
        return int.tryParse((ps['total_points'] ?? '0').toString()) ?? 0;
      }(),
      rewardMessage: () {
        final ps = map['sub_order_points_summary'] is Map
            ? Map<String, dynamic>.from(map['sub_order_points_summary'] as Map)
            : <String, dynamic>{};
        return (ps['message'] ?? '').toString();
      }(),
      items: productsRaw
          .whereType<Map>()
          .map((e) => OrderItemEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      files: (map['suborder_files'] is List
              ? map['suborder_files'] as List
              : <dynamic>[])
          .whereType<Map>()
          .map((e) =>
              OrderShipmentFileEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      hasReview: map['review'] != null,
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
    this.subTotal = 0,
    this.sgst = 0,
    this.cgst = 0,
    this.shippingFee = 0,
    this.deliveryName = '',
    this.deliveryPhone = '',
    this.billingName = '',
    this.billingPhone = '',
    this.billingAddressFormatted = '',
    this.gstNumber = '',
    this.paymentMethods = const [],
    this.rewardPoints = 0,
    this.isStoreOrder = false,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String createdAt;
  final double total;
  final List<OrderItemEntity> items;
  final String shippingAddress;
  final bool isQuickCommerceOrder;
  final String projectName;
  final String rewardMessage;
  final List<OrderShipmentEntity> shipments;
  final double subTotal;
  final double sgst;
  final double cgst;
  final double shippingFee;
  final String deliveryName;
  final String deliveryPhone;
  final String billingName;
  final String billingPhone;
  final String billingAddressFormatted;
  final String gstNumber;
  final List<String> paymentMethods;
  final int rewardPoints;
  final bool isStoreOrder;

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
    final isQuickCommerceOrder = map['is_quick_commerce_order'] == true ||
        map['is_quick_commerce_order'] == 1 ||
        map['isQuickCommerceOrder'] == true ||
        map['quick_commerce'] == true;
    final billingAddr = map['billing_address'] is Map
        ? Map<String, dynamic>.from(map['billing_address'] as Map)
        : <String, dynamic>{};
    final billingAddrParts = [
      billingAddr['address_line_1']?.toString() ?? '',
      billingAddr['address_line_2']?.toString() ?? '',
      billingAddr['city']?.toString() ?? '',
      billingAddr['state']?.toString() ?? '',
      billingAddr['pincode']?.toString() ?? '',
    ].where((e) => e.isNotEmpty).toList();
    final paymentsRaw =
        map['payments'] is List ? map['payments'] as List : <dynamic>[];
    final resolvedGst = () {
      final billingGst = (billingAddr['gst_number'] ?? '').toString().trim();
      if (billingGst.isNotEmpty) return billingGst;
      final orderGst = (map['gst_number'] ?? '').toString().trim();
      if (orderGst.isNotEmpty) return orderGst;
      final userDetails = map['user_details'] is Map
          ? Map<String, dynamic>.from(map['user_details'] as Map)
          : <String, dynamic>{};
      return (userDetails['gst_number'] ?? '').toString().trim();
    }();

    final directItems = itemsRaw
        .whereType<Map>()
        .map((e) => OrderItemEntity.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final shipments = subordersRaw
        .whereType<Map>()
        .map((e) => OrderShipmentEntity.fromMap(Map<String, dynamic>.from(e)))
        .toList();

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
      items: directItems.isNotEmpty
          ? directItems
          : shipments.expand((s) => s.items).toList(),
      shippingAddress: addrParts.join(', '),
      projectName: (map['project_name'] ??
              project['name'] ??
              project['project_name'] ??
              addressProject['name'] ??
              addressProject['project_name'] ??
              '')
          .toString(),
      rewardMessage: (pointsSummary['message'] ??
              pointsSummary['reward_message'] ??
              map['reward_message'] ??
              '')
          .toString(),
      isQuickCommerceOrder: isQuickCommerceOrder,
      shipments: shipments,
      subTotal: double.tryParse(
              (map['sub_total'] ?? map['subtotal'] ?? map['total'] ?? '0')
                  .toString()) ??
          0,
      sgst: double.tryParse((map['sgst'] ?? '0').toString()) ?? 0,
      cgst: double.tryParse((map['cgst'] ?? '0').toString()) ?? 0,
      shippingFee:
          double.tryParse((map['shipping_fee'] ?? '0').toString()) ?? 0,
      deliveryName: (addr['name'] ?? '').toString(),
      deliveryPhone: (addr['phone_number'] ?? addr['phone'] ?? '').toString(),
      billingName: (billingAddr['name'] ?? '').toString(),
      billingPhone: (billingAddr['phone_number'] ?? billingAddr['phone'] ?? '')
          .toString(),
      billingAddressFormatted: billingAddrParts.join(', '),
      gstNumber: resolvedGst,
      paymentMethods: paymentsRaw
          .whereType<Map>()
          .map((p) => (p['payment_gateway'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList(),
      rewardPoints:
          int.tryParse((pointsSummary['total_points'] ?? '0').toString()) ?? 0,
      isStoreOrder: map['is_store_order'] == true,
    );
  }
}
