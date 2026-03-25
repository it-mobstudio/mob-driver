import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/features/cart/models/cart_item.dart';

class CartController extends ChangeNotifier {
  CartController({List<CartItem>? initialItems})
      : _items = List<CartItem>.from(initialItems ?? _demoItems);

  static const double defaultShipping = 500;
  static const double defaultTax = 433;
  static const double defaultSavings = 1055;
  static const double savingsBannerAmount = 7200;

  List<CartItem> _items;

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  double get subtotal =>
      _items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get shipping => defaultShipping;
  double get tax => defaultTax;
  double get savings => defaultSavings;
  double get total => subtotal + shipping + tax - savings;

  Map<String, List<CartItem>> get itemsBySeller {
    final bySeller = <String, List<CartItem>>{};
    for (final item in _items) {
      bySeller.putIfAbsent(item.sellerCode, () => <CartItem>[]).add(item);
    }
    return bySeller;
  }

  void updateQuantity(CartItem item, int newQty) {
    final index = _items.indexOf(item);
    if (index < 0) {
      return;
    }

    if (newQty <= 0) {
      removeItem(item);
      return;
    }

    _items[index] = _items[index].copyWith(qty: newQty);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items = _items.where((e) => e != item).toList();
    notifyListeners();
  }
}

const List<CartItem> _demoItems = <CartItem>[
  CartItem(
    title:
        'Hindware 121 mm Round Brass Silver Wall Mount Overhead Rain Shower F1…',
    imageAsset: 'assets/sample_product.png',
    qty: 1,
    unitPrice: 4250,
    sellerCode: 'BENG-098',
  ),
  CartItem(
    title:
        'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower, F160119',
    imageAsset: 'assets/sample_product.png',
    qty: 2,
    unitPrice: 1533,
    sellerCode: 'BENG-098',
  ),
  CartItem(
    title: 'Hindware Overhead Shower 150 mm White ABS Round, F160216',
    imageAsset: 'assets/sample_product.png',
    qty: 3,
    unitPrice: 2325,
    sellerCode: 'BENG-004',
  ),
  CartItem(
    title:
        'Hindware Single Flow Overhead Round Shower Single Flow, Rain Flow, 23…',
    imageAsset: 'assets/sample_product.png',
    qty: 4,
    unitPrice: 3175,
    sellerCode: 'BENG-004',
  ),
];
