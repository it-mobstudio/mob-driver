import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';
import 'package:m_o_b_demand_side/features/home/domain/repositories/home_repository.dart';

// MOB currently operates in the Mumbai and Bengaluru metro areas. Browsing
// is gated at this city level only (accepting common alternate spellings
// and the surrounding metro-region city names) — the precise pincode-level
// delivery restriction is enforced later, at checkout
// (checkout_address_page.dart's _checkPincode), so someone in an operating
// city but a not-yet-serviceable pincode can still browse/shop and only
// gets blocked once they try to actually check out.
const _mumbaiCityAliases = {
  'mumbai',
  'bombay',
  'navi mumbai',
  'thane',
  'greater mumbai',
};

const _bengaluruCityAliases = {
  'bengaluru',
  'bangalore',
};

bool _isOperatingCity(String city) {
  final normalized = city.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return _mumbaiCityAliases.contains(normalized) ||
      _bengaluruCityAliases.contains(normalized);
}

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

// The selected delivery address's city is outside every operating metro
// area — the catalog never gets fetched for this case (nothing to show).
final class HomeNotServiceable extends HomeState {}

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
    if (!await _isSelectedCityInOperatingArea()) {
      emit(HomeNotServiceable());
      return;
    }
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;

    try {
      if (!await _isSelectedCityInOperatingArea()) {
        emit(HomeNotServiceable());
        return;
      }

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

  // No address selected yet means nothing to gate on — an address gate
  // elsewhere already handles the "no address at all" case.
  Future<bool> _isSelectedCityInOperatingArea() async {
    final city = (await SelectedAddressStore.read())?.city.trim() ?? '';
    if (city.isEmpty) return true;
    return _isOperatingCity(city);
  }
}
