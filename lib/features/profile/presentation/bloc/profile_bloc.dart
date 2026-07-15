import 'dart:typed_data';

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

final class ProjectCreateRequested extends ProfileEvent {
  ProjectCreateRequested({
    required this.projectName,
    required this.city,
    this.siteDeliveryAddressId,
    this.newAddress,
    this.imageBytes,
    this.imageFilename,
  });

  final String projectName;
  final String city;
  final int? siteDeliveryAddressId;
  final Map<String, dynamic>? newAddress;
  final Uint8List? imageBytes;
  final String? imageFilename;
}

final class ProjectUpdateRequested extends ProfileEvent {
  ProjectUpdateRequested({
    required this.projectId,
    required this.projectName,
    required this.city,
    required this.address,
    this.imageBytes,
    this.imageFilename,
  });

  final String projectId;
  final String projectName;
  final String city;
  final Map<String, dynamic> address;
  final Uint8List? imageBytes;
  final String? imageFilename;
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
  ProjectsLoaded(
    this.projects, {
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.loadMoreError,
  });

  final ProjectListEntity projects;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? loadMoreError;
}

final class ProjectsError extends ProfileState {
  ProjectsError(this.message);
  final String message;
}

final class ProjectSaving extends ProfileState {}

final class ProjectSaved extends ProfileState {}

final class ProjectSaveError extends ProfileState {
  ProjectSaveError(this.message);
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
    on<ProjectCreateRequested>(_onCreateProject);
    on<ProjectUpdateRequested>(_onUpdateProject);
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
    final currentState = state;
    final isFirstPage = event.page <= 1;
    final currentProjects =
        currentState is ProjectsLoaded ? currentState.projects : null;

    if (isFirstPage) {
      emit(ProfileLoading());
    } else if (currentState is ProjectsLoaded) {
      if (currentState.isLoadingMore || currentState.hasReachedEnd) return;
      emit(ProjectsLoaded(
        currentState.projects,
        isLoadingMore: true,
        hasReachedEnd: currentState.hasReachedEnd,
      ));
    }

    final (projects, failure) = await _repository.getProjects(page: event.page);
    if (failure != null) {
      AppHaptics.error();
      if (!isFirstPage && currentProjects != null) {
        emit(ProjectsLoaded(
          currentProjects,
          hasReachedEnd: false,
          loadMoreError: failure.message,
        ));
      } else {
        emit(ProjectsError(failure.message));
      }
    } else {
      final fetched = projects!;
      if (isFirstPage || currentProjects == null) {
        emit(ProjectsLoaded(
          fetched,
          hasReachedEnd: _hasReachedProjectsEnd(fetched),
        ));
      } else {
        final merged =
            _mergeProjects(currentProjects.projects, fetched.projects);
        final totalCount = fetched.totalCount > 0
            ? fetched.totalCount
            : currentProjects.totalCount;
        final nextList = fetched.copyWith(
          projects: merged,
          totalCount: totalCount,
        );
        emit(ProjectsLoaded(
          nextList,
          hasReachedEnd: _hasReachedProjectsEnd(nextList),
        ));
      }
    }
  }

  Future<void> _onCreateProject(
    ProjectCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProjectSaving());
    final (success, failure) = await _repository.createProject(
      projectName: event.projectName,
      city: event.city,
      siteDeliveryAddressId: event.siteDeliveryAddressId,
      newAddress: event.newAddress,
      imageBytes: event.imageBytes,
      imageFilename: event.imageFilename,
    );
    if (failure != null || !success) {
      AppHaptics.error();
      emit(ProjectSaveError(failure?.message ?? 'Unable to create project.'));
    } else {
      emit(ProjectSaved());
      add(ProjectsLoadRequested());
    }
  }

  Future<void> _onUpdateProject(
    ProjectUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProjectSaving());
    final (success, failure) = await _repository.updateProject(
      projectId: event.projectId,
      projectName: event.projectName,
      city: event.city,
      address: event.address,
      imageBytes: event.imageBytes,
      imageFilename: event.imageFilename,
    );
    if (failure != null || !success) {
      AppHaptics.error();
      emit(ProjectSaveError(failure?.message ?? 'Unable to update project.'));
    } else {
      emit(ProjectSaved());
      add(ProjectsLoadRequested());
    }
  }

  bool _hasReachedProjectsEnd(ProjectListEntity projects) {
    final hasNextPage = projects.hasNextPage;
    if (hasNextPage != null) return !hasNextPage;
    return projects.projects.isEmpty ||
        (projects.totalCount > 0 &&
            projects.projects.length >= projects.totalCount);
  }

  List<ProjectEntity> _mergeProjects(
    List<ProjectEntity> existing,
    List<ProjectEntity> incoming,
  ) {
    final seen = <String>{};
    final merged = <ProjectEntity>[];
    for (final project in [...existing, ...incoming]) {
      final key = project.id != 0
          ? project.id.toString()
          : project.projectId.trim().isNotEmpty
              ? project.projectId.trim()
              : '${project.name}|${project.address}|${project.phone}';
      if (seen.add(key)) merged.add(project);
    }
    return merged;
  }
}
