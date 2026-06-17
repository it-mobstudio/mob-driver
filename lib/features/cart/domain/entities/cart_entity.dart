import 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';
export 'package:m_o_b_demand_side/features/cart/data/models/cart_item.dart';

class CartAddressEntity {
  const CartAddressEntity({
    required this.name,
    required this.address,
    this.addressId = '',
    this.phone = '',
    this.pincode = '',
    this.tag = '',
    this.project = '',
    this.gstNumber = '',
  });

  final String addressId;
  final String name;
  final String address;
  final String pincode;
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
    required this.mobstarAmount,
    required this.earningPoints,
    required this.walletBalance,
    required this.applicableWalletAmount,
    required this.useWallet,
    required this.usePoints,
    required this.rfqItemCount,
    required this.itemCount,
    required this.cartId,
    required this.shippingTitle,
    required this.shippingSubtitle,
    required this.shippingRecipientName,
    required this.shippingAddress,
    required this.shippingPhone,
    required this.shippingAddressId,
    required this.shippingPincode,
    required this.gstNumber,
    required this.billingAddress,
    required this.billingAddressId,
    required this.billingGstNumber,
    required this.savedAddresses,
    required this.mobCreditBalance,
    this.walletNote = '',
    this.mobCreditAccountStatus,
  });

  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double tax;
  final double savings;
  final double total;
  /// Redeemable mobstar points the user currently holds.
  final int rewardPoints;

  /// Rupee value of redeemable mobstar points (from API actual_money).
  final double mobstarAmount;

  /// Points the user will earn on this purchase (from API earning_points).
  final int earningPoints;

  /// Mobwallet balance available for redemption.
  final double walletBalance;

  /// Amount from wallet that will actually be applied to this order.
  final double applicableWalletAmount;

  /// Whether the cart currently has wallet redemption active (from API use_wallet).
  final bool useWallet;

  /// Whether the cart currently has mobstar points redemption active (from API use_points).
  final bool usePoints;

  final int rfqItemCount;

  /// Raw `item_count` from the API — use this for the cart badge.
  final int itemCount;

  /// Cart ID from API — used for address-to-order linking.
  final String cartId;

  final String shippingTitle;
  final String shippingSubtitle;
  final String shippingRecipientName;
  final String shippingAddress;
  final String shippingPhone;

  /// Address ID of the currently set delivery address.
  final String shippingAddressId;
  final String shippingPincode;

  final String gstNumber;
  final String billingAddress;

  /// Address ID of the currently set billing address.
  final String billingAddressId;

  final String billingGstNumber;
  final List<CartAddressEntity> savedAddresses;

  /// mobCREDIT balance available for the user (from user_details in cart API).
  final double mobCreditBalance;

  /// Info note from wallet object (e.g. "Only 20% of cart value can be used from referral money").
  final String walletNote;

  /// Rupifi account_status from rupifiDetails (e.g. "ACTIVE", "AMOUNT_DUE", "INACTIVE").
  /// null means the user has no mobCredit account — hide the option entirely.
  final String? mobCreditAccountStatus;

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
    mobstarAmount: 0,
    earningPoints: 0,
    walletBalance: 0,
    applicableWalletAmount: 0,
    useWallet: false,
    usePoints: false,
    rfqItemCount: 0,
    itemCount: 0,
    cartId: '',
    shippingTitle: 'Shipping address',
    shippingSubtitle: 'Add an address to continue',
    shippingRecipientName: '',
    shippingAddress: '',
    shippingPhone: '',
    shippingAddressId: '',
    shippingPincode: '',
    gstNumber: '',
    billingAddress: '',
    billingAddressId: '',
    billingGstNumber: '',
    savedAddresses: <CartAddressEntity>[],
    mobCreditBalance: 0,
  );
}
