import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/features/products/models/product_models.dart';
import 'package:m_o_b_demand_side/features/products/repositories/products_repository.dart';

class ProductDetailController extends ChangeNotifier {
  ProductDetailController({
    required String slug,
    ProductsRepository? repository,
  })  : _slug = slug,
        _repository = repository ?? const ProductsRepository();

  final String _slug;
  final ProductsRepository _repository;

  ProductModel? product;
  List<ProductModel> similarProducts = <ProductModel>[];
  bool isLoading = true;
  String? error;
  final Map<String, String?> selectedVariants = <String, String?>{};

  bool get hasProduct => product != null;

  Future<void> load({String? mobSku}) async {
    if (_slug.isEmpty) {
      error = 'No product slug provided.';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _repository.getProductDetails(
        slug: _slug,
        mobSku: (mobSku != null && mobSku.isNotEmpty) ? mobSku : null,
      );

      product = response.product;
      similarProducts = response.similarProducts;
      _syncVariantState(response.product);
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectVariant({
    required String key,
    required ProductVariantOption option,
  }) async {
    selectedVariants[key] = option.value;
    notifyListeners();
    await load(mobSku: option.mobSku);
  }

  void _syncVariantState(ProductModel current) {
    final validKeys = current.variants.keys.toSet();
    selectedVariants.removeWhere((key, _) => !validKeys.contains(key));

    for (final entry in current.variants.entries) {
      if (entry.value.isEmpty) {
        selectedVariants.remove(entry.key);
        continue;
      }
      final selected = selectedVariants[entry.key];
      final exists = entry.value.any((option) => option.value == selected);
      if (!exists) {
        selectedVariants[entry.key] = null;
      }
    }
  }
}
