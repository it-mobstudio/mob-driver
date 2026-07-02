import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
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

final class WalletHistoryLoadRequested extends ProfileEvent {}

final class MobstarLoadRequested extends ProfileEvent {}

final class ProjectsLoadRequested extends ProfileEvent {
  ProjectsLoadRequested({this.page = 1});
  final int page;
}

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

final class WalletHistoryLoaded extends ProfileState {
  WalletHistoryLoaded(this.wallet);
  final WalletHistoryEntity wallet;
}

final class WalletHistoryError extends ProfileState {
  WalletHistoryError(this.message);
  final String message;
}

final class MobstarLoaded extends ProfileState {
  MobstarLoaded(this.mobstar);
  final MobstarEntity mobstar;
}

final class MobstarError extends ProfileState {
  MobstarError(this.message);
  final String message;
}

final class ProjectsLoaded extends ProfileState {
  ProjectsLoaded(this.projects);
  final ProjectListEntity projects;
}

final class ProjectsError extends ProfileState {
  ProjectsError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ReferralSummaryLoadRequested>(_onLoadReferralSummary);
    on<WalletHistoryLoadRequested>(_onLoadWalletHistory);
    on<MobstarLoadRequested>(_onLoadMobstar);
    on<ProjectsLoadRequested>(_onLoadProjects);
  }

  final ProfileRepository _repository;

  Future<void> _onLoad(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final (profile, failure) = await _repository.getProfile();
    if (failure != null) {
      AppHaptics.error();
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
      AppHaptics.error();
      emit(ProfileError(failure.message));
    } else if (success) {
      // Reload profile after successful update
      add(ProfileLoadRequested());
    } else {
      AppHaptics.error();
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
      AppHaptics.error();
      emit(ReferralSummaryError(failure.message));
    } else {
      emit(ReferralSummaryLoaded(summary!));
    }
  }

  Future<void> _onLoadWalletHistory(
    WalletHistoryLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final (wallet, failure) = await _repository.getWalletHistory();
    if (failure != null) {
      AppHaptics.error();
      emit(WalletHistoryError(failure.message));
    } else {
      emit(WalletHistoryLoaded(wallet!));
    }
  }

  Future<void> _onLoadMobstar(
    MobstarLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final (mobstar, failure) = await _repository.getMobstar();
    if (failure != null) {
      AppHaptics.error();
      emit(MobstarError(failure.message));
    } else {
      emit(MobstarLoaded(mobstar!));
    }
  }

  Future<void> _onLoadProjects(
    ProjectsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final (projects, failure) = await _repository.getProjects(page: event.page);
    if (failure != null) {
      AppHaptics.error();
      emit(ProjectsError(failure.message));
    } else {
      emit(ProjectsLoaded(projects!));
    }
  }
}
