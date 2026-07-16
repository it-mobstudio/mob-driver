import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/backend/analytics/analytics_service.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/add_address_detail_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/confirm_delivery_location_page.dart';
import 'package:m_o_b_demand_side/features/address/presentation/pages/location_search_page.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/pages/splash_screen.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/pages/cart_page.dart';
import 'package:m_o_b_demand_side/features/categories/presentation/pages/categories_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/credit_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_dashboard_page.dart';
import 'package:m_o_b_demand_side/features/credit/presentation/pages/mob_credit_profile_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_address_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_order_review_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/checkout_payment_page.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/order_placed_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/payment_failed_page.dart';
import 'package:m_o_b_demand_side/core/app_runtime/nav/route_extra_cache.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/orders_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/brand_product_search_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_detail_page.dart';
import 'package:m_o_b_demand_side/features/product/presentation/pages/product_listing_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/account_privacy_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_account.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/my_projects_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/personal_info_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_history_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/referral_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/upgrade_to_pro_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/wallet_points_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/dev_info_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_page.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/pages/mobstar_points_page.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_page.dart';
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

String _labelFromSlug(String slug) {
  return slug
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

/// Combined notifier that listens to both app state and auth changes
class _CombinedStateNotifier extends ChangeNotifier {
  _CombinedStateNotifier(
    AppStateNotifier appNotifier,
    AuthSession authSession,
  )   : _appNotifier = appNotifier,
        _authSession = authSession {
    _appNotifier.addListener(_onStateChanged);
    _authSession.addListener(_onStateChanged);
  }

  final AppStateNotifier _appNotifier;
  final AuthSession _authSession;

  void _onStateChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _appNotifier.removeListener(_onStateChanged);
    _authSession.removeListener(_onStateChanged);
    super.dispose();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) {
  final combinedNotifier = _CombinedStateNotifier(
    appStateNotifier,
    AuthSession.instance,
  );

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: combinedNotifier,
    navigatorKey: appNavigatorKey,
    observers: <NavigatorObserver>[AnalyticsService.instance.observer],
    redirect: (context, state) {
      if (appStateNotifier.showSplashImage) return null;
      final loc = state.matchedLocation;
      final isAuthRoute = _authRoutePaths.contains(loc);
      if (!AuthSession.instance.isAuthenticated) {
        return isAuthRoute ? null : LoginpageWidget.routePath;
      }
      if (AuthSession.instance.needsRegistration) {
        return loc == SignupWidget.routePath ? null : SignupWidget.routePath;
      }
      // Existing/logged-in users should not remain on splash, login, or OTP.
      // The signup page is allowed here so the registration success listener can
      // finish its address-selection navigation without a router race.
      if (loc == SignupWidget.routePath) return null;
      return isAuthRoute ? HomepageWidget.routePath : null;
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
            showSearch: extra['showSearch'] != false,
            selectable: extra['selectable'] != false,
            title: extra['title']?.toString(),
          );
        },
      ),
      GoRoute(
        name: LocationSearchPage.routeName,
        path: LocationSearchPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const LocationSearchPage(),
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
              name: 'OrdersTab',
              path: '/orders-tab',
              builder: (context, state) => const OrdersPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: CreditPage.routeName,
              path: CreditPage.routePath,
              builder: (context, state) => const CreditTabPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              name: 'MoreMenuTab',
              path: '/more',
              builder: (context, state) => const MyAccountWidget(),
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
            orderId:
                extra as String? ?? state.uri.queryParameters['order_id'] ?? '',
            paymentGateway: state.uri.queryParameters['payment_Gateway'],
            merchantPaymentRefId:
                state.uri.queryParameters['merchantPaymentRefId'],
            paymentId: state.uri.queryParameters['paymentId'],
            transactionId: state.uri.queryParameters['transactionId'],
            currency: state.uri.queryParameters['currency'],
          );
        },
      ),
      GoRoute(
        name: 'OrderPlacedDeepLinkAlias',
        path: '/success',
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => OrderPlacedPage(
          orderId: state.uri.queryParameters['order_id'] ?? '',
          paymentGateway: state.uri.queryParameters['payment_Gateway'],
          merchantPaymentRefId:
              state.uri.queryParameters['merchantPaymentRefId'],
          paymentId: state.uri.queryParameters['paymentId'],
          transactionId: state.uri.queryParameters['transactionId'],
          currency: state.uri.queryParameters['currency'],
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
        name: AddAddressDetailPage.routeName,
        path: AddAddressDetailPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        // Deliberately no `redirect` here — this router has a
        // refreshListenable (AuthSession/AppStateNotifier), and GoRouter
        // re-runs every active route's `redirect`/`builder` on any refresh,
        // using a freshly re-derived GoRouterState whose `extra` is NOT
        // guaranteed to still be the object originally passed at push-time.
        // That previously kicked the user back to the address list (or, via
        // `builder` alone, silently swapped this page for the address list
        // mid-flow) any time an unrelated auth/app-state notification fired
        // while this route was on screen — e.g. right after a fresh
        // registration, while other post-signup syncs are still settling.
        // RouteExtraCache (same pattern already used for OrderTrackingPage)
        // remembers the last real `extra` for this path so a refresh with a
        // missing/wrong-typed `extra` recovers it instead of losing the flow.
        builder: (context, state) {
          final rawExtra = state.extra;
          if (rawExtra is AddressEntity) {
            RouteExtraCache.put(AddAddressDetailPage.routePath, rawExtra);
          }
          final extra = rawExtra is AddressEntity
              ? rawExtra
              : RouteExtraCache.take<AddressEntity>(
                  AddAddressDetailPage.routePath);
          if (extra == null) return const AddressSelectionWidget();
          // A non-empty id means this is an existing saved address being
          // edited (its own details are both the location and the form's
          // starting values), not a freshly-confirmed pin with nothing
          // saved yet.
          return AddAddressDetailPage(
            location: extra,
            existingAddress: extra.id.trim().isNotEmpty ? extra : null,
          );
        },
      ),
      GoRoute(
        name: ConfirmDeliveryLocationPage.routeName,
        path: ConfirmDeliveryLocationPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        // Same reasoning as AddAddressDetailPage above — no `redirect`, and
        // RouteExtraCache guards against a refresh-triggered rebuild losing
        // this route's `extra` mid-flow.
        builder: (context, state) {
          final rawExtra = state.extra;
          if (rawExtra is AddressLocationEntity) {
            RouteExtraCache.put(
                ConfirmDeliveryLocationPage.routePath, rawExtra);
          }
          final extra = rawExtra is AddressLocationEntity
              ? rawExtra
              : RouteExtraCache.take<AddressLocationEntity>(
                  ConfirmDeliveryLocationPage.routePath);
          if (extra == null) return const AddressSelectionWidget();
          return ConfirmDeliveryLocationPage(initialLocation: extra);
        },
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
          rfqId:
              state.extra?.toString() ?? state.uri.queryParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        name: MyAccountWidget.routeName,
        path: MyAccountWidget.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const MyAccountWidget(),
      ),
      GoRoute(
        name: AccountPrivacyPage.routeName,
        path: AccountPrivacyPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const AccountPrivacyPage(),
      ),
      GoRoute(
        name: OrdersPage.routeName,
        path: OrdersPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        name: MyProjectsPage.routeName,
        path: MyProjectsPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const MyProjectsPage(),
      ),
      GoRoute(
        name: UpgradeToProPage.routeName,
        path: UpgradeToProPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const UpgradeToProPage(),
      ),
      GoRoute(
        name: MobCreditProfilePage.routeName,
        path: MobCreditProfilePage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return CreditPage(showBackButton: extra['showBackButton'] == true);
        },
      ),
      GoRoute(
        name: MobCreditDashboardPage.routeName,
        path: MobCreditDashboardPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const MobCreditDashboardPage(),
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
        name: DevInfoPage.routeName,
        path: DevInfoPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const DevInfoPage(),
      ),
      GoRoute(
        name: MobstarPage.routeName,
        path: MobstarPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const MobstarPage(),
      ),
      GoRoute(
        name: MobstarPointsPage.routeName,
        path: MobstarPointsPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const MobstarPointsPage(),
      ),
      GoRoute(
        name: OrderDetailPage.routeName,
        path: OrderDetailPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) => const OrderDetailPage(),
      ),
      GoRoute(
        name: OrderTrackingPage.routeName,
        path: OrderTrackingPage.routePath,
        parentNavigatorKey: appNavigatorKey,
        builder: (context, state) {
          // Browser back/forward on web replays the URL only, not the
          // `extra` payload — fall back to whatever was last pushed here
          // this session instead of rendering blank. See RouteExtraCache.
          final rawExtra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          if (rawExtra != null) {
            RouteExtraCache.put(OrderTrackingPage.routePath, rawExtra);
          }
          final extra = rawExtra ??
              RouteExtraCache.take<Map<String, dynamic>>(
                  OrderTrackingPage.routePath) ??
              <String, dynamic>{};
          return OrderTrackingPage(
            order: extra['order'] is OrderEntity
                ? extra['order'] as OrderEntity
                : null,
            shipment: extra['shipment'] is OrderShipmentEntity
                ? extra['shipment'] as OrderShipmentEntity
                : null,
            autoOpenRating: extra['autoOpenRating'] == true,
          );
        },
      ),
    ],
  );
}

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
