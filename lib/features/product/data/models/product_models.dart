class VendorPricing {
  const VendorPricing({
    required this.vendorSellingPrice,
    required this.discount,
    required this.fullfillmentLatency,
    required this.vendorProductId,
    required this.bmpId,
    required this.quickEcommerceEnabled,
  });

  final num vendorSellingPrice;
  final num discount;
  final String fullfillmentLatency;
  final String vendorProductId;
  final String bmpId;
  final bool quickEcommerceEnabled;

  factory VendorPricing.fromMap(Map<String, dynamic> map) {
    return VendorPricing(
      vendorSellingPrice:
          num.tryParse(map['vendor_selling_price']?.toString() ?? '0') ?? 0,
      discount: num.tryParse(map['discount']?.toString() ?? '0') ?? 0,
      fullfillmentLatency: map['fullfillment_latency']?.toString() ?? '',
      vendorProductId: map['vendor_product_id']?.toString() ?? '',
      bmpId: map['bmp_id']?.toString() ?? '',
      quickEcommerceEnabled: _parseBool(map['quick_ecommerce_enabled']),
    );
  }
}

class ProductSellerOffer {
  const ProductSellerOffer({
    required this.vendorSellingPrice,
    required this.discount,
    required this.fullfillmentLatency,
    required this.vendorProductId,
    required this.bmpId,
    required this.quickEcommerceEnabled,
    required this.stock,
  });

  final num vendorSellingPrice;
  final num discount;
  final String fullfillmentLatency;
  final String vendorProductId;
  final String bmpId;
  final bool quickEcommerceEnabled;
  final num stock;

  factory ProductSellerOffer.fromMap(Map<String, dynamic> map) {
    return ProductSellerOffer(
      vendorSellingPrice:
          num.tryParse(map['vendor_selling_price']?.toString() ?? '0') ?? 0,
      discount: num.tryParse(map['discount']?.toString() ?? '0') ?? 0,
      fullfillmentLatency: map['fullfillment_latency']?.toString() ?? '',
      vendorProductId: map['vendor_product_id']?.toString() ?? '',
      bmpId: (map['bmp_id'] ?? map['routing_id'] ?? '').toString(),
      quickEcommerceEnabled: _parseBool(map['quick_ecommerce_enabled']),
      stock: num.tryParse(
            (map['stock'] ??
                    (map['stock_details'] is Map
                        ? (map['stock_details'] as Map)['stock']
                        : null) ??
                    '0')
                .toString(),
          ) ??
          0,
    );
  }
}

class ProductImageRef {
  const ProductImageRef({required this.url});

  final String url;

  factory ProductImageRef.fromMap(Map<String, dynamic> map) =>
      ProductImageRef(url: map['image']?.toString() ?? '');
}

class ProductVariantOption {
  const ProductVariantOption({
    required this.value,
    required this.mobSku,
  });

  final String value;
  final String mobSku;

  factory ProductVariantOption.fromMap(Map<String, dynamic> map) {
    return ProductVariantOption(
      value: map['value']?.toString() ?? '',
      mobSku: map['mob_sku']?.toString() ?? '',
    );
  }
}

class ProductVariantCombination {
  const ProductVariantCombination({
    required this.attributes,
    required this.mobSku,
    required this.slug,
    required this.productId,
    required this.stock,
    required this.isAvailable,
    required this.inStock,
    required this.stockStatus,
  });

  final Map<String, String> attributes;
  final String mobSku;
  final String slug;
  final String productId;
  final num stock;
  final bool isAvailable;
  final bool inStock;
  final String stockStatus;

  factory ProductVariantCombination.fromMap(Map<String, dynamic> map) {
    final attributesMap = map['attributes'] is Map
        ? Map<String, dynamic>.from(map['attributes'] as Map)
        : <String, dynamic>{};
    return ProductVariantCombination(
      attributes: attributesMap.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
      mobSku: (map['mob_sku'] ?? map['sku'] ?? '').toString(),
      slug: map['slug']?.toString() ?? '',
      productId: (map['product_id'] ?? map['id'] ?? '').toString(),
      stock: num.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      isAvailable: map['is_available'] == null || _parseBool(map['is_available']),
      inStock: map['in_stock'] == null || _parseBool(map['in_stock']),
      stockStatus: map['stock_status']?.toString() ?? '',
    );
  }
}

class ProductChildVariantInfo {
  const ProductChildVariantInfo({
    required this.value,
    this.name = '',
  });

  final String value;
  final String name;

  factory ProductChildVariantInfo.fromMap(Map<String, dynamic> map) {
    return ProductChildVariantInfo(
      value: map['value']?.toString() ?? '',
      name: (map['name'] ??
              map['key'] ??
              map['label'] ??
              map['variant_name'] ??
              map['attribute_name'] ??
              '')
          .toString(),
    );
  }
}

class ProductChildRef {
  const ProductChildRef({
    required this.stock,
    required this.id,
    required this.slug,
    required this.title,
    required this.imageUrl,
    required this.mobSku,
    required this.vendorProductId,
    required this.productPrice,
    required this.maximumRetailPrice,
    required this.discount,
    required this.quickEcommerceEnabled,
    required this.variantInfo,
  });

  final num stock;
  final String id;
  final String slug;
  final String title;
  final String imageUrl;
  final String mobSku;
  final String vendorProductId;
  final num productPrice;
  final num maximumRetailPrice;
  final num discount;
  final bool quickEcommerceEnabled;
  final List<ProductChildVariantInfo> variantInfo;

  String get label {
    final values = variantInfo
        .map((item) => item.value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isNotEmpty) {
      return values.join(' - ');
    }
    return title;
  }

  factory ProductChildRef.fromMap(Map<String, dynamic> map) {
    final vendorPricingMap = map['vendorPricings'] is Map
        ? Map<String, dynamic>.from(map['vendorPricings'] as Map)
        : <String, dynamic>{};
    final variantInfoRaw = map['variant_info'] is List
        ? List<dynamic>.from(map['variant_info'] as List)
        : <dynamic>[];
    return ProductChildRef(
      stock: num.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      id: (map['product_id'] ?? map['id'] ?? '').toString(),
      slug: map['slug']?.toString() ?? '',
      title: (map['item_name_title'] ?? map['product_name'] ?? '').toString(),
      imageUrl: (map['image'] ?? map['primary_image'] ?? '').toString(),
      mobSku: map['mob_sku']?.toString() ?? '',
      vendorProductId:
          (map['vendor_product_id'] ?? vendorPricingMap['vendor_product_id'] ?? '')
              .toString(),
      productPrice: num.tryParse(
            (vendorPricingMap['vendor_selling_price'] ?? map['product_price'] ?? '0')
                .toString(),
          ) ??
          0,
      maximumRetailPrice: num.tryParse(
            (vendorPricingMap['maximum_retail_price'] ?? map['mrp'] ?? '0')
                .toString(),
          ) ??
          0,
      discount: num.tryParse(
            (map['discount'] ?? vendorPricingMap['discount'] ?? '0').toString(),
          ) ??
          0,
      quickEcommerceEnabled: _parseBool(
        map['quick_ecommerce_enabled'] ?? vendorPricingMap['quick_ecommerce_enabled'],
      ),
      variantInfo: variantInfoRaw
          .whereType<Map>()
          .map(
            (e) => ProductChildVariantInfo.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }

  ProductModel toProductModel(ProductModel parent) {
    return ProductModel(
      id: id.isNotEmpty ? id : parent.id,
      slug: slug.isNotEmpty ? slug : parent.slug,
      title: title.isNotEmpty ? title : parent.title,
      mobSku: mobSku,
      maximumRetailPrice:
          maximumRetailPrice > 0 ? maximumRetailPrice : parent.maximumRetailPrice,
      rating: parent.rating,
      reviewCount: parent.reviewCount,
      productDescription: parent.productDescription,
      productBulletPoints: parent.productBulletPoints,
      vendorPricing: VendorPricing(
        vendorSellingPrice:
            productPrice > 0 ? productPrice : parent.vendorPricing.vendorSellingPrice,
        discount: discount,
        fullfillmentLatency: parent.vendorPricing.fullfillmentLatency,
        vendorProductId: vendorProductId.isNotEmpty
            ? vendorProductId
            : parent.vendorPricing.vendorProductId,
        bmpId: parent.vendorPricing.bmpId,
        quickEcommerceEnabled:
            quickEcommerceEnabled || parent.vendorPricing.quickEcommerceEnabled,
      ),
      images: imageUrl.isNotEmpty
          ? <ProductImageRef>[ProductImageRef(url: imageUrl)]
          : parent.images,
      features: parent.features,
      variants: const <String, List<ProductVariantOption>>{},
      variantAttributes: const <String>[],
      availableOptions: const <String, List<String>>{},
      activeVariantSelections: const <String, String>{},
      variantCombinations: const <ProductVariantCombination>[],
      sellers: const <ProductSellerOffer>[],
      brandName: parent.brandName,
      brandLogoUrl: parent.brandLogoUrl,
      brandSegmentName: parent.brandSegmentName,
      quickCommerceCategoryName: parent.quickCommerceCategoryName,
      badgeOption: parent.badgeOption,
      stock: stock,
      stockDetailsStock: stock,
      quickEcommerceEnabled:
          quickEcommerceEnabled || parent.quickEcommerceEnabled,
      childProducts: const <ProductChildRef>[],
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.mobSku,
    required this.maximumRetailPrice,
    required this.rating,
    required this.reviewCount,
    required this.productDescription,
    required this.productBulletPoints,
    required this.vendorPricing,
    required this.images,
    required this.features,
    required this.variants,
    required this.variantAttributes,
    required this.availableOptions,
    required this.activeVariantSelections,
    required this.variantCombinations,
    required this.sellers,
    required this.brandName,
    required this.brandLogoUrl,
    required this.brandSegmentName,
    required this.quickCommerceCategoryName,
    required this.badgeOption,
    required this.stock,
    required this.stockDetailsStock,
    required this.quickEcommerceEnabled,
    required this.childProducts,
  });

  final String id;
  final String slug;
  final String title;
  final String mobSku;
  final num maximumRetailPrice;
  final num rating;
  final int reviewCount;
  final String productDescription;
  final String productBulletPoints;
  final VendorPricing vendorPricing;
  final List<ProductImageRef> images;
  final Map<String, String> features;
  final Map<String, List<ProductVariantOption>> variants;
  final List<String> variantAttributes;
  final Map<String, List<String>> availableOptions;
  final Map<String, String> activeVariantSelections;
  final List<ProductVariantCombination> variantCombinations;
  final List<ProductSellerOffer> sellers;
  final String brandName;
  final String brandLogoUrl;
  final String brandSegmentName;
  final String quickCommerceCategoryName;
  final String badgeOption;
  final num stock;
  final num stockDetailsStock;
  final bool quickEcommerceEnabled;
  final List<ProductChildRef> childProducts;

  String get primaryImageUrl => images.isNotEmpty ? images.first.url : '';
  bool get hasVariants =>
      variants.values.any((v) => v.isNotEmpty) ||
      variantCombinations.isNotEmpty ||
      childProducts.isNotEmpty;
  int get variantOptionCount {
    final variantsCount = variants.values.fold<int>(
      0,
      (sum, options) => sum + options.length,
    );
    if (variantsCount > 0) return variantsCount;
    if (variantCombinations.isNotEmpty) {
      final keys = variantAttributes.isNotEmpty
          ? variantAttributes
          : variantCombinations.first.attributes.keys.toList();
      return keys.fold<int>(0, (sum, key) {
        return sum +
            variantCombinations
                .map((c) => c.attributes[key]?.trim() ?? '')
                .where((v) => v.isNotEmpty)
                .toSet()
                .length;
      });
    }
    return childProducts.length;
  }
  String get addToCartProductId =>
      vendorPricing.vendorProductId.isNotEmpty ? vendorPricing.vendorProductId : id;
  bool get isQuickEcommerceEnabled =>
      quickEcommerceEnabled || vendorPricing.quickEcommerceEnabled;
  bool get hasVariantLevelStock =>
      childProducts.any((child) => child.stock > 0) ||
      variantCombinations.any((combo) => combo.inStock);
  int get availableStock {
    final parsed = stockDetailsStock > 0 ? stockDetailsStock : stock;
    return parsed > 0 ? parsed.toInt() : 0;
  }
  bool get isOutOfStockForQuickProduct =>
      isQuickEcommerceEnabled &&
      (hasVariants ? !hasVariantLevelStock : availableStock <= 0);
  bool get shouldShowNotify =>
      badgeOption.toLowerCase() == 'sold out' || isOutOfStockForQuickProduct;

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final vendorPricingMap = map['vendorPricings'] is Map
        ? Map<String, dynamic>.from(map['vendorPricings'] as Map)
        : <String, dynamic>{};
    final imagesList = map['images'] is List
        ? List<dynamic>.from(map['images'] as List)
        : <dynamic>[];
    final featuresMap = map['features'] is Map
        ? Map<String, dynamic>.from(map['features'] as Map)
        : <String, dynamic>{};
    final variantsMap = map['variants'] is Map
        ? Map<String, dynamic>.from(map['variants'] as Map)
        : <String, dynamic>{};
    final variantCombinationsRaw = map['variants'] is List
        ? List<dynamic>.from(map['variants'] as List)
        : (map['variant_combinations'] is List
            ? List<dynamic>.from(map['variant_combinations'] as List)
            : <dynamic>[]);
    final variantAttributesList = map['variant_attributes'] is List
        ? List<dynamic>.from(map['variant_attributes'] as List)
        : <dynamic>[];
    final availableOptionsMap = map['available_options'] is Map
        ? Map<String, dynamic>.from(map['available_options'] as Map)
        : <String, dynamic>{};
    final activeVariantMap = map['active_variant'] is Map
        ? Map<String, dynamic>.from(map['active_variant'] as Map)
        : <String, dynamic>{};
    final activeSelectedOptionsMap = activeVariantMap['selected_options'] is Map
        ? Map<String, dynamic>.from(activeVariantMap['selected_options'] as Map)
        : <String, dynamic>{};
    final brandSegment = map['brand_segment'] is Map
        ? Map<String, dynamic>.from(map['brand_segment'] as Map)
        : <String, dynamic>{};
    final brandMap = map['brand'] is Map
        ? Map<String, dynamic>.from(map['brand'] as Map)
        : (map['brand_details'] is Map
            ? Map<String, dynamic>.from(map['brand_details'] as Map)
            : <String, dynamic>{});
    final quickCommerceCategory = map['quick_commerce_category'] is Map
        ? Map<String, dynamic>.from(map['quick_commerce_category'] as Map)
        : <String, dynamic>{};
    final stockDetails = map['stock_details'] is Map
        ? Map<String, dynamic>.from(map['stock_details'] as Map)
        : <String, dynamic>{};
    final childProductsList = map['child_products'] is List
        ? List<dynamic>.from(map['child_products'] as List)
        : <dynamic>[];
    final sellersRaw = map['vendors'] is List
        ? List<dynamic>.from(map['vendors'] as List)
        : <dynamic>[];

    return ProductModel(
      id: map['id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      title: map['item_name_title']?.toString() ?? '',
      mobSku: map['mob_sku']?.toString() ?? '',
      maximumRetailPrice: num.tryParse(
            (map['maximum_retail_price'] ??
                    vendorPricingMap['maximum_retail_price'] ??
                    map['mrp'] ??
                    '0')
                .toString(),
          ) ??
          0,
      rating: num.tryParse(map['rating']?.toString() ?? '0') ?? 0,
      reviewCount: int.tryParse(map['review_count']?.toString() ?? '0') ?? 0,
      productDescription: map['product_description']?.toString() ?? '',
      productBulletPoints: map['product_bullet_points']?.toString() ?? '',
      vendorPricing: VendorPricing.fromMap(vendorPricingMap),
      images: imagesList
          .whereType<Map>()
          .map((e) => ProductImageRef.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      features: featuresMap.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
      variants: variantsMap.map((key, value) {
        final list = value is List ? value : <dynamic>[];
        return MapEntry(
          key.toString(),
          list
              .whereType<Map>()
              .map((e) =>
                  ProductVariantOption.fromMap(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }),
      variantAttributes: variantAttributesList
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      availableOptions: availableOptionsMap.map((key, value) {
        final list = value is List ? value : <dynamic>[];
        return MapEntry(
          key.toString(),
          list
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .toList(),
        );
      }),
      activeVariantSelections: activeSelectedOptionsMap.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      ),
      variantCombinations: variantCombinationsRaw
          .whereType<Map>()
          .map((e) => ProductVariantCombination.fromMap(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      sellers: sellersRaw
          .whereType<Map>()
          .map((e) => ProductSellerOffer.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      brandName: (map['brand_name'] ??
              brandMap['name'] ??
              brandMap['brand_name'] ??
              map['brand_title'] ??
              (map['brand'] is String ? map['brand'] : null) ??
              '')
          .toString(),
      brandLogoUrl: (map['brand_logo'] ??
              map['brand_logo_url'] ??
              brandMap['logo'] ??
              brandMap['image'] ??
              brandMap['logo_url'] ??
              '')
          .toString(),
      brandSegmentName: brandSegment['name']?.toString() ?? '',
      quickCommerceCategoryName:
          quickCommerceCategory['display_name']?.toString() ?? '',
      badgeOption: map['badge_option']?.toString() ?? '',
      stock: num.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      stockDetailsStock:
          num.tryParse(stockDetails['stock']?.toString() ?? '0') ?? 0,
      quickEcommerceEnabled: _parseBool(map['quick_ecommerce_enabled']),
      childProducts: childProductsList
          .whereType<Map>()
          .map((e) => ProductChildRef.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

class SubCategoryModel {
  const SubCategoryModel({
    required this.name,
    required this.image,
    required this.slug,
  });

  final String name;
  final String image;
  final String slug;

  String get browseSlug => slug.isNotEmpty ? slug : _slugFromName(name);

  factory SubCategoryModel.fromMap(Map<String, dynamic> map) {
    return SubCategoryModel(
      name: map['sub_category_name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      slug: (map['sub_category_slug'] ??
              map['slug'] ??
              map['category_slug'] ??
              map['sub_category'] ??
              '')
          .toString(),
    );
  }
}

String _slugFromName(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class PaginationModel {
  const PaginationModel({
    required this.isNextPage,
    required this.nextPage,
  });

  final bool isNextPage;
  final int nextPage;

  factory PaginationModel.fromMap(Map<String, dynamic> map) {
    return PaginationModel(
      isNextPage: map['is_next_page'] == true,
      nextPage: int.tryParse(map['next_page']?.toString() ?? '0') ?? 0,
    );
  }
}

class BrowseProductsResult {
  const BrowseProductsResult({
    required this.products,
    required this.subCategories,
    required this.pagination,
  });

  final List<ProductModel> products;
  final List<SubCategoryModel> subCategories;
  final PaginationModel pagination;
}

class BrowseFilterOption {
  const BrowseFilterOption({
    required this.value,
    required this.label,
    required this.count,
  });

  final String value;
  final String label;
  final int count;

  factory BrowseFilterOption.fromMap(Map<String, dynamic> map) {
    return BrowseFilterOption(
      value: map['value']?.toString() ?? '',
      label: map['label']?.toString() ?? map['value']?.toString() ?? '',
      count: int.tryParse(map['count']?.toString() ?? '0') ?? 0,
    );
  }
}

class BrowseFilterSection {
  const BrowseFilterSection({
    required this.key,
    required this.label,
    required this.searchable,
    required this.options,
    required this.meta,
  });

  final String key;
  final String label;
  final bool searchable;
  final List<BrowseFilterOption> options;
  final Map<String, dynamic> meta;

  factory BrowseFilterSection.fromMap(Map<String, dynamic> map) {
    final optionsRaw =
        map['options'] is List ? List<dynamic>.from(map['options'] as List) : <dynamic>[];
    final metaMap = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};
    final bucketsRaw = metaMap['buckets'] is List
        ? List<dynamic>.from(metaMap['buckets'] as List)
        : <dynamic>[];
    final options = optionsRaw
        .whereType<Map>()
        .map((e) => BrowseFilterOption.fromMap(Map<String, dynamic>.from(e)))
        .where((option) => option.label.isNotEmpty)
        .toList();
    if (options.isEmpty && bucketsRaw.isNotEmpty) {
      options.addAll(
        bucketsRaw.whereType<Map>().map((bucket) {
          final from = bucket['from']?.toString() ?? '';
          final to = bucket['to']?.toString() ?? '';
          final label = from.isNotEmpty && to.isNotEmpty
              ? '\u20B9$from - \u20B9$to'
              : [from, to].where((value) => value.isNotEmpty).join(' - ');
          return BrowseFilterOption(
            value: [from, to].where((value) => value.isNotEmpty).join(','),
            label: label,
            count: 0,
          );
        }).where((option) => option.label.isNotEmpty),
      );
    }
    return BrowseFilterSection(
      key: map['key']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      searchable: map['searchable'] == true,
      options: options,
      meta: metaMap,
    );
  }
}

class ProductDetailsResult {
  const ProductDetailsResult({
    required this.product,
    required this.similarProducts,
  });

  final ProductModel product;
  final List<ProductModel> similarProducts;
}
