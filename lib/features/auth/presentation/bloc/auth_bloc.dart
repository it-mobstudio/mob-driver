import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class AuthEvent {}

/// [phoneNumber] is the full international number, e.g. `+919000000000` —
/// the backend matches drivers on it exactly.
final class AuthOtpSendRequested extends AuthEvent {
  AuthOtpSendRequested({required this.phoneNumber});
  final String phoneNumber;
}

final class AuthOtpVerifyRequested extends AuthEvent {
  AuthOtpVerifyRequested({required this.phoneNumber, required this.otp});
  final String phoneNumber;
  final String otp;
}

final class AuthSignOutRequested extends AuthEvent {}

// ── States ───────────────────────────────────────────────────────────────────

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthOtpSent extends AuthState {
  AuthOtpSent(this.phoneNumber, {this.debugOtp});
  final String phoneNumber;

  /// Present only against a non-production backend — see
  /// [OtpRequestResult.debugOtp].
  final String? debugOtp;
}

final class AuthVerified extends AuthState {
  AuthVerified({required this.userDetails});
  final Map<String, dynamic> userDetails;
}

final class AuthSignedOut extends AuthState {}

final class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AuthOtpSendRequested>(_onSendOtp);
    on<AuthOtpVerifyRequested>(_onVerifyOtp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repository;

  Future<void> _onSendOtp(
    AuthOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final (result, failure) =
        await _repository.sendOtp(phoneNumber: event.phoneNumber);
    if (result == null) {
      AppHaptics.error();
      emit(AuthError(failure?.message ?? 'Failed to send OTP. Please try again.'));
      return;
    }
    emit(AuthOtpSent(event.phoneNumber, debugOtp: result.debugOtp));
  }

  Future<void> _onVerifyOtp(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final (result, failure) = await _repository.verifyOtp(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
    );
    if (result == null) {
      AppHaptics.error();
      emit(AuthError(failure?.message ?? 'OTP verification failed.'));
      return;
    }
    emit(AuthVerified(userDetails: result.userDetails));
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    emit(AuthSignedOut());
  }
}
