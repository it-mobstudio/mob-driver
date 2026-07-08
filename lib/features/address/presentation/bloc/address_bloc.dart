import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';

sealed class AddressEvent {}

final class AddressLoadRequested extends AddressEvent {}

final class AddressSearchRequested extends AddressEvent {
  AddressSearchRequested(this.query);
  final String query;
}

final class AddressLocationDetailsRequested extends AddressEvent {
  AddressLocationDetailsRequested(this.placeId);
  final String placeId;
}

final class AddressSaveRequested extends AddressEvent {
  AddressSaveRequested(this.address);
  final AddressEntity address;
}

sealed class AddressState {}

final class AddressInitial extends AddressState {}

final class AddressLoading extends AddressState {}

final class AddressListLoaded extends AddressState {
  AddressListLoaded(this.addresses);
  final List<AddressEntity> addresses;
}

final class AddressSearching extends AddressState {}

final class AddressSearchLoaded extends AddressState {
  AddressSearchLoaded(this.suggestions);
  final List<AddressSuggestionEntity> suggestions;
}

final class AddressLocationResolved extends AddressState {
  AddressLocationResolved(this.location);
  final AddressLocationEntity location;
}

final class AddressSaving extends AddressState {}

final class AddressSaved extends AddressState {
  AddressSaved(this.address);
  final AddressEntity address;
}

final class AddressError extends AddressState {
  AddressError(this.message);
  final String message;
}

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc(this._repository) : super(AddressInitial()) {
    on<AddressLoadRequested>(_onLoad);
    on<AddressSearchRequested>(_onSearch);
    on<AddressLocationDetailsRequested>(_onResolve);
    on<AddressSaveRequested>(_onSave);
  }

  final AddressRepository _repository;

  Future<void> _onLoad(
    AddressLoadRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final (addresses, failure) = await _repository.getAddresses();
    if (failure != null) {
      AppHaptics.error();
      emit(AddressError(failure.message));
    } else {
      emit(AddressListLoaded(addresses ?? const []));
    }
  }

  Future<void> _onSearch(
    AddressSearchRequested event,
    Emitter<AddressState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 3) {
      emit(AddressSearchLoaded(const []));
      return;
    }
    emit(AddressSearching());
    final (suggestions, failure) = await _repository.searchLocations(query);
    if (failure != null) {
      AppHaptics.error();
      emit(AddressError(failure.message));
    } else {
      emit(AddressSearchLoaded(suggestions ?? const []));
    }
  }

  Future<void> _onResolve(
    AddressLocationDetailsRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final (location, failure) =
        await _repository.getLocationDetails(event.placeId);
    if (failure != null) {
      AppHaptics.error();
      emit(AddressError(failure.message));
    } else {
      emit(AddressLocationResolved(location!));
    }
  }

  Future<void> _onSave(
    AddressSaveRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressSaving());
    // A non-empty id means this address already exists — editing it must
    // PATCH the existing record, not silently create a duplicate.
    final (address, failure) = event.address.id.trim().isNotEmpty
        ? await _repository.updateAddress(event.address)
        : await _repository.createAddress(event.address);
    if (failure != null) {
      AppHaptics.error();
      emit(AddressError(failure.message));
    } else {
      emit(AddressSaved(address!));
    }
  }
}
