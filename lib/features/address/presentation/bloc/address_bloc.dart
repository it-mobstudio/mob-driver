import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/domain/repositories/address_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

sealed class AddressEvent {}

final class AddressLoadRequested extends AddressEvent {}

// ── States ────────────────────────────────────────────────────────────────────

sealed class AddressState {}

final class AddressInitial extends AddressState {}

final class AddressLoading extends AddressState {}

final class AddressLoaded extends AddressState {
  AddressLoaded(this.addresses);
  final List<UserAddressEntity> addresses;
}

final class AddressError extends AddressState {
  AddressError(this.message);
  final String message;
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc(this._repository) : super(AddressInitial()) {
    on<AddressLoadRequested>(_onLoad);
  }

  final AddressRepository _repository;

  Future<void> _onLoad(
    AddressLoadRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading());
    final (addresses, failure) = await _repository.getAddresses();
    if (failure != null) {
      emit(AddressError(failure.message));
    } else {
      emit(AddressLoaded(addresses!));
    }
  }
}
