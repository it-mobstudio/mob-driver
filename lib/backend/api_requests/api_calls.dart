import 'api_manager.dart';
import 'dart:convert';
import '/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';

export 'api_manager.dart' show ApiCallResponse;

const Map<String, String> _jsonHeaders = {
  'Content-Type': 'application/json',
};

class LoginOTPCall {
  /// Calls the login OTP API with the given phone/email and type.
  static Future<ApiCallResponse> call({
    required int emailOrPhone,
    bool isPhone = true,
  }) async {
    final Map<String, dynamic> body = {
      'email_or_phone': emailOrPhone,
      'isPhone': isPhone,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'loginOTP',
      apiUrl: AppConfig.apiUri('/accounts/mob_user/auth/send_otp/').toString(),
      callType: ApiCallType.POST,
      headers: _jsonHeaders,
      params: {},
      body: json.encode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class HomeDataCall {
  /// Calls the home API to fetch categories and other home data.
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'homeData',
      apiUrl: AppConfig.apiUri('/home/').toString(),
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class CheckOTPCall {
  /// Calls the check OTP API with the given phone and otp.
  static Future<ApiCallResponse> call({
    required String phone,
    required String otp,
  }) async {
    final Map<String, dynamic> body = {
      'email_or_phone': phone,
      'otp': otp,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'checkOTP',
      apiUrl: AppConfig.apiUri('/accounts/mob_user/auth/check_otp/').toString(),
      callType: ApiCallType.POST,
      headers: _jsonHeaders,
      params: {},
      body: json.encode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BrowseProductsCall {
  /// Calls the browse products API for a given category name.
  static Future<ApiCallResponse> call({
    required String categoryName,
    int page = 1,
    bool isProfessional = true,
  }) async {
    final apiUrl = AppConfig.apiUri(
      '/home/$categoryName/browse_products/',
      queryParameters: {
        'page': page,
        'is_professional': isProfessional,
      },
    ).toString();
    return ApiManager.instance.makeApiCall(
      callName: 'browseProducts',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class BrowseProductFiltersCall {
  /// Calls the browse product filters API for a given category or subcategory.
  static Future<ApiCallResponse> call({
    required String search,
    bool isProfessional = true,
  }) async {
    final apiUrl = AppConfig.apiUri(
      '/home/get_filters/',
      queryParameters: {
        'search': search,
        'quick_ecommerce': true,
        'is_professional': isProfessional,
      },
    ).toString();
    return ApiManager.instance.makeApiCall(
      callName: 'browseProductFilters',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ProductDetailsCall {
  /// Calls the product details API for a given product slug.
  static Future<ApiCallResponse> call({
    required String slug,
    String? mobSku,
  }) async {
    final apiUrl = AppConfig.apiUri(
      '/home/$slug/get_product_details/',
      queryParameters:
          mobSku != null && mobSku.isNotEmpty ? {'mob_sku': mobSku} : null,
    ).toString();
    return ApiManager.instance.makeApiCall(
      callName: 'productDetails',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ProductSearchCall {
  static Future<ApiCallResponse> call({
    required String query,
  }) async {
    final apiUrl = AppConfig.apiUri(
      '/home/product_search/',
      queryParameters: {'search': query},
    ).toString();
    return ApiManager.instance.makeApiCall(
      callName: 'productSearch',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class AddToCartCall {
  /// Calls the add to cart API with a list of products and quantities.
  static Future<ApiCallResponse> call({
    required List<Map<String, dynamic>> items,
  }) async {
    final apiUrl = AppConfig.apiUri('/orders/cart/add_to_cart/').toString();
    final body = <String, dynamic>{'items': items};
    return ApiManager.instance.makeApiCall(
      callName: 'addToCart',
      apiUrl: apiUrl,
      callType: ApiCallType.POST,
      headers: _jsonHeaders,
      params: {},
      body: json.encode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCartCall {
  /// Calls the get cart API.
  static Future<ApiCallResponse> call({
    bool userDetails = true,
  }) async {
    final apiUrl = AppConfig.apiUri(
      '/orders/cart/get_cart/',
      queryParameters: {
        'userDetails': userDetails,
      },
    ).toString();

    return ApiManager.instance.makeApiCall(
      callName: 'getCart',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: _jsonHeaders,
      params: const {},
      returnBody: true,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RemoveCartItemCall {
  /// Calls the remove cart item API.
  static Future<ApiCallResponse> call({
    required String cartItemId,
  }) async {
    final apiUrl =
        AppConfig.apiUri('/orders/cart/remove_cart_item/').toString();
    final body = <String, dynamic>{
      'cart_item_id': cartItemId,
      'cartItemId': cartItemId,
      'id': cartItemId,
      'cart_item_ids': [cartItemId],
      'cartItemIds': [cartItemId],
    };

    return ApiManager.instance.makeApiCall(
      callName: 'removeCartItem',
      apiUrl: apiUrl,
      callType: ApiCallType.POST,
      headers: _jsonHeaders,
      params: const {},
      body: json.encode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RegisterUserCall {
  static Future<ApiCallResponse> call({
    required String name,
    String? phone,
    String? email,
    FFUploadedFile? profilePicture,
    String? gstin,
    String? businessName,
  }) async {
    final Map<String, dynamic> formData = {
      'full_name': name,
      if (phone != null && phone.isNotEmpty) 'email_or_phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (profilePicture != null) 'profile_picture': profilePicture,
    };

    return ApiManager.instance.makeApiCall(
      callName: 'registerUser',
      apiUrl:
          AppConfig.apiUri('/accounts/mob_user/auth/update_user/').toString(),
      callType: ApiCallType.POST,
      headers: const {},
      params: formData,
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
