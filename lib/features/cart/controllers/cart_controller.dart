import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/backend/api_requests/api_calls.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/network/app_error.dart';
import 'package:m_o_b_demand_side/features/cart/models/cart_item.dart';

class CartAddress {
  const CartAddress({
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

class CartController extends ChangeNotifier {
  CartController({List<CartItem>? initialItems})
      : _items = List<CartItem>.from(initialItems ?? const <CartItem>[]);

  List<CartItem> _items;
  bool _isLoading = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  bool _isUpdatingCart = false;
  String? _updatingItemKey;
  bool _requiresLogin = false;
  int _rfqItemCount = 0;

  double _subtotal = 0;
  double _shipping = 0;
  double _tax = 0;
  double _savings = 0;
  double _total = 0;
  int _rewardPoints = 0;
  int _itemCount = 0;
  String _shippingTitle = 'Shipping address';
  String _shippingSubtitle = 'Add an address to continue';
  String _shippingRecipientName = '';
  String _shippingAddress = '';
  String _shippingPhone = '';
  String _gstNumber = '';
  String _billingAddress = '';
  String _billingGstNumber = '';
  List<CartAddress> _savedAddresses = const <CartAddress>[];

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get isUpdatingCart => _isUpdatingCart;
  String? get updatingItemKey => _updatingItemKey;
  bool get requiresLogin => _requiresLogin;
  int get rfqItemCount => _rfqItemCount;
  bool get hasRfqItems => _rfqItemCount > 0;
  int get itemCount => _itemCount;

  double get subtotal => _subtotal;
  double get shipping => _shipping;
  double get tax => _tax;
  double get savings => _savings;
  double get total => _total;
  int get rewardPoints => _rewardPoints;
  String get shippingTitle => _shippingTitle;
  String get shippingSubtitle => _shippingSubtitle;
  String get shippingRecipientName => _shippingRecipientName;
  String get shippingAddress => _shippingAddress;
  String get shippingPhone => _shippingPhone;
  String get gstNumber => _gstNumber;
  String get billingAddress => _billingAddress;
  String get billingGstNumber => _billingGstNumber;
  List<CartAddress> get savedAddresses =>
      List<CartAddress>.unmodifiable(_savedAddresses);
  bool get hasDeliveryAddress => _shippingAddress.trim().isNotEmpty;

  Map<String, List<CartItem>> get itemsBySeller {
    final bySeller = <String, List<CartItem>>{};
    for (final item in _items) {
      bySeller.putIfAbsent(item.sellerCode, () => <CartItem>[]).add(item);
    }
    return bySeller;
  }

  void updateQuantity(CartItem item, int newQty) {
    if (newQty <= 0) {
      removeItem(item);
      return;
    }
    _changeQuantity(item, newQty);
  }

  void removeItem(CartItem item) {
    _deleteItem(item);
  }

  void onQuantityInputChanged(CartItem item, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return;
    }
    if (parsed <= 0) {
      removeItem(item);
      return;
    }
    _changeQuantity(item, parsed);
  }

  Future<void> loadCart() async {
    if (!AuthSession.instance.isAuthenticated) {
      _requiresLogin = true;
      _isLoading = false;
      _errorMessage = null;
      _items = <CartItem>[];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _actionErrorMessage = null;
    _requiresLogin = false;
    notifyListeners();

    try {
      final response = await GetCartCall.call(userDetails: true);
      if (!response.succeeded) {
        throw appExceptionFromApiResponse(
          response,
          fallbackMessage: 'Unable to load cart. Please try again.',
        );
      }

      final body = response.jsonBody is Map
          ? Map<String, dynamic>.from(response.jsonBody as Map)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      _applyServerData(data);
    } catch (e) {
      _items = <CartItem>[];
      _rfqItemCount = 0;
      _subtotal = 0;
      _shipping = 0;
      _tax = 0;
      _savings = 0;
      _total = 0;
      _rewardPoints = 0;
      _errorMessage = userMessageFromError(
        e,
        fallbackMessage: 'Unable to load cart. Please try again.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _changeQuantity(CartItem item, int newQty) async {
    final itemKey = item.itemKey.isNotEmpty
        ? item.itemKey
        : (item.vendorProductId.isNotEmpty ? item.vendorProductId : item.title);
    if (_isUpdatingCart) {
      return;
    }
    if (item.vendorProductId.isEmpty) {
      _errorMessage = 'Unable to update this cart item right now.';
      notifyListeners();
      return;
    }

    _isUpdatingCart = true;
    _updatingItemKey = itemKey;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final response = await AddToCartCall.call(
        items: [
          {
            'product': item.vendorProductId,
            'quantity': newQty,
          },
        ],
      );

      if (!response.succeeded) {
        throw appExceptionFromApiResponse(
          response,
          fallbackMessage: 'Unable to update cart item. Please try again.',
        );
      }

      final body = response.jsonBody is Map
          ? Map<String, dynamic>.from(response.jsonBody as Map)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      _applyServerData(data);
    } catch (e) {
      _actionErrorMessage = userMessageFromError(
        e,
        fallbackMessage: 'Unable to update cart item. Please try again.',
      );
    } finally {
      _isUpdatingCart = false;
      _updatingItemKey = null;
      notifyListeners();
    }
  }

  Future<void> _deleteItem(CartItem item) async {
    final itemKey = item.itemKey.isNotEmpty
        ? item.itemKey
        : (item.vendorProductId.isNotEmpty ? item.vendorProductId : item.title);
    if (_isUpdatingCart) {
      return;
    }
    if (item.cartItemId.isEmpty) {
      if (item.vendorProductId.isNotEmpty) {
        await _changeQuantity(item, 0);
        return;
      }
      _errorMessage = 'Unable to delete this cart item right now.';
      notifyListeners();
      return;
    }

    _isUpdatingCart = true;
    _updatingItemKey = itemKey;
    _actionErrorMessage = null;
    notifyListeners();

    try {
      final response =
          await RemoveCartItemCall.call(cartItemId: item.cartItemId);
      if (!response.succeeded) {
        throw appExceptionFromApiResponse(
          response,
          fallbackMessage: 'Unable to delete cart item. Please try again.',
        );
      }

      final body = response.jsonBody is Map
          ? Map<String, dynamic>.from(response.jsonBody as Map)
          : <String, dynamic>{};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      _applyServerData(data);
    } catch (e) {
      _actionErrorMessage = userMessageFromError(
        e,
        fallbackMessage: 'Unable to delete cart item. Please try again.',
      );
    } finally {
      _isUpdatingCart = false;
      _updatingItemKey = null;
      notifyListeners();
    }
  }

  void _applyServerData(Map<String, dynamic> data) {
    final itemMaps = _extractCartItemMapsFromServerData(data);
    _items = itemMaps.map(CartItem.fromMap).toList();
    _itemCount = _readFirstInt(
      data,
      const ['item_count', 'itemCount'],
      fallback: _items.fold<int>(0, (sum, item) => sum + item.qty),
    );

    _subtotal = _readFirstNum(
      data,
      const ['sub_cart_total', 'subTotal', 'subtotal'],
      fallback: _items.fold<double>(0, (sum, item) => sum + item.lineTotal),
    ).toDouble();
    _shipping = _readFirstNum(
      data,
      const ['shipping', 'shipping_charge', 'shippingCharges'],
    ).toDouble();
    _tax = _readFirstNum(
      data,
      const ['tax', 'total_tax', 'tax_total'],
    ).toDouble();
    _savings = _readFirstNum(
      data,
      const ['savings', 'discount'],
    ).toDouble();
    _total = _readFirstNum(
      data,
      const ['total', 'cart_total'],
      fallback: _subtotal + _shipping + _tax - _savings,
    ).toDouble();
    _rewardPoints = _readFirstInt(
      data,
      const [
        'reward_points',
        'rewardPoints',
        'points_earned',
        'pointsEarned',
        'mobstar_points',
        'mobstarPoints',
      ],
    );
    _rfqItemCount = _extractRfqItemCount(data['quote_cart']);
    _setShippingDetails(data['user_details']);
    _setBillingDetails(data);
    _setSavedAddresses(data);
  }

  List<Map<String, dynamic>> _extractCartItemMapsFromServerData(
    Map<String, dynamic> data,
  ) {
    final result = <Map<String, dynamic>>[];

    final subcarts = _toMapList(data['subcarts']);
    result.addAll(_itemsFromSubcarts(subcarts));

    final quickCommerce = data['quick_commerce'];
    if (quickCommerce is Map) {
      final quickSubcarts = _toMapList(quickCommerce['subcarts']);
      result.addAll(_itemsFromSubcarts(quickSubcarts));

      final quickProducts = _toMapList(quickCommerce['quick_products']);
      result.addAll(quickProducts);
    } else if (quickCommerce is List) {
      result.addAll(_itemsFromSubcarts(_toMapList(quickCommerce)));
    }

    if (result.isNotEmpty) {
      return result;
    }

    return _extractCartItemMaps(data);
  }

  List<Map<String, dynamic>> _itemsFromSubcarts(
      List<Map<String, dynamic>> subcarts) {
    final result = <Map<String, dynamic>>[];
    for (final subcart in subcarts) {
      final vendor = subcart['vendor'] is Map
          ? Map<String, dynamic>.from(subcart['vendor'] as Map)
          : <String, dynamic>{};
      final sellerCode = _readFirstString(
        vendor,
        const ['bmp_id', 'seller_code', 'sellerCode', 'vendor_code'],
        fallback: 'STORE',
      );

      final items = _toMapList(subcart['items']);
      for (final item in items) {
        final product = item['product'] is Map
            ? Map<String, dynamic>.from(item['product'] as Map)
            : <String, dynamic>{};
        final merged = <String, dynamic>{
          ...product,
          ...item,
          'seller_code': item['seller_code'] ?? sellerCode,
          'quantity': item['quantity'] ?? item['qty'] ?? 1,
          'vendor_product_id':
              item['vendor_product_id'] ?? product['vendor_product_id'],
          'cart_item_id': item['cart_item_id'] ?? item['id'],
          'vendor_selling_price':
              item['vendor_selling_price'] ?? product['vendor_selling_price'],
          'item_name_title':
              item['item_name_title'] ?? product['item_name_title'],
          'image':
              item['image'] ?? product['image'] ?? product['product_image'],
        };
        result.add(merged);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _extractCartItemMaps(Map<String, dynamic> data) {
    final candidateLists = <dynamic>[];
    const keys = <String>[
      'items',
      'cart_items',
      'cartItems',
      'products',
      'cart_products',
      'cartProducts',
      'results',
      'data',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        candidateLists.add(value);
      }
    }

    if (candidateLists.isEmpty) {
      final directList = data.values.whereType<List>();
      candidateLists.addAll(directList);
    }

    final flattened = <Map<String, dynamic>>[];
    for (final list in candidateLists) {
      for (final item in list as List) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (_looksLikeCartItem(map)) {
            flattened.add(map);
            continue;
          }
          final nested = _extractNestedItemMaps(map);
          flattened.addAll(nested);
        }
      }
    }
    return flattened;
  }

  List<Map<String, dynamic>> _extractNestedItemMaps(Map<String, dynamic> map) {
    final result = <Map<String, dynamic>>[];
    for (final value in map.values) {
      if (value is Map) {
        final nestedMap = Map<String, dynamic>.from(value);
        if (_looksLikeCartItem(nestedMap)) {
          result.add(nestedMap);
        } else {
          result.addAll(_extractNestedItemMaps(nestedMap));
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final nestedMap = Map<String, dynamic>.from(item);
            if (_looksLikeCartItem(nestedMap)) {
              result.add(nestedMap);
            } else {
              result.addAll(_extractNestedItemMaps(nestedMap));
            }
          }
        }
      }
    }
    return result;
  }

  bool _looksLikeCartItem(Map<String, dynamic> map) {
    const titleKeys = <String>[
      'item_name_title',
      'title',
      'name',
      'product_name',
      'item_name',
    ];
    const qtyKeys = <String>['quantity', 'qty', 'count', 'cart_quantity'];
    const priceKeys = <String>[
      'vendor_selling_price',
      'selling_price',
      'unit_price',
      'price',
      'amount',
    ];

    final hasTitle =
        titleKeys.any((k) => (map[k]?.toString().trim() ?? '').isNotEmpty);
    final hasQty =
        qtyKeys.any((k) => num.tryParse(map[k]?.toString() ?? '') != null);
    final hasPrice =
        priceKeys.any((k) => num.tryParse(map[k]?.toString() ?? '') != null);
    return hasTitle || (hasQty && hasPrice);
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _extractRfqItemCount(dynamic quoteCart) {
    if (quoteCart is Map) {
      final items = quoteCart['items'];
      if (items is List) {
        return items.length;
      }
      final subcarts = quoteCart['subcarts'];
      if (subcarts is List) {
        return subcarts
            .whereType<Map>()
            .fold<int>(0, (sum, sc) => sum + _listLength(sc['items']));
      }
      return 0;
    }
    if (quoteCart is List) {
      return quoteCart.whereType<Map>().fold<int>(
            0,
            (sum, sc) => sum + _listLength(sc['items']),
          );
    }
    return 0;
  }

  int _listLength(dynamic value) => value is List ? value.length : 0;

  void _setShippingDetails(dynamic userDetailsRaw) {
    if (userDetailsRaw is! Map) {
      _shippingTitle = 'Shipping address';
      _shippingSubtitle = 'Add an address to continue';
      _shippingRecipientName = '';
      _shippingAddress = '';
      _shippingPhone = '';
      _gstNumber = '';
      _billingAddress = '';
      _billingGstNumber = '';
      _savedAddresses = const <CartAddress>[];
      return;
    }
    final userDetails = Map<String, dynamic>.from(userDetailsRaw);
    final project = userDetails['project'] is Map
        ? Map<String, dynamic>.from(userDetails['project'] as Map)
        : <String, dynamic>{};
    final projectName = _readFirstString(
      project,
      const ['project_name', 'name'],
    );

    final name = _readFirstString(
      userDetails,
      const ['name', 'full_name', 'username'],
    );
    _shippingRecipientName = name;
    _shippingTitle = projectName.isNotEmpty
        ? 'Shipping to: $projectName'
        : (name.isNotEmpty ? 'Shipping to: $name' : 'Shipping address');

    final line1 = _readFirstString(
      userDetails,
      const ['address_line_1', 'address1', 'address'],
    );
    final line2 = _readFirstString(
      userDetails,
      const ['address_line_2', 'address2'],
    );
    final city = _readFirstString(userDetails, const ['city']);
    final state = _readFirstString(userDetails, const ['state']);
    final pincode = _readFirstString(userDetails, const ['pincode', 'zip']);
    _shippingPhone = _readFirstString(
      userDetails,
      const [
        'phone',
        'phone_number',
        'mobile',
        'mobile_number',
        'contact_number'
      ],
    );
    _gstNumber = _readFirstString(
      userDetails,
      const [
        'gst_number',
        'gst_no',
        'gstin',
        'gst',
        'tax_number',
      ],
    );

    final parts = <String>[
      line1,
      line2,
      city,
      state,
      pincode,
    ].where((e) => e.isNotEmpty).toList();
    _shippingAddress = parts.join(', ');
    _shippingSubtitle =
        parts.isNotEmpty ? parts.join(', ') : 'Address unavailable';
  }

  void _setBillingDetails(Map<String, dynamic> data) {
    final billingRaw = data['billing_details'] ??
        data['billing_address'] ??
        data['billingAddress'] ??
        data['billing'];
    if (billingRaw is! Map) {
      _billingAddress = _shippingAddress;
      _billingGstNumber = _gstNumber;
      return;
    }

    final billing = Map<String, dynamic>.from(billingRaw);
    final line1 = _readFirstString(
      billing,
      const ['address_line_1', 'address1', 'address'],
    );
    final line2 = _readFirstString(
      billing,
      const ['address_line_2', 'address2'],
    );
    final city = _readFirstString(billing, const ['city']);
    final state = _readFirstString(billing, const ['state']);
    final pincode = _readFirstString(billing, const ['pincode', 'zip']);
    final parts = <String>[
      line1,
      line2,
      city,
      state,
      pincode,
    ].where((e) => e.isNotEmpty).toList();

    _billingAddress = parts.isNotEmpty ? parts.join(', ') : _shippingAddress;
    _billingGstNumber = _readFirstString(
      billing,
      const [
        'gst_number',
        'gst_no',
        'gstin',
        'gst',
        'tax_number',
      ],
      fallback: _gstNumber,
    );
  }

  void _setSavedAddresses(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['addresses'],
      data['saved_addresses'],
      data['savedAddresses'],
      data['user_addresses'],
      data['delivery_addresses'],
      data['address_list'],
    ];
    final userDetails = data['user_details'];
    if (userDetails is Map) {
      candidates.addAll([
        userDetails['addresses'],
        userDetails['saved_addresses'],
        userDetails['savedAddresses'],
        userDetails['user_addresses'],
        userDetails['delivery_addresses'],
        userDetails['address_list'],
      ]);
    }

    final addresses = <CartAddress>[];
    for (final candidate in candidates) {
      addresses.addAll(_addressListFrom(candidate));
    }

    if (addresses.isEmpty && _shippingAddress.trim().isNotEmpty) {
      addresses.add(
        CartAddress(
          name: _shippingRecipientName,
          address: _shippingAddress,
          phone: _shippingPhone,
          tag: 'Delivery',
          project: _shippingTitle.replaceFirst('Shipping to: ', ''),
          gstNumber: _gstNumber,
        ),
      );
    }

    final seen = <String>{};
    _savedAddresses = addresses.where((address) {
      final key = [
        address.name,
        address.address,
        address.phone,
      ].join('|').toLowerCase();
      return address.hasAddress && seen.add(key);
    }).toList();
  }

  List<CartAddress> _addressListFrom(dynamic value) {
    if (value is! List) {
      return const <CartAddress>[];
    }
    return value
        .whereType<Map>()
        .map((entry) => _addressFromMap(Map<String, dynamic>.from(entry)))
        .where((address) => address.hasAddress)
        .toList();
  }

  CartAddress _addressFromMap(Map<String, dynamic> map) {
    final line1 = _readFirstString(
      map,
      const ['address_line_1', 'address1', 'address'],
    );
    final line2 = _readFirstString(
      map,
      const ['address_line_2', 'address2'],
    );
    final city = _readFirstString(map, const ['city']);
    final state = _readFirstString(map, const ['state']);
    final pincode = _readFirstString(map, const ['pincode', 'zip']);
    final parts = <String>[
      line1,
      line2,
      city,
      state,
      pincode,
    ].where((e) => e.isNotEmpty).toList();

    return CartAddress(
      name: _readFirstString(
        map,
        const ['name', 'full_name', 'username', 'recipient_name'],
        fallback: _shippingRecipientName,
      ),
      address: parts.join(', '),
      phone: _readFirstString(
        map,
        const [
          'phone',
          'phone_number',
          'mobile',
          'mobile_number',
          'contact_number',
        ],
      ),
      tag: _readFirstString(
        map,
        const ['tag', 'type', 'address_type', 'label'],
        fallback: 'Address',
      ),
      project: _readFirstString(
        map,
        const ['project_name', 'project', 'projectName'],
      ),
      gstNumber: _readFirstString(
        map,
        const ['gst_number', 'gst_no', 'gstin', 'gst', 'tax_number'],
      ),
    );
  }

  String _readFirstString(
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

  int _readFirstInt(
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

  num _readFirstNum(
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
