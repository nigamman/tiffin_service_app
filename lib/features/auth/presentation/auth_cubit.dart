import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String verificationId;
  final String name;
  const AuthOtpSent({required this.phone, required this.verificationId, required this.name});

  @override
  List<Object?> get props => [phone, verificationId, name];
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  final bool isSmsUnavailable;
  const AuthError(this.message, {this.isSmsUnavailable = false});

  @override
  List<Object?> get props => [message, isSmsUnavailable];
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

  Future<void> sendOtp(String phone, String name) async {
    emit(AuthLoading());
    try {
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            final User? firebaseUser = userCredential.user;
            if (firebaseUser != null) {
              final profile = await _repository.getUserOrCreateProfile(
                id: firebaseUser.uid,
                phone: phone,
                name: name,
              );
              emit(AuthAuthenticated(profile));
            }
          } catch (e) {
            emit(AuthError(e.toString()));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(const AuthError(
            "OTP service is temporarily unavailable. Please log in with Google to continue.",
            isSmsUnavailable: true,
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          emit(AuthOtpSent(phone: phone, verificationId: verificationId, name: name));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(const AuthError(
        "OTP service is temporarily unavailable. Please log in with Google to continue.",
        isSmsUnavailable: true,
      ));
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
    required String verificationId,
    required String name,
  }) async {
    emit(AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception("Sign in failed");
      }
      
      final profile = await _repository.getUserOrCreateProfile(
        id: firebaseUser.uid,
        phone: phone,
        name: name,
      );
      emit(AuthAuthenticated(profile));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      emit(AuthOtpSent(phone: phone, verificationId: verificationId, name: name));
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
