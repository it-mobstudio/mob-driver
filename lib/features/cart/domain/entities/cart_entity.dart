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
    this.isMobCredit = false,
  });

  final String addressId;
  final String name;
  final String address;
  final String pincode;
  final String phone;
  final String tag;
  final String project;
  final String gstNumber;

  /// Mirrors AddressEntity.mobCredit — the address designated as this
  /// user's mobCREDIT/billing address, used to auto-pick a billing address.
  final bool isMobCredit;

  bool get hasAddress => address.trim().isNotEmpty;
}

class CartAccountEntity {
  const CartAccountEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.profileImage,
    required this.wallet,
    required this.mobStarPoints,
    required this.mobStarAmount,
    required this.mobStarLevel,
    required this.mobStarPercentage,
    required this.freeDelivery,
    required this.gstNumber,
    required this.rupifiPrimaryStatus,
    required this.rupifiAccountStatus,
    required this.rupifiCurrentLimit,
    required this.rupifiBalance,
    required this.isBlocked,
    required this.isProfessional,
    required this.businessSegmentName,
  });

  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String profileImage;
  final double wallet;
  final int mobStarPoints;
  final double mobStarAmount;
  final String mobStarLevel;
  final double mobStarPercentage;
  final int freeDelivery;
  final String gstNumber;
  final String rupifiPrimaryStatus;
  final String rupifiAccountStatus;
  final double rupifiCurrentLimit;
  final double rupifiBalance;
  final bool isBlocked;
  final bool isProfessional;
  final String businessSegmentName;

  bool get hasData =>
      fullName.isNotEmpty ||
      phoneNumber.isNotEmpty ||
      email.isNotEmpty ||
      profileImage.isNotEmpty;

  String get membership {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(mobStarLevel);
    return match?.group(1) ?? (mobStarLevel.isEmpty ? 'Bronze' : mobStarLevel);
  }

  factory CartAccountEntity.fromMap(Map<String, dynamic> map) {
    final mobStar = map['mobStarPoints'] is Map
        ? Map<String, dynamic>.from(map['mobStarPoints'] as Map)
        : <String, dynamic>{};
    final rupifi = map['rupifiDetails'] is Map
        ? Map<String, dynamic>.from(map['rupifiDetails'] as Map)
        : <String, dynamic>{};
    final walletSource = map['wallet'];
    final wallet = walletSource is Map
        ? Map<String, dynamic>.from(walletSource)
        : <String, dynamic>{};
    final businessSource = map['business_segment'] ?? map['businessSegment'];
    final businessSegment = businessSource is Map
        ? Map<String, dynamic>.from(businessSource)
        : <String, dynamic>{};
    final walletAmount = wallet.isNotEmpty
        ? _entityNum(wallet, const ['wallet_balance', 'balance', 'amount'])
        : _entityNum(
            map,
            const ['wallet', 'wallet_balance', 'mob_wallet_balance'],
          );

    return CartAccountEntity(
      id: _entityStr(map, const ['id']),
      email: _entityStr(map, const ['email']),
      fullName: _entityStr(map, const ['full_name', 'name', 'username']),
      phoneNumber: _entityStr(
        map,
        const ['phone_number', 'phone', 'mobile', 'email_or_phone'],
      ),
      profileImage:
          _entityStr(map, const ['profile_image', 'profile_picture', 'image']),
      wallet: walletAmount.toDouble(),
      mobStarPoints: _entityInt(mobStar, const ['points']),
      mobStarAmount: _entityNum(mobStar, const ['actual_money']).toDouble(),
      mobStarLevel: _entityStr(mobStar, const ['name']),
      mobStarPercentage: _entityNum(mobStar, const ['percentage']).toDouble(),
      freeDelivery: _entityInt(mobStar, const ['free_delivery']),
      gstNumber: _entityStr(map, const ['gst_number', 'gstin', 'gst_no']),
      rupifiPrimaryStatus: _entityStr(rupifi, const ['primary_status']),
      rupifiAccountStatus: _entityStr(rupifi, const ['account_status']),
      rupifiCurrentLimit:
          _entityNum(rupifi, const ['current_limit']).toDouble(),
      rupifiBalance: _entityNum(rupifi, const ['balance']).toDouble(),
      isBlocked: map['is_blocked'] == true,
      isProfessional: map['is_professional'] == true,
      businessSegmentName:
          _entityStr(businessSegment, const ['category_name', 'category']),
    );
  }

  static const empty = CartAccountEntity(
    id: '',
    email: '',
    fullName: '',
    phoneNumber: '',
    profileImage: '',
    wallet: 0,
    mobStarPoints: 0,
    mobStarAmount: 0,
    mobStarLevel: 'Level 01 (Bronze)',
    mobStarPercentage: 0,
    freeDelivery: 0,
    gstNumber: '',
    rupifiPrimaryStatus: '',
    rupifiAccountStatus: '',
    rupifiCurrentLimit: 0,
    rupifiBalance: 0,
    isBlocked: false,
    isProfessional: false,
    businessSegmentName: '',
  );
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
    required this.account,
    this.outOfStockItems = const <CartItem>[],
    this.checkoutDisabled = false,
    this.isReferralOnlyWallet = false,
    this.isWalletUsageLimited = false,
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
  final CartAccountEntity account;
  final List<CartItem> outOfStockItems;
  final bool checkoutDisabled;

  /// Wallet restriction flags from API. The referral-limit note should only
  /// show when both are true, matching web checkout.
  final bool isReferralOnlyWallet;
  final bool isWalletUsageLimited;

  /// Info note from wallet object (e.g. "Only 20% of cart value can be used from referral money").
  final String walletNote;

  /// Rupifi account_status from rupifiDetails (e.g. "ACTIVE", "AMOUNT_DUE", "INACTIVE").
  /// null means the user has no mobCredit account — hide the option entirely.
  final String? mobCreditAccountStatus;

  bool get isEmpty => itemCount == 0 && items.isEmpty;
  bool get hasRfqItems => rfqItemCount > 0;
  bool get hasDeliveryAddress => shippingAddress.trim().isNotEmpty;
  bool get hasOutOfStockItems => outOfStockItems.isNotEmpty;

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
    account: CartAccountEntity.empty,
    outOfStockItems: <CartItem>[],
    checkoutDisabled: false,
    isReferralOnlyWallet: false,
    isWalletUsageLimited: false,
  );
}

String _entityStr(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

int _entityInt(Map<String, dynamic> map, List<String> keys,
    {int fallback = 0}) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

num _entityNum(Map<String, dynamic> map, List<String> keys,
    {num fallback = 0}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}
