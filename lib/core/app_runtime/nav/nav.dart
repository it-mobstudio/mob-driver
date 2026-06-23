import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/map_location_widget.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/splash_screen.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/pages/cart_page.dart';
import 'package:m_o_b_demand_side/features/categories/presentation/pages/categories_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_address_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_payment_page.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
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
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/magic_ai_quote_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_details_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_form_page.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/pages/rfq_success_page.dart';
import 'package:m_o_b_demand_side/index.dart';
import 'package:m_o_b_demand_side/shared/scaffold_with_nav_bar.dart';
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

final _authRoutePaths = {
  '/',
  LoginpageWidget.routePath,
  OTPVerificationWidget.routePath,
  SignupWidget.routePath,
};

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      observers: <NavigatorObserver>[AnalyticsService.instance.observer],
      redirect: (context, state) {
        if (appStateNotifier.showSplashImage) return null;
        if (!AuthSession.instance.isAuthenticated) return null;
        final loc = state.matchedLocation;
        if (AuthSession.instance.needsRegistration) {
          return loc == SignupWidget.routePath ? null : SignupWidget.routePath;
        }
        return _authRoutePaths.contains(loc) ? HomepageWidget.routePath : null;
      },
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
              : const LoginpageWidget(),
        ),
        GoRoute(
          name: LoginpageWidget.routeName,
          path: LoginpageWidget.routePath,
          builder: (context, state) => const LoginpageWidget(),
        ),
        GoRoute(
          name: OTPVerificationWidget.routeName,
          path: OTPVerificationWidget.routePath,
          builder: (context, state) {
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
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final extra = state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : <String, dynamic>{};
            return AddressSelectionWidget(
              returnToHome: extra['returnToHome'] == true,
              showReferralBonus: extra['showReferralBonus'] == true,
            );
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              ScaffoldWithNavBar(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                name: HomepageWidget.routeName,
                path: HomepageWidget.routePath,
                builder: (context, state) {
                  final extra = state.extra is Map<String, dynamic>
                      ? state.extra as Map<String, dynamic>
                      : <String, dynamic>{};
                  return HomepageWidget(
                    showReferralBonus: extra['showReferralBonus'] == true,
                  );
                },
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                name: CategoriesPage.routeName,
                path: CategoriesPage.routePath,
                builder: (context, state) => const CategoriesPage(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                name: OrdersPage.routeName,
                path: OrdersPage.routePath,
                builder: (context, state) => const OrdersPage(),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                name: CreditPage.routeName,
                path: CreditPage.routePath,
                builder: (context, state) => const CreditPage(),
              ),
            ]),
          ],
        ),
        GoRoute(
          name: ProductListingPage.routeName,
          path: ProductListingPage.routePath,
          parentNavigatorKey: appNavigatorKey,
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
            final subCategorySlug = extra['subCategorySlug']?.toString() ??
                state.uri.queryParameters['sub_category'];
            final subCategoryName = extra['subCategoryName']?.toString();
            return ProductListingPage(
              category: category,
              slug: slug,
              initialSubCategorySlug: subCategorySlug,
              initialSubCategoryName: subCategoryName,
            );
          },
        ),
        GoRoute(
          name: ProductDetailPage.routeName,
          path: '${ProductDetailPage.routePath}/:slug',
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: 'CategoryWebAlias',
          path: '/home/:slug',
          parentNavigatorKey: appNavigatorKey,
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
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: 'ProductDetailWebAlias',
          path: '/products/:slug',
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => ProductDetailPage(
            slug: state.pathParameters['slug'] ?? '',
          ),
        ),
        GoRoute(
          name: BrandProductSearchPage.routeName,
          path: '${BrandProductSearchPage.routePath}/:slug',
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : <String, dynamic>{};
            final slug = state.pathParameters['slug'] ?? '';
            final brandName = extra['brandName']?.toString() ??
                state.uri.queryParameters['brand'];
            final searchTerm = extra['searchTerm']?.toString() ??
                brandName ??
                state.uri.queryParameters['search'] ??
                _labelFromSlug(slug);
            return BrandProductSearchPage(
              searchTerm: searchTerm,
              brandName: brandName,
            );
          },
        ),
        GoRoute(
          name: SearchPage.routeName,
          path: SearchPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          name: CartPage.routeName,
          path: CartPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const CartPage(),
        ),
        GoRoute(
          name: CheckoutAddressPage.routeName,
          path: CheckoutAddressPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const CheckoutAddressPage(),
        ),
        GoRoute(
          name: CheckoutOrderReviewPage.routeName,
          path: CheckoutOrderReviewPage.routePath,
          parentNavigatorKey: appNavigatorKey,
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
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const CheckoutPaymentPage(),
        ),
        GoRoute(
          name: OrderPlacedPage.routeName,
          path: OrderPlacedPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is PlacedOrderEntity) {
              return OrderPlacedPage(order: extra);
            }
            return OrderPlacedPage(
              orderId: extra as String? ??
                  state.uri.queryParameters['order_id'] ??
                  '',
            );
          },
        ),
        GoRoute(
          name: 'OrderPlacedDeepLinkAlias',
          path: '/success',
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => OrderPlacedPage(
            orderId: state.uri.queryParameters['order_id'] ?? '',
          ),
        ),
        GoRoute(
          name: PaymentFailedPage.routeName,
          path: PaymentFailedPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) =>
              PaymentFailedPage(message: state.extra as String? ?? ''),
        ),
        GoRoute(
          name: MapLocationWidget.routeName,
          path: MapLocationWidget.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => MapLocationWidget(
            initialLocation: state.extra is AddressLocationEntity
                ? state.extra as AddressLocationEntity
                : null,
          ),
        ),
        GoRoute(
          name: MagicAiQuotePage.routeName,
          path: MagicAiQuotePage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const MagicAiQuotePage(),
        ),
        GoRoute(
          name: RfqFormPage.routeName,
          path: RfqFormPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const RfqFormPage(),
        ),
        GoRoute(
          name: RfqSuccessPage.routeName,
          path: RfqSuccessPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const RfqSuccessPage(),
        ),
        GoRoute(
          name: RfqPage.routeName,
          path: RfqPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const RfqPage(),
        ),
        GoRoute(
          name: RfqDetailsPage.routeName,
          path: RfqDetailsPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => RfqDetailsPage(
            rfqId: state.extra?.toString() ??
                state.uri.queryParameters['id'] ??
                '',
          ),
        ),
        GoRoute(
          name: MyAccountWidget.routeName,
          path: MyAccountWidget.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const MyAccountWidget(),
        ),
        GoRoute(
          name: PersonalInfoPage.routeName,
          path: PersonalInfoPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const PersonalInfoPage(),
        ),
        GoRoute(
          name: ReferralPage.routeName,
          path: ReferralPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const ReferralPage(),
        ),
        GoRoute(
          name: ReferralHistoryPage.routeName,
          path: ReferralHistoryPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const ReferralHistoryPage(),
        ),
        GoRoute(
          name: WalletPointsPage.routeName,
          path: WalletPointsPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const WalletPointsPage(),
        ),
        GoRoute(
          name: MobstarPage.routeName,
          path: MobstarPage.routePath,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const MobstarPage(),
        ),
        GoRoute(
          name: OrderDetailPage.routeName,
          path: OrderDetailPage.routePath,
          parentNavigatorKey: appNavigatorKey,
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
