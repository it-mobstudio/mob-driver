import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  late final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> enableCollection() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  Future<void> logCategoryOpened({
    required String category,
    required String slug,
  }) async {
    await _analytics.logEvent(
      name: 'category_opened',
      parameters: <String, Object>{
        'category': category,
        'slug': slug,
      },
    );
  }

  Future<void> logProductViewed({
    required String slug,
    String? title,
  }) async {
    await _analytics.logViewItem(
      items: <AnalyticsEventItem>[
        AnalyticsEventItem(
          itemId: slug,
          itemName: title,
        ),
      ],
    );
  }

  Future<void> logSearch({
    required String query,
    required int resultCount,
  }) async {
    await _analytics.logEvent(
      name: 'search_performed',
      parameters: <String, Object>{
        'query': query,
        'results': resultCount,
      },
    );
  }

  Future<void> logAddToCart({
    required String productId,
    required String slug,
    required double price,
    required bool success,
  }) async {
    await _analytics.logAddToCart(
      currency: 'INR',
      value: price,
      items: <AnalyticsEventItem>[
        AnalyticsEventItem(
          itemId: productId,
          itemName: slug,
          price: price,
        ),
      ],
    );
    await _analytics.logEvent(
      name: 'add_to_cart_result',
      parameters: <String, Object>{
        'product_id': productId,
        'slug': slug,
        'success': success,
      },
    );
  }
}
