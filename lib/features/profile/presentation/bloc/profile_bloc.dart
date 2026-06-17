import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/domain/repositories/profile_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class ProfileEvent {}

final class ProfileLoadRequested extends ProfileEvent {}

final class ProfileUpdateRequested extends ProfileEvent {
  ProfileUpdateRequested(this.data);
  final Map<String, dynamic> data;
}

final class ReferralSummaryLoadRequested extends ProfileEvent {}

// ── States ───────────────────────────────────────────────────────────────────

sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  ProfileLoaded(this.profile);
  final ProfileEntity profile;
}

final class ProfileUpdated extends ProfileState {
  ProfileUpdated(this.profile);
  final ProfileEntity profile;
}

final class ProfileError extends ProfileState {
  ProfileError(this.message);
  final String message;
}

final class ReferralSummaryLoaded extends ProfileState {
  ReferralSummaryLoaded(this.summary);
  final ReferralSummaryEntity summary;
}

final class ReferralSummaryError extends ProfileState {
  ReferralSummaryError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ReferralSummaryLoadRequested>(_onLoadReferralSummary);
  }

  final ProfileRepository _repository;

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final (profile, failure) = await _repository.getProfile();
    if (failure != null) {
      emit(ProfileError(failure.message));
    } else {
      emit(ProfileLoaded(profile!));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final (success, failure) = await _repository.updateProfile(event.data);
    if (failure != null) {
      emit(ProfileError(failure.message));
    } else if (success) {
      // Reload profile after successful update
      add(ProfileLoadRequested());
    } else {
      emit(ProfileError('Update failed.'));
    }
  }

  Future<void> _onLoadReferralSummary(
    ReferralSummaryLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final (summary, failure) = await _repository.getReferralSummary();
    if (failure != null) {
      emit(ReferralSummaryError(failure.message));
    } else {
      emit(ReferralSummaryLoaded(summary!));
    }
  }
}
