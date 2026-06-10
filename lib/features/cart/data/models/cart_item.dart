class CartItem {
  const CartItem({
    required this.title,
    required this.imageAsset,
    required this.qty,
    required this.unitPrice,
    required this.sellerCode,
    this.storeDelivery = true,
    this.vendorProductId = '',
    this.cartItemId = '',
  });

  final String title;
  final String imageAsset;
  final int qty;
  final double unitPrice;
  final String sellerCode;
  final bool storeDelivery;
  final String vendorProductId;
  final String cartItemId;
  bool get isNetworkImage =>
      imageAsset.startsWith('http://') || imageAsset.startsWith('https://');
  String get itemKey => cartItemId.isNotEmpty ? cartItemId : vendorProductId;

  double get lineTotal => unitPrice * qty;

  CartItem copyWith({
    String? title,
    String? imageAsset,
    int? qty,
    double? unitPrice,
    String? sellerCode,
    bool? storeDelivery,
    String? vendorProductId,
    String? cartItemId,
  }) {
    return CartItem(
      title: title ?? this.title,
      imageAsset: imageAsset ?? this.imageAsset,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      sellerCode: sellerCode ?? this.sellerCode,
      storeDelivery: storeDelivery ?? this.storeDelivery,
      vendorProductId: vendorProductId ?? this.vendorProductId,
      cartItemId: cartItemId ?? this.cartItemId,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final nestedProduct = map['product'] is Map
        ? Map<String, dynamic>.from(map['product'] as Map)
        : <String, dynamic>{};
    final title = _readFirstString(
      map,
      const [
        'item_name_title',
        'title',
        'name',
        'product_name',
        'item_name',
      ],
    );
    final image = _readFirstString(
      map,
      const [
        'image',
        'image_url',
        'product_image',
        'thumbnail',
      ],
    );
    final quantity = _readFirstInt(
      map,
      const ['quantity', 'qty', 'count', 'cart_quantity'],
      fallback: 1,
    );
    final unitPrice = _readFirstNum(
      map,
      const [
        'vendor_selling_price',
        'selling_price',
        'unit_price',
        'price',
        'amount',
      ],
      fallback: 0,
    ).toDouble();
    final sellerCode = _readFirstString(
      map,
      const ['seller_code', 'sellerCode', 'vendor_code', 'vendorCode'],
      fallback: 'STORE',
    );
    final vendorProductId = _readFirstString(
      {
        ...nestedProduct,
        ...map,
      },
      const ['vendor_product_id', 'vendorProductId', 'product_id', 'productId'],
    );
    final cartItemId = _readFirstString(
      {
        ...nestedProduct,
        ...map,
      },
      const ['cart_item_id', 'cartItemId', 'id'],
    );

    return CartItem(
      title: title.isNotEmpty ? title : 'Cart item',
      imageAsset: image.isNotEmpty ? image : 'assets/images/Image-coming-soon.png',
      qty: quantity <= 0 ? 1 : quantity,
      unitPrice: unitPrice,
      sellerCode: sellerCode.isNotEmpty ? sellerCode : 'STORE',
      vendorProductId: vendorProductId,
      cartItemId: cartItemId,
    );
  }

  static String _readFirstString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  static int _readFirstInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) {
        return value;
      }
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }

  static num _readFirstNum(
    Map<String, dynamic> map,
    List<String> keys, {
    num fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value;
      }
      final parsed = num.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }
}
