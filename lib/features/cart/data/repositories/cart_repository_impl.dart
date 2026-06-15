import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._datasource);

  final CartRemoteDatasource _datasource;

  @override
  Future<(CartSummaryEntity?, AppFailure?)> getCart({bool outOfStock = false}) async {
    try {
      final data = await _datasource.getCart(outOfStock: outOfStock);
      return (_buildSummary(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(CartSummaryEntity?, AppFailure?)> addToCart({
    required String vendorProductId,
    required int quantity,
  }) async {
    try {
      final data = await _datasource.addToCart(
        vendorProductId: vendorProductId,
        quantity: quantity,
      );
      return (_buildSummary(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(CartSummaryEntity?, AppFailure?)> removeFromCart({
    required String cartItemId,
    String? vendorProductId,
  }) async {
    try {
      final data = await _datasource.removeFromCart(
        cartItemId: cartItemId,
        vendorProductId: vendorProductId,
      );
      return (_buildSummary(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(CartSummaryEntity?, AppFailure?)> updateCartRedeem({
    required String cartId,
    required bool useWallet,
    required double walletAmount,
    required bool usePoints,
    required int points,
  }) async {
    try {
      final data = await _datasource.updateCartRedeem({
        'cart_id': int.tryParse(cartId) ?? 0,
        'use_wallet': useWallet,
        'wallet_amount': walletAmount,
        'use_points': usePoints,
        'points': points,
      });
      return (_buildSummary(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  // ── Entity builder ───────────────────────────────────────────────────────

  CartSummaryEntity _buildSummary(Map<String, dynamic> data) {
    final items = _extractItemMaps(data).map(CartItem.fromMap).toList();
    final subtotal = _num(
      data,
      const ['sub_cart_total', 'subTotal', 'subtotal'],
      fallback: items.fold<double>(0, (s, i) => s + i.lineTotal),
    );
    final ship = _num(data, const ['shipping', 'shipping_charge', 'shippingCharges']);
    final sav = _num(data, const ['savings', 'discount']);

    final shippingInfo = _parseShipping(data['user_details']);
    final billingAddr = _parseBillingAddress(data, shippingInfo.address, shippingInfo.gst);
    final billingGst = _parseBillingGst(data, shippingInfo.gst);
    final billingId = _parseBillingAddressId(data, shippingInfo.id);
    final savedAddresses = _parseSavedAddresses(data, shippingInfo);

    final rfqCount = _rfqCount(data['quote_cart']);

    final ud = data['user_details'];
    final udMap = ud is Map ? Map<String, dynamic>.from(ud) : <String, dynamic>{};

    // Mob star tier nested inside user_details (e.g. mob_star, loyalty, tier)
    final mobStarTier = _findNestedMap(udMap, const [
      'mob_star', 'mob_star_tier', 'loyalty', 'loyalty_tier', 'tier', 'reward_tier',
    ]);

    // Wallet nested object (e.g. mob_wallet, wallet, wallet_info)
    final walletObj = _findNestedMap(data, const [
      'mob_wallet', 'wallet', 'wallet_info', 'wallet_details',
    ]);

    final walletBalance = _num(walletObj, const ['wallet_balance']).toDouble() != 0
        ? _num(walletObj, const ['wallet_balance']).toDouble()
        : _num(data, const ['wallet_balance', 'mob_wallet_balance']).toDouble();

    return CartSummaryEntity(
      items: items,
      subtotal: subtotal.toDouble(),
      shipping: ship.toDouble(),
      tax: _num(data, const ['tax', 'total_tax', 'tax_total']).toDouble(),
      savings: sav.toDouble(),
      total: _num(data, const ['total', 'cart_total'],
              fallback: subtotal + ship - sav)
          .toDouble(),
      rewardPoints: _int(mobStarTier, const ['points']),
      mobstarAmount: _num(mobStarTier, const ['actual_money']).toDouble(),
      earningPoints: _int(data, const ['earning_points', 'earn_points', 'points_to_earn']),
      walletBalance: walletBalance,
      applicableWalletAmount: _num(walletObj, const ['applicable_wallet_amount']).toDouble() != 0
          ? _num(walletObj, const ['applicable_wallet_amount']).toDouble()
          : walletBalance,
      useWallet: data['use_wallet'] == true,
      usePoints: data['use_points'] == true,
      rfqItemCount: rfqCount,
      itemCount: _int(data, const ['item_count', 'itemCount', 'total_items'],
          fallback: items.length + rfqCount),
      cartId: _str(data, const ['id', 'cart_id', 'pk']),
      shippingTitle: shippingInfo.title,
      shippingSubtitle: shippingInfo.subtitle,
      shippingRecipientName: shippingInfo.name,
      shippingAddress: shippingInfo.address,
      shippingPhone: shippingInfo.phone,
      shippingAddressId: shippingInfo.id,
      shippingPincode: shippingInfo.pincode,
      gstNumber: shippingInfo.gst,
      billingAddress: billingAddr,
      billingAddressId: billingId,
      billingGstNumber: billingGst,
      savedAddresses: savedAddresses,
    );
  }

  // ── Item extraction ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractItemMaps(Map<String, dynamic> data) {
    final result = <Map<String, dynamic>>[];
    result.addAll(_fromSubcarts(_mapList(data['subcarts'])));

    final qc = data['quick_commerce'];
    if (qc is Map) {
      result.addAll(_fromSubcarts(_mapList(qc['subcarts'])));
      result.addAll(_mapList(qc['quick_products']));
    } else if (qc is List) {
      result.addAll(_fromSubcarts(_mapList(qc)));
    }

    if (result.isNotEmpty) return result;
    return _fallbackItems(data);
  }

  List<Map<String, dynamic>> _fromSubcarts(List<Map<String, dynamic>> subcarts) {
    final result = <Map<String, dynamic>>[];
    for (final subcart in subcarts) {
      final vendor = subcart['vendor'] is Map
          ? Map<String, dynamic>.from(subcart['vendor'] as Map)
          : <String, dynamic>{};
      final sellerCode =
          _str(vendor, const ['bmp_id', 'seller_code', 'vendor_code'], fallback: 'STORE');
      for (final item in _mapList(subcart['items'])) {
        final product = item['product'] is Map
            ? Map<String, dynamic>.from(item['product'] as Map)
            : <String, dynamic>{};
        result.add({
          ...product,
          ...item,
          'seller_code': item['seller_code'] ?? sellerCode,
          'quantity': item['quantity'] ?? item['qty'] ?? 1,
          'vendor_product_id': item['vendor_product_id'] ?? product['vendor_product_id'],
          'cart_item_id': item['cart_item_id'] ?? item['id'],
          'vendor_selling_price':
              item['vendor_selling_price'] ?? product['vendor_selling_price'],
          'item_name_title': item['item_name_title'] ?? product['item_name_title'],
          'image': item['image'] ?? product['image'] ?? product['product_image'],
        });
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _fallbackItems(Map<String, dynamic> data) {
    const keys = ['items', 'cart_items', 'cartItems', 'products', 'results'];
    for (final key in keys) {
      final v = data[key];
      if (v is List) {
        final maps = v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where(_looksLikeItem)
            .toList();
        if (maps.isNotEmpty) return maps;
      }
    }
    return const [];
  }

  bool _looksLikeItem(Map<String, dynamic> map) {
    const titleKeys = ['item_name_title', 'title', 'name', 'product_name'];
    const qtyKeys = ['quantity', 'qty'];
    const priceKeys = ['vendor_selling_price', 'selling_price', 'price'];
    final hasTitle = titleKeys.any((k) => (map[k]?.toString().trim() ?? '').isNotEmpty);
    final hasQty = qtyKeys.any((k) => num.tryParse(map[k]?.toString() ?? '') != null);
    final hasPrice = priceKeys.any((k) => num.tryParse(map[k]?.toString() ?? '') != null);
    return hasTitle || (hasQty && hasPrice);
  }

  // ── RFQ ─────────────────────────────────────────────────────────────────

  int _rfqCount(dynamic quoteCart) {
    if (quoteCart is Map) {
      final items = quoteCart['items'];
      if (items is List) return items.length;
      final subcarts = quoteCart['subcarts'];
      if (subcarts is List) {
        return subcarts
            .whereType<Map>()
            .fold<int>(0, (s, sc) => s + _listLen(sc['items']));
      }
    }
    if (quoteCart is List) {
      return quoteCart
          .whereType<Map>()
          .fold<int>(0, (s, sc) => s + _listLen(sc['items']));
    }
    return 0;
  }

  // ── Shipping / Billing / Addresses ───────────────────────────────────────

  _ShippingInfo _parseShipping(dynamic raw) {
    if (raw is! Map) {
      return const _ShippingInfo(
        title: 'Shipping address',
        subtitle: 'Add an address to continue',
        name: '',
        address: '',
        phone: '',
        gst: '',
        id: '',
        pincode: '',
      );
    }
    final ud = Map<String, dynamic>.from(raw);
    final project =
        ud['project'] is Map ? Map<String, dynamic>.from(ud['project'] as Map) : <String, dynamic>{};
    final projectName = _str(project, const ['project_name', 'name']);
    final name = _str(ud, const ['name', 'full_name', 'username']);
    final parts = [
      _str(ud, const ['address_line_1', 'address1', 'address']),
      _str(ud, const ['address_line_2', 'address2']),
      _str(ud, const ['city']),
      _str(ud, const ['state']),
      _str(ud, const ['pincode', 'zip']),
    ].where((e) => e.isNotEmpty).toList();
    final addr = parts.join(', ');
    return _ShippingInfo(
      title: projectName.isNotEmpty
          ? 'Shipping to: $projectName'
          : (name.isNotEmpty ? 'Shipping to: $name' : 'Shipping address'),
      subtitle: parts.isNotEmpty ? addr : 'Add an address to continue',
      name: name,
      address: addr,
      phone: _str(ud, const ['phone', 'phone_number', 'mobile', 'contact_number']),
      gst: _str(ud, const ['gst_number', 'gst_no', 'gstin', 'gst', 'tax_number']),
      id: _str(ud, const ['id', 'address_id', 'pk']),
      pincode: _str(ud, const ['pincode', 'zip', 'zip_code']),
    );
  }

  String _parseBillingAddressId(Map<String, dynamic> data, String fallback) {
    final raw = data['billing_details'] ?? data['billing_address'] ?? data['billing'];
    if (raw is! Map) return fallback;
    final billing = Map<String, dynamic>.from(raw);
    return _str(billing, const ['id', 'address_id', 'pk'], fallback: fallback);
  }

  String _parseBillingAddress(
    Map<String, dynamic> data,
    String fallbackAddress,
    String fallbackGst,
  ) {
    final raw = data['billing_details'] ?? data['billing_address'] ?? data['billing'];
    if (raw is! Map) return fallbackAddress;
    final billing = Map<String, dynamic>.from(raw);
    final parts = [
      _str(billing, const ['address_line_1', 'address1', 'address']),
      _str(billing, const ['address_line_2', 'address2']),
      _str(billing, const ['city']),
      _str(billing, const ['state']),
      _str(billing, const ['pincode', 'zip']),
    ].where((e) => e.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : fallbackAddress;
  }

  String _parseBillingGst(Map<String, dynamic> data, String fallback) {
    final raw = data['billing_details'] ?? data['billing_address'] ?? data['billing'];
    if (raw is! Map) return fallback;
    final billing = Map<String, dynamic>.from(raw);
    return _str(billing, const ['gst_number', 'gst_no', 'gstin', 'gst'], fallback: fallback);
  }

  List<CartAddressEntity> _parseSavedAddresses(
    Map<String, dynamic> data,
    _ShippingInfo shipping,
  ) {
    final candidates = <dynamic>[
      data['addresses'],
      data['saved_addresses'],
    ];
    final ud = data['user_details'];
    if (ud is Map) {
      candidates.addAll([ud['addresses'], ud['saved_addresses']]);
    }

    final addresses = <CartAddressEntity>[];
    for (final c in candidates) {
      if (c is! List) continue;
      for (final e in c.whereType<Map>()) {
        final m = Map<String, dynamic>.from(e);
        final parts = [
          _str(m, const ['address_line_1', 'address1', 'address']),
          _str(m, const ['address_line_2', 'address2']),
          _str(m, const ['city']),
          _str(m, const ['state']),
          _str(m, const ['pincode', 'zip']),
        ].where((v) => v.isNotEmpty).toList();
        if (parts.isEmpty) continue;
        addresses.add(CartAddressEntity(
          addressId: _str(m, const ['id', 'address_id', 'pk']),
          name: _str(m, const ['name', 'full_name', 'recipient_name'],
              fallback: shipping.name),
          address: parts.join(', '),
          pincode: _str(m, const ['pincode', 'zip_code', 'zip']),
          phone: _str(m, const ['phone', 'phone_number', 'mobile']),
          tag: _str(m, const ['tag', 'type', 'address_type', 'label'], fallback: 'Address'),
          project: _str(m, const ['project_name', 'project']),
          gstNumber: _str(m, const ['gst_number', 'gst_no', 'gstin']),
        ));
      }
    }

    if (addresses.isEmpty && shipping.address.isNotEmpty) {
      addresses.add(CartAddressEntity(
        addressId: shipping.id,
        name: shipping.name,
        address: shipping.address,
        pincode: shipping.pincode,
        phone: shipping.phone,
        tag: 'Delivery',
        gstNumber: shipping.gst,
      ));
    }

    final seen = <String>{};
    return addresses.where((a) {
      final key = '${a.name}|${a.address}|${a.phone}'.toLowerCase();
      return a.hasAddress && seen.add(key);
    }).toList();
  }

  // ── Primitive helpers ────────────────────────────────────────────────────

  Map<String, dynamic> _findNestedMap(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    return {};
  }

  List<Map<String, dynamic>> _mapList(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int _listLen(dynamic v) => v is List ? v.length : 0;

  String _str(Map<String, dynamic> map, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return fallback;
  }

  int _int(Map<String, dynamic> map, List<String> keys, {int fallback = 0}) {
    for (final k in keys) {
      final v = map[k];
      if (v is int) return v;
      final p = int.tryParse(v?.toString() ?? '');
      if (p != null) return p;
    }
    return fallback;
  }

  num _num(Map<String, dynamic> map, List<String> keys, {num fallback = 0}) {
    for (final k in keys) {
      final v = map[k];
      if (v is num) return v;
      final p = num.tryParse(v?.toString() ?? '');
      if (p != null) return p;
    }
    return fallback;
  }
}

// ── Internal shipping data struct ────────────────────────────────────────────

class _ShippingInfo {
  const _ShippingInfo({
    required this.title,
    required this.subtitle,
    required this.name,
    required this.address,
    required this.phone,
    required this.gst,
    required this.id,
    required this.pincode,
  });

  final String title;
  final String subtitle;
  final String name;
  final String address;
  final String phone;
  final String gst;
  final String id;
  final String pincode;
}
