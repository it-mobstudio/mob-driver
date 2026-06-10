import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
export 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';

class CartAddressEntity {
  const CartAddressEntity({
    required this.name,
    required this.address,
    this.phone = '',
    this.tag = '',
    this.project = '',
    this.gstNumber = '',
  });

  final String name;
  final String address;
  final String phone;
  final String tag;
  final String project;
  final String gstNumber;

  bool get hasAddress => address.trim().isNotEmpty;
}

class CartSummaryEntity {
  const CartSummaryEntity({
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.savings,
    required this.total,
    required this.rewardPoints,
    required this.rfqItemCount,
    required this.itemCount,
    required this.shippingTitle,
    required this.shippingSubtitle,
    required this.shippingRecipientName,
    required this.shippingAddress,
    required this.shippingPhone,
    required this.gstNumber,
    required this.billingAddress,
    required this.billingGstNumber,
    required this.savedAddresses,
  });

  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double tax;
  final double savings;
  final double total;
  final int rewardPoints;
  final int rfqItemCount;

  /// Raw `item_count` from the API — use this for the cart badge.
  final int itemCount;

  final String shippingTitle;
  final String shippingSubtitle;
  final String shippingRecipientName;
  final String shippingAddress;
  final String shippingPhone;
  final String gstNumber;
  final String billingAddress;
  final String billingGstNumber;
  final List<CartAddressEntity> savedAddresses;

  bool get isEmpty => itemCount == 0 && items.isEmpty;
  bool get hasRfqItems => rfqItemCount > 0;
  bool get hasDeliveryAddress => shippingAddress.trim().isNotEmpty;

  Map<String, List<CartItem>> get itemsBySeller {
    final bySeller = <String, List<CartItem>>{};
    for (final item in items) {
      bySeller.putIfAbsent(item.sellerCode, () => <CartItem>[]).add(item);
    }
    return bySeller;
  }

  static const empty = CartSummaryEntity(
    items: <CartItem>[],
    subtotal: 0,
    shipping: 0,
    tax: 0,
    savings: 0,
    total: 0,
    rewardPoints: 0,
    rfqItemCount: 0,
    itemCount: 0,
    shippingTitle: 'Shipping address',
    shippingSubtitle: 'Add an address to continue',
    shippingRecipientName: '',
    shippingAddress: '',
    shippingPhone: '',
    gstNumber: '',
    billingAddress: '',
    billingGstNumber: '',
    savedAddresses: <CartAddressEntity>[],
  );
}
