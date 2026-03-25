class VendorPricing {
  const VendorPricing({
    required this.vendorSellingPrice,
    required this.discount,
    required this.fullfillmentLatency,
    required this.vendorProductId,
    required this.bmpId,
  });

  final num vendorSellingPrice;
  final num discount;
  final String fullfillmentLatency;
  final String vendorProductId;
  final String bmpId;

  factory VendorPricing.fromMap(Map<String, dynamic> map) {
    return VendorPricing(
      vendorSellingPrice:
          num.tryParse(map['vendor_selling_price']?.toString() ?? '0') ?? 0,
      discount: num.tryParse(map['discount']?.toString() ?? '0') ?? 0,
      fullfillmentLatency: map['fullfillment_latency']?.toString() ?? '',
      vendorProductId: map['vendor_product_id']?.toString() ?? '',
      bmpId: map['bmp_id']?.toString() ?? '',
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

  String get primaryImageUrl => images.isNotEmpty ? images.first.url : '';
  bool get hasVariants => variants.values.any((v) => v.isNotEmpty);
  String get addToCartProductId =>
      vendorPricing.vendorProductId.isNotEmpty ? vendorPricing.vendorProductId : id;

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

    return ProductModel(
      id: map['id']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      title: map['item_name_title']?.toString() ?? '',
      mobSku: map['mob_sku']?.toString() ?? '',
      maximumRetailPrice:
          num.tryParse(map['maximum_retail_price']?.toString() ?? '0') ?? 0,
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
    );
  }
}

class SubCategoryModel {
  const SubCategoryModel({
    required this.name,
    required this.image,
  });

  final String name;
  final String image;

  factory SubCategoryModel.fromMap(Map<String, dynamic> map) {
    return SubCategoryModel(
      name: map['sub_category_name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
    );
  }
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

class ProductDetailsResult {
  const ProductDetailsResult({
    required this.product,
    required this.similarProducts,
  });

  final ProductModel product;
  final List<ProductModel> similarProducts;
}
