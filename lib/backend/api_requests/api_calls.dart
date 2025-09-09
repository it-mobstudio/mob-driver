import 'api_manager.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
export 'api_manager.dart' show ApiCallResponse;

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
      apiUrl:
          'https://uat.madoverbuilding.com/api/accounts/mob_user/auth/send_otp/',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
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
      apiUrl: 'https://uat.madoverbuilding.com/api/home/',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
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
      apiUrl:
          'https://uat.madoverbuilding.com/api/accounts/mob_user/auth/check_otp/',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
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
    final apiUrl =
        'https://uat.madoverbuilding.com/api/home/$categoryName/browse_products/?page=$page&is_professional=$isProfessional';
    return ApiManager.instance.makeApiCall(
      callName: 'browseProducts',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
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
    String apiUrl =
        'https://uat.madoverbuilding.com/api/home/$slug/get_product_details/';
    if (mobSku != null && mobSku.isNotEmpty) {
      apiUrl += '?mob_sku=$mobSku';
    }
    return ApiManager.instance.makeApiCall(
      callName: 'productDetails',
      apiUrl: apiUrl,
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
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
    final apiUrl =
        'https://uat.madoverbuilding.com/api/orders/cart/add_to_cart/';
    return ApiManager.instance.makeApiCall(
      callName: 'addToCart',
      apiUrl: apiUrl,
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: json.encode(items),
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

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
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
