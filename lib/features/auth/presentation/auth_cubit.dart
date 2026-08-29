import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phone;
  const AuthOtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository = AuthRepository();

  AuthCubit() : super(AuthInitial()) {
    checkCachedUser();
  }

  Future<void> checkCachedUser() async {
    try {
      final user = await _repository.getCachedUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthInitial());
      }
    } catch (_) {
      emit(AuthInitial());
    }
  }

  Future<void> sendOtp(String phone) async {
    emit(AuthLoading());
    // Simulate sending OTP. In real app Firebase Phone verification would happen here.
    await Future.delayed(const Duration(milliseconds: 600));
    emit(AuthOtpSent(phone));
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(AuthLoading());
    try {
      final user = await _repository.verifyOtp(phone, otp);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(AuthOtpSent(phone)); // Go back to OTP sent screen so user can retry
    }
  }

  Future<void> updateProfile(String name, String houseNo, String area, String landmark) async {
    if (state is! AuthAuthenticated) return;
    
    final current = (state as AuthAuthenticated).user;
    emit(AuthLoading());
    try {
      final updated = await _repository.updateProfile(name, houseNo, area, landmark);
      emit(AuthAuthenticated(updated));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthAuthenticated(current));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final user = await _repository.getCachedUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthInitial());
      }
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _repository.logout();
    emit(AuthInitial());
  }
}
