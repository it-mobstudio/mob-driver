import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';

sealed class AddressEvent {}

final class AddressLoadRequested extends AddressEvent {}

final class AddressSearchRequested extends AddressEvent {
  AddressSearchRequested(this.query);
  final String query;
}

final class AddressPlaceSelected extends AddressEvent {
  AddressPlaceSelected(this.placeId);
  final String placeId;
}

final class AddressSaveRequested extends AddressEvent {
  AddressSaveRequested(this.address);
  final AddressEntity address;
}

final class AddressMessageCleared extends AddressEvent {}

class AddressState {
  const AddressState({
    this.addresses = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isSaving = false,
    this.selectedPlace,
    this.error,
    this.savedAddress,
  });

  final List<AddressEntity> addresses;
  final List<LocationSuggestion> suggestions;
  final bool isLoading;
  final bool isSearching;
  final bool isSaving;
  final PlaceDetails? selectedPlace;
  final String? error;
  final AddressEntity? savedAddress;

  AddressState copyWith({
    List<AddressEntity>? addresses,
    List<LocationSuggestion>? suggestions,
    bool? isLoading,
    bool? isSearching,
    bool? isSaving,
    PlaceDetails? selectedPlace,
    String? error,
    AddressEntity? savedAddress,
    bool clearSelectedPlace = false,
    bool clearError = false,
    bool clearSavedAddress = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isSaving: isSaving ?? this.isSaving,
      selectedPlace: clearSelectedPlace ? null : (selectedPlace ?? this.selectedPlace),
      error: clearError ? null : (error ?? this.error),
      savedAddress: clearSavedAddress ? null : (savedAddress ?? this.savedAddress),
    );
  }
}

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc(this._repository) : super(const AddressState()) {
    on<AddressLoadRequested>(_onLoad);
    on<AddressSearchRequested>(
      _onSearch,
      transformer: _restartableDebounce(const Duration(milliseconds: 350)),
    );
    on<AddressPlaceSelected>(_onPlaceSelected);
    on<AddressSaveRequested>(_onSave);
    on<AddressMessageCleared>(_onClearMessage);
  }

  final AddressRepository _repository;

  Future<void> _onLoad(
    AddressLoadRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final (addresses, failure) = await _repository.getAddresses();
    emit(state.copyWith(
      addresses: addresses ?? state.addresses,
      isLoading: false,
      error: failure?.message,
    ));
  }

  Future<void> _onSearch(
    AddressSearchRequested event,
    Emitter<AddressState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 3) {
      emit(state.copyWith(
        suggestions: const [],
        isSearching: false,
        clearError: true,
      ));
      return;
    }
    emit(state.copyWith(isSearching: true, clearError: true));
    final (suggestions, failure) = await _repository.searchLocations(query);
    emit(state.copyWith(
      suggestions: suggestions ?? const [],
      isSearching: false,
      error: failure?.message,
    ));
  }

  Future<void> _onPlaceSelected(
    AddressPlaceSelected event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isSearching: true, clearError: true));
    final (place, failure) = await _repository.getPlaceDetails(event.placeId);
    emit(state.copyWith(
      selectedPlace: place,
      suggestions: const [],
      isSearching: false,
      error: failure?.message,
    ));
  }

  Future<void> _onSave(
    AddressSaveRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSavedAddress: true));
    final (address, failure) = await _repository.createAddress(event.address);
    if (failure != null) {
      emit(state.copyWith(isSaving: false, error: failure.message));
      return;
    }
    emit(state.copyWith(
      isSaving: false,
      savedAddress: address,
      addresses: [address!, ...state.addresses],
    ));
  }

  void _onClearMessage(
    AddressMessageCleared event,
    Emitter<AddressState> emit,
  ) {
    emit(state.copyWith(clearError: true, clearSavedAddress: true));
  }
}

EventTransformer<T> _restartableDebounce<T>(Duration duration) {
  return (events, mapper) {
    late StreamController<T> controller;
    Timer? timer;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>(
      onListen: () {
        subscription = events.listen(
          (event) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(event));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        return subscription?.cancel();
      },
    );
    return controller.stream.asyncExpand(mapper);
  };
}
