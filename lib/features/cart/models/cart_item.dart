class CartItem {
  const CartItem({
    required this.title,
    required this.imageAsset,
    required this.qty,
    required this.unitPrice,
    required this.sellerCode,
    this.storeDelivery = true,
  });

  final String title;
  final String imageAsset;
  final int qty;
  final double unitPrice;
  final String sellerCode;
  final bool storeDelivery;

  double get lineTotal => unitPrice * qty;

  CartItem copyWith({
    String? title,
    String? imageAsset,
    int? qty,
    double? unitPrice,
    String? sellerCode,
    bool? storeDelivery,
  }) {
    return CartItem(
      title: title ?? this.title,
      imageAsset: imageAsset ?? this.imageAsset,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      sellerCode: sellerCode ?? this.sellerCode,
      storeDelivery: storeDelivery ?? this.storeDelivery,
    );
  }
}
