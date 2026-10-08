import 'package:get_it/get_it.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/network/dio_client.dart';

// Auth
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';
import 'package:m_o_b_demand_side/features/auth/presentation/bloc/auth_bloc.dart';

// Driver
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/driver/data/local/driver_snapshot_cache.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/data/realtime/driver_realtime.dart';
import 'package:m_o_b_demand_side/features/driver/data/repositories/driver_repository_impl.dart';
import 'package:m_o_b_demand_side/features/driver/domain/repositories/driver_repository.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';

final GetIt sl = GetIt.instance;

/// Only what the driver app's screens use. The shopping features still in
/// this codebase (cart, catalogue, checkout, credit, quotes…) are reachable
/// from no route, so they're deliberately not registered: with nothing
/// referencing them, the release compiler drops their code from the app —
/// a smaller install and less memory on low-end phones.
Future<void> setupDependencies() async {
  // ── 1. Network ───────────────────────────────────────────────────────────
  DioClient.instance.initialize(baseUrl: AppConfig.apiBaseUrl);
  final dio = DioClient.instance.dio;

  // ── 2. Datasources ───────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(dio),
  );
  sl.registerLazySingleton<DriverRemoteDatasource>(
    () => DriverRemoteDatasource(dio),
  );

  // ── 3. Repositories & services ───────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(
      sl(),
      cache: DriverSnapshotCache(
        currentDriverId: () => AuthSession.instance.userDetails?['id']?.toString(),
      ),
    ),
  );
  sl.registerLazySingleton<DriverLocationService>(
    () => const GeolocatorLocationService(),
  );
  // The live connection that replaces polling (see DriverRealtime).
  sl.registerLazySingleton<DriverRealtime>(
    () => DriverRealtime(
      url: AppConfig.realtimeUrl,
      accessToken: () => AuthSession.instance.accessToken,
      refreshToken: AuthSession.instance.refreshAccessToken,
    ),
  );

  // ── 4. BLoCs ─────────────────────────────────────────────────────────────

  // The driver's on-duty session (location, trip pushes) has to outlive any
  // one screen, so it's a singleton provided at the app root.
  sl.registerLazySingleton<DriverSessionCubit>(
    () => DriverSessionCubit(repository: sl(), location: sl(), realtime: sl()),
  );

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
}
