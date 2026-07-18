import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class HomeEvent {}

final class HomeLoadRequested extends HomeEvent {}

final class HomeRefreshRequested extends HomeEvent {}

// ── States ───────────────────────────────────────────────────────────────────

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  HomeLoaded(this.data);
  final HomeEntity data;
}

final class HomeError extends HomeState {
  HomeError(this.message);
  final String message;
}

// ── BLoC (singleton) ─────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
  }

  final HomeRepository _repository;
  bool _refreshInFlight = false;

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) return; // already loaded, no re-fetch
    emit(HomeLoading());
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    try {
      final previousData =
          state is HomeLoaded ? (state as HomeLoaded).data : null;
      if (previousData == null) emit(HomeLoading());

      final (data, failure) = await _repository.getHomeData();
      if (failure != null) {
        AppHaptics.error();
        emit(
          previousData == null
              ? HomeError(failure.message)
              : HomeLoaded(previousData),
        );
        return;
      }
      emit(HomeLoaded(data!));
    } finally {
      _refreshInFlight = false;
    }
  }

  Future<void> _fetch(Emitter<HomeState> emit) async {
    final (data, failure) = await _repository.getHomeData();
    if (failure != null) {
      AppHaptics.error();
      emit(HomeError(failure.message));
    } else {
      emit(HomeLoaded(data!));
    }
  }
}
