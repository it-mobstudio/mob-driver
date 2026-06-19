import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class AuthEvent {}

final class AuthOtpSendRequested extends AuthEvent {
  AuthOtpSendRequested({required this.emailOrPhone, required this.isPhone});
  final String emailOrPhone;
  final bool isPhone;
}

final class AuthOtpVerifyRequested extends AuthEvent {
  AuthOtpVerifyRequested({required this.emailOrPhone, required this.otp});
  final String emailOrPhone;
  final String otp;
}

final class AuthRegisterRequested extends AuthEvent {
  AuthRegisterRequested({
    required this.name,
    this.phone,
    this.email,
    this.gstin,
    this.businessName,
    this.referralCode,
  });
  final String name;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? businessName;
  final String? referralCode;
}

final class AuthSignOutRequested extends AuthEvent {}

// ── States ───────────────────────────────────────────────────────────────────

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthOtpSent extends AuthState {
  AuthOtpSent(this.emailOrPhone);
  final String emailOrPhone;
}

final class AuthVerified extends AuthState {
  AuthVerified({required this.isNewAccount, required this.userDetails});
  final bool isNewAccount;
  final Map<String, dynamic> userDetails;
}

final class AuthRegistered extends AuthState {}

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
    on<AuthRegisterRequested>(_onRegister);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repository;

  Future<void> _onSendOtp(
    AuthOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final (success, failure) = await _repository.sendOtp(
      emailOrPhone: event.emailOrPhone,
      isPhone: event.isPhone,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(AuthError(failure.message));
    } else if (success) {
      emit(AuthOtpSent(event.emailOrPhone));
    } else {
      AppHaptics.error();
      emit(AuthError('Failed to send OTP. Please try again.'));
    }
  }

  Future<void> _onVerifyOtp(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final (result, failure) = await _repository.verifyOtp(
      emailOrPhone: event.emailOrPhone,
      otp: event.otp,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(AuthError(failure.message));
    } else {
      emit(AuthVerified(
        isNewAccount: result!.isNewAccount,
        userDetails: result.userDetails,
      ));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final (success, failure) = await _repository.registerUser(
      name: event.name,
      phone: event.phone,
      email: event.email,
      gstin: event.gstin,
      businessName: event.businessName,
      referralCode: event.referralCode,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(AuthError(failure.message));
    } else if (success) {
      emit(AuthRegistered());
    } else {
      AppHaptics.error();
      emit(AuthError('Registration failed. Please try again.'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await AuthSession.instance.signOut();
    // Deliberately NOT clearing SelectedAddressStore here: the delivery
    // address is tied to where the device/user is, not to the auth session,
    // so it should survive logout and be picked up automatically on the
    // next login instead of forcing address selection again.
    emit(AuthSignedOut());
  }
}
