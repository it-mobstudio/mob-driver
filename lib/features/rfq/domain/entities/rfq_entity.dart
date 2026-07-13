import 'package:m_o_b_demand_side/shared/image_url.dart';

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
      imageUrl: sanitizeImageUrl(
          (map['image'] ?? map['product_image'] ?? '').toString()),
    );
  }
}

/// One entry in a `quote_requesteditems[vendorName]` list — a line item the
/// customer requested a quote for, grouped by the mob partner (vendor) who
/// will fulfill it.
class RfqRequestedItemEntity {
  const RfqRequestedItemEntity({
    required this.productName,
    required this.mobSku,
    required this.qty,
  });

  final String productName;
  final String mobSku;
  final int qty;

  factory RfqRequestedItemEntity.fromMap(Map<String, dynamic> map) {
    return RfqRequestedItemEntity(
      productName: (map['product_name'] ?? '').toString(),
      mobSku: (map['mob_sku'] ?? '').toString(),
      qty: int.tryParse((map['qty'] ?? '0').toString()) ?? 0,
    );
  }
}

/// One entry in the `quotes` array of `get_rfq_details` — mirrors the shape
/// consumed by the web's RfqQuotes.jsx (`data.index`, `data.date`,
/// `data.items`, `data.total`, `data.quote_status`,
/// `data.customer_quotation_pdf.file`, `data.checkout_url`,
/// `data.rfq_order.order_id`).
class RfqQuoteEntity {
  const RfqQuoteEntity({
    required this.quoteId,
    required this.index,
    required this.date,
    required this.itemsCount,
    required this.total,
    required this.quoteStatus,
    required this.quotationPdfUrl,
    required this.checkoutUrl,
    required this.orderId,
  });

  final String quoteId;
  final int index;
  final String date;
  final int itemsCount;
  final double total;
  final String quoteStatus;
  final String quotationPdfUrl;
  final String checkoutUrl;
  final String orderId;

  bool get isAccepted => quoteStatus == 'Accepted';
  bool get isConvertedToOrder => quoteStatus == 'Order Converted';
  bool get isMagicQuote => quoteStatus == 'Magic Quote';
  bool get isNew => !isAccepted && !isConvertedToOrder;

  RfqQuoteEntity copyWith({String? quoteStatus, String? orderId}) {
    return RfqQuoteEntity(
      quoteId: quoteId,
      index: index,
      date: date,
      itemsCount: itemsCount,
      total: total,
      quoteStatus: quoteStatus ?? this.quoteStatus,
      quotationPdfUrl: quotationPdfUrl,
      checkoutUrl: checkoutUrl,
      orderId: orderId ?? this.orderId,
    );
  }

  factory RfqQuoteEntity.fromMap(Map<String, dynamic> map) {
    final pdf = map['customer_quotation_pdf'] is Map
        ? Map<String, dynamic>.from(map['customer_quotation_pdf'] as Map)
        : <String, dynamic>{};
    final order = map['rfq_order'] is Map
        ? Map<String, dynamic>.from(map['rfq_order'] as Map)
        : <String, dynamic>{};
    return RfqQuoteEntity(
      quoteId: (map['quote_id'] ?? map['id'] ?? '').toString(),
      index: int.tryParse((map['index'] ?? '0').toString()) ?? 0,
      date: (map['date'] ?? map['created_at'] ?? '').toString(),
      itemsCount: int.tryParse((map['items'] ?? '0').toString()) ?? 0,
      total: double.tryParse((map['total'] ?? '0').toString()) ?? 0,
      quoteStatus: (map['quote_status'] ?? '').toString(),
      quotationPdfUrl: (pdf['file'] ?? '').toString(),
      checkoutUrl: (map['checkout_url'] ?? '').toString(),
      orderId: (order['order_id'] ?? '').toString(),
    );
  }
}

String _humanizeText(String text) {
  final replaced = text.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (replaced.isEmpty) return replaced;
  return replaced[0].toUpperCase() + replaced.substring(1);
}

String _formatPreferredBrands(dynamic raw) {
  if (raw is List) {
    return raw
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
  }
  var text = (raw ?? '').toString();
  text = text.replaceFirst(RegExp(r'^\s*\[\s*'), '');
  text = text.replaceFirst(RegExp(r'\s*\]\s*$'), '');
  text = text.replaceAll(RegExp("['\"]"), '');
  return text.trim();
}

class RfqEntity {
  const RfqEntity({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.totalAmount,
    this.city = '',
    this.pincode = '',
    this.projectName = '',
    this.rfqRemarks = '',
    this.preferredBrands = '',
    this.comments = '',
    this.deliveryInstructions = const [],
    this.files = const [],
    this.quotes = const [],
    this.orderId = '',
    this.quoteRequestedItems = const {},
  });

  final String id;
  final String status;
  final String createdAt;
  final List<RfqItemEntity> items;
  final double totalAmount;
  final String city;
  final String pincode;
  final String projectName;

  /// "Item list" free-text the customer typed when submitting the RFQ.
  final String rfqRemarks;
  final String preferredBrands;

  /// Answer to the `specific_preferences_note` questionnaire question.
  final String comments;

  /// Every other questionnaire answer, humanized for display.
  final List<({String key, String value})> deliveryInstructions;

  /// Uploaded reference file URLs.
  final List<String> files;
  final List<RfqQuoteEntity> quotes;

  /// Platform order id once this RFQ has been converted to an order.
  final String orderId;

  /// Requested items grouped by vendor (mob partner) name.
  final Map<String, List<RfqRequestedItemEntity>> quoteRequestedItems;

  List<RfqQuoteEntity> get newQuotes =>
      quotes.where((q) => q.isNew && !q.isMagicQuote).toList();
  List<RfqQuoteEntity> get acceptedQuotes =>
      quotes.where((q) => q.isAccepted).toList();
  List<RfqQuoteEntity> get convertedToOrderQuotes =>
      quotes.where((q) => q.isConvertedToOrder).toList();
  List<RfqQuoteEntity> get magicQuotes =>
      quotes.where((q) => q.isMagicQuote).toList();

  int get requestedItemsTotalCount => quoteRequestedItems.values
      .expand((items) => items)
      .fold(0, (sum, item) => sum + item.qty);

  RfqEntity copyWith({
    String? id,
    String? status,
    String? createdAt,
    List<RfqItemEntity>? items,
    double? totalAmount,
    String? city,
    String? pincode,
    String? projectName,
    List<RfqQuoteEntity>? quotes,
    String? orderId,
  }) {
    return RfqEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      projectName: projectName ?? this.projectName,
      rfqRemarks: rfqRemarks,
      preferredBrands: preferredBrands,
      comments: comments,
      deliveryInstructions: deliveryInstructions,
      files: files,
      quotes: quotes ?? this.quotes,
      orderId: orderId ?? this.orderId,
      quoteRequestedItems: quoteRequestedItems,
    );
  }

  factory RfqEntity.fromMap(Map<String, dynamic> map) {
    final itemsRaw = switch (map['items'] ??
        map['products'] ??
        map['rfq_items'] ??
        map['quote_items']) {
      final List value => value,
      _ => <dynamic>[],
    };
    final order = map['order'] is Map
        ? Map<String, dynamic>.from(map['order'] as Map)
        : <String, dynamic>{};
    final project = order['project'] is Map
        ? Map<String, dynamic>.from(order['project'] as Map)
        : <String, dynamic>{};
    final rawCity = (map['city'] ?? '').toString().trim();
    final city = rawCity.isEmpty || rawCity == 'N/A' || rawCity == 'undefined'
        ? ''
        : rawCity;

    final filesRaw = map['files'] is List ? map['files'] as List : <dynamic>[];
    final files = filesRaw
        .map((file) => file is Map
            ? (file['thumbnail'] ?? '').toString()
            : file.toString())
        .where((url) => url.trim().isNotEmpty)
        .toList();

    final questionnaireAnswers = map['questionnaire_answers'] is Map
        ? Map<String, dynamic>.from(map['questionnaire_answers'] as Map)
        : <String, dynamic>{};
    const noteQuestionId = 'specific_preferences_note';
    final comments = (questionnaireAnswers[noteQuestionId] ?? '').toString();
    final deliveryInstructions = questionnaireAnswers.entries
        .where((e) => e.key != noteQuestionId)
        .map((e) => (
              key: _humanizeText(e.key),
              value: _humanizeText(e.value.toString()),
            ))
        .toList();

    final rfqOrderId = (order['order_id'] ?? '').toString();
    final quotesRaw =
        map['quotes'] is List ? map['quotes'] as List : <dynamic>[];
    // Individual quote objects in the API's `quotes` array never carry their
    // own `rfq_order` — the web app stitches the single RFQ-level `order`
    // onto each quote before rendering (see mob-web's
    // `[rfq-details].jsx` building `rfq_order: rfqDetails?.data?.order` and
    // re-attaching it per quote). Mirror that here instead of reading a key
    // that's never present on the raw quote map.
    final quotes = quotesRaw
        .whereType<Map>()
        .map((e) => RfqQuoteEntity.fromMap(Map<String, dynamic>.from(e)))
        .map((quote) => quote.isConvertedToOrder && quote.orderId.isEmpty
            ? quote.copyWith(orderId: rfqOrderId)
            : quote)
        .toList();

    final quoteRequestedItemsRaw = map['quote_requesteditems'] is Map
        ? Map<String, dynamic>.from(map['quote_requesteditems'] as Map)
        : <String, dynamic>{};
    final quoteRequestedItems = quoteRequestedItemsRaw.map(
      (vendor, itemsList) => MapEntry(
        vendor,
        (itemsList is List ? itemsList : <dynamic>[])
            .whereType<Map>()
            .map((e) =>
                RfqRequestedItemEntity.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      ),
    );

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
      city: city,
      pincode: (map['pincode'] ?? '').toString(),
      projectName: (project['project_name'] ?? '').toString(),
      rfqRemarks: (map['rfq_remarks'] ?? '').toString(),
      preferredBrands: _formatPreferredBrands(map['preferred_brands']),
      comments: comments,
      deliveryInstructions: deliveryInstructions,
      files: files,
      quotes: quotes,
      orderId: rfqOrderId,
      quoteRequestedItems: quoteRequestedItems,
    );
  }
}
