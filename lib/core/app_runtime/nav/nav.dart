import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/map_location_widget.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/splash_screen.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/pages/cart_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_address_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_payment_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/order_placed_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/payment_failed_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/brand_product_search_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_listing_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/personal_info_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_history_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/magic_ai_quote_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_details_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_form_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_success_page.dart';
import 'package:m_o_b_demand_side/index.dart';
import 'package:m_o_b_demand_side/shared/top_search_page.dart';

export 'package:go_router/go_router.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = false;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      observers: <NavigatorObserver>[AnalyticsService.instance.observer],
      errorBuilder: (context, state) => appStateNotifier.showSplashImage
          ? const SplashScreen()
          : (AuthSession.instance.isAuthenticated
              ? const HomepageWidget()
              : const LoginpageWidget()),
      routes: [
        GoRoute(
          name: '_initialize',
          path: '/',
          builder: (context, state) => appStateNotifier.showSplashImage
              ? const SplashScreen()
              : (AuthSession.instance.isAuthenticated
                  ? const HomepageWidget()
                  : const LoginpageWidget()),
        ),
        GoRoute(
          name: LoginpageWidget.routeName,
          path: LoginpageWidget.routePath,
          builder: (context, state) => AuthSession.instance.isAuthenticated
              ? const HomepageWidget()
              : const LoginpageWidget(),
        ),
        GoRoute(
          name: OTPVerificationWidget.routeName,
          path: OTPVerificationWidget.routePath,
          builder: (context, state) {
            if (AuthSession.instance.isAuthenticated) {
              return const HomepageWidget();
            }
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return OTPVerificationWidget(
              phoneNumber: extra['phoneNumber']?.toString() ?? '',
            );
          },
        ),
        GoRoute(
          name: SignupWidget.routeName,
          path: SignupWidget.routePath,
          builder: (context, state) {
            if (AuthSession.instance.isAuthenticated) {
              return const HomepageWidget();
            }
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return SignupWidget(
              phoneNumber: extra['phoneNumber']?.toString() ?? '',
            );
          },
        ),
        GoRoute(
          name: AddressSelectionWidget.routeName,
          path: AddressSelectionWidget.routePath,
          builder: (context, state) => const AddressSelectionWidget(),
        ),
        GoRoute(
          name: HomepageWidget.routeName,
          path: HomepageWidget.routePath,
          builder: (context, state) => const HomepageWidget(),
        ),
        GoRoute(
          name: ProductListingPage.routeName,
          path: ProductListingPage.routePath,
          builder: (context, state) {
            final extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : <String, dynamic>{};
            final category = extra['category']?.toString() ??
                state.uri.queryParameters['category'] ??
                '';
            final slug = extra['slug']?.toString() ??
                state.uri.queryParameters['slug'] ??
                '';
            return ProductListingPage(category: category, slug: slug);
          },
        ),
        GoRoute(
          name: ProductDetailPage.routeName,
          path: '${ProductDetailPage.routePath}/:slug',
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: 'CategoryWebAlias',
          path: '/home/:slug',
          builder: (context, state) {
            final categorySlug = state.pathParameters['slug'] ?? '';
            return ProductListingPage(
              category: _labelFromSlug(categorySlug),
              slug: categorySlug,
            );
          },
        ),
        GoRoute(
          name: 'ProductDetailHomeWebAlias',
          path: '/home/product-details/:slug',
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: 'ProductDetailWebAlias',
          path: '/products/:slug',
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: BrandProductSearchPage.routeName,
          path: '${BrandProductSearchPage.routePath}/:slug',
          builder: (context, state) {
            final extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : <String, dynamic>{};
            final slug = state.pathParameters['slug'] ?? '';
            final brandName = extra['brandName']?.toString() ??
                state.uri.queryParameters['brand'] ??
                _labelFromSlug(slug);
            return BrandProductSearchPage(
              searchTerm: brandName,
              brandName: brandName,
            );
          },
        ),
        GoRoute(
          name: SearchPage.routeName,
          path: SearchPage.routePath,
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          name: CartPage.routeName,
          path: CartPage.routePath,
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          name: CheckoutAddressPage.routeName,
          path: CheckoutAddressPage.routePath,
          builder: (context, state) => const CheckoutAddressPage(),
        ),
        GoRoute(
          name: CheckoutOrderReviewPage.routeName,
          path: CheckoutOrderReviewPage.routePath,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CheckoutOrderReviewPage(
              cartId: extra['cart_id'] as int? ?? 0,
              deliveryAddressId: extra['delivery_address_id'] as int? ?? 0,
              billingAddressId: extra['billing_address_id'] as int? ?? 0,
            );
          },
        ),
        GoRoute(
          name: CheckoutPaymentPage.routeName,
          path: CheckoutPaymentPage.routePath,
          builder: (context, state) => const CheckoutPaymentPage(),
        ),
        GoRoute(
          name: OrderPlacedPage.routeName,
          path: OrderPlacedPage.routePath,
          builder: (context, state) =>
              OrderPlacedPage(orderId: state.extra as String? ?? ''),
        ),
        GoRoute(
          name: PaymentFailedPage.routeName,
          path: PaymentFailedPage.routePath,
          builder: (context, state) =>
              PaymentFailedPage(message: state.extra as String? ?? ''),
        ),
        GoRoute(
          name: MapLocationWidget.routeName,
          path: MapLocationWidget.routePath,
          builder: (context, state) => MapLocationWidget(
            initialLocation: state.extra is AddressLocationEntity
                ? state.extra as AddressLocationEntity
                : null,
          ),
        ),
        GoRoute(
          name: MagicAiQuotePage.routeName,
          path: MagicAiQuotePage.routePath,
          builder: (context, state) => const MagicAiQuotePage(),
        ),
        GoRoute(
          name: RfqFormPage.routeName,
          path: RfqFormPage.routePath,
          builder: (context, state) => const RfqFormPage(),
        ),
        GoRoute(
          name: RfqSuccessPage.routeName,
          path: RfqSuccessPage.routePath,
          builder: (context, state) => const RfqSuccessPage(),
        ),
        GoRoute(
          name: RfqPage.routeName,
          path: RfqPage.routePath,
          builder: (context, state) => const RfqPage(),
        ),
        GoRoute(
          name: RfqDetailsPage.routeName,
          path: RfqDetailsPage.routePath,
          builder: (context, state) => RfqDetailsPage(
            rfqId: state.extra?.toString() ??
                state.uri.queryParameters['id'] ??
                '',
          ),
        ),
        GoRoute(
          name: MyAccountWidget.routeName,
          path: MyAccountWidget.routePath,
          builder: (context, state) => const MyAccountWidget(),
        ),
        GoRoute(
          name: PersonalInfoPage.routeName,
          path: PersonalInfoPage.routePath,
          builder: (context, state) => const PersonalInfoPage(),
        ),
        GoRoute(
          name: ReferralPage.routeName,
          path: ReferralPage.routePath,
          builder: (context, state) => const ReferralPage(),
        ),
        GoRoute(
          name: ReferralHistoryPage.routeName,
          path: ReferralHistoryPage.routePath,
          builder: (context, state) => const ReferralHistoryPage(),
        ),
        GoRoute(
          name: OrdersPage.routeName,
          path: OrdersPage.routePath,
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          name: OrderDetailPage.routeName,
          path: OrderDetailPage.routePath,
          builder: (context, state) => const OrderDetailPage(),
        ),
      ],
    );

extension NavigationExtensions on BuildContext {
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

String _labelFromSlug(String slug) {
  return slug
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
