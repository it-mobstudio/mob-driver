import 'package:get_it/get_it.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';

import 'package:m_o_b_demand_side/features/address/data/datasources/address_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/address/data/repositories/address_repository_impl.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';

// Auth
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';

// Cart
import 'package:m_o_b_demand_side/features/cart/data/datasources/cart_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:m_o_b_demand_side/features/cart/domain/repositories/cart_repository.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';

// Home
import 'package:m_o_b_demand_side/features/home/data/datasources/home_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/home/data/repositories/home_repository_impl.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';
import 'package:m_o_b_demand_side/features/home/presentation/bloc/home_bloc.dart';

// Product
import 'package:m_o_b_demand_side/features/product/data/datasources/product_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/product/data/repositories/product_repository_impl.dart';
import 'package:m_o_b_demand_side/features/product/domain/repositories/product_repository.dart';
import 'package:m_o_b_demand_side/features/product/presentation/bloc/product_bloc.dart';

// Orders
import 'package:m_o_b_demand_side/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:m_o_b_demand_side/features/orders/domain/repositories/orders_repository.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/bloc/orders_bloc.dart';

// Checkout
import 'package:m_o_b_demand_side/features/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';

// Profile
import 'package:m_o_b_demand_side/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:m_o_b_demand_side/features/profile/domain/repositories/profile_repository.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';

// RFQ
import 'package:m_o_b_demand_side/features/rfq/data/datasources/rfq_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/rfq/data/repositories/rfq_repository_impl.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';
import 'package:m_o_b_demand_side/features/rfq/presentation/bloc/rfq_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // ── 1. Network ───────────────────────────────────────────────────────────
  DioClient.instance.initialize(baseUrl: AppConfig.apiBaseUrl);
  final dio = DioClient.instance.dio;

  // ── 2. Datasources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<AddressRemoteDatasource>(
    () => AddressRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<CartRemoteDatasource>(
    () => CartRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<HomeRemoteDatasource>(
    () => HomeRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<ProductRemoteDatasource>(
    () => ProductRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<OrdersRemoteDatasource>(
    () => OrdersRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<CheckoutRemoteDatasource>(
    () => CheckoutRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<ProfileRemoteDatasource>(
    () => ProfileRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<RfqRemoteDatasource>(
    () => RfqRemoteDatasourceImpl(dio),
  );

  // ── 3. Repositories ──────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<RfqRepository>(
    () => RfqRepositoryImpl(sl()),
  );

  // ── 4. BLoCs ─────────────────────────────────────────────────────────────

  // Singletons — persist across navigation (cart badge, home data)
  sl.registerLazySingleton<CartBloc>(() => CartBloc(sl()));
  sl.registerLazySingleton<HomeBloc>(() => HomeBloc(sl()));

  // Factories — fresh state per screen visit
  sl.registerFactory<AddressBloc>(() => AddressBloc(sl()));
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<ProductBloc>(() => ProductBloc(sl()));
  sl.registerFactory<OrdersBloc>(() => OrdersBloc(sl()));
  sl.registerFactory<CheckoutBloc>(() => CheckoutBloc(sl()));
  sl.registerFactory<ProfileBloc>(() => ProfileBloc(sl()));
  sl.registerFactory<RfqBloc>(() => RfqBloc(sl()));
}
