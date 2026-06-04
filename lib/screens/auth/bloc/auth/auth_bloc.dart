import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grofery_user/model/user_data_model/user_data_model.dart';
import 'package:grofery_user/screens/auth/repo/auth_repo.dart';
import 'package:grofery_user/bloc/user_details_bloc/user_details_bloc.dart';
import '../../../../bloc/user_details_bloc/user_details_event.dart';
import '../../model/auth_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository = AuthRepository();
  final UserDataBloc _userDetailBloc;

  Map<String, dynamic>? _pendingRegistrationData;
  String? _pendingPhoneNumber;
  String? _pendingCountryCode;
  String? _pendingIsoCode;

  AuthBloc(this._userDetailBloc) : super(AuthInitial()) {
    on<LoginRequest>(_onLoginRequest);
    on<RegisterRequest>(_onRegisterRequest);
    on<LogoutUserRequest>(_onLogoutUserRequest);
    on<DeleteUserRequest>(_onDeleteUserRequest);
    on<SendOtpToPhoneEvent>(_onSendOtpToPhone);
    on<VerifySentOtp>(_onVerifySentOtp);
    on<OnPhoneOtpSend>(_onPhoneOtpSent);
    on<OnPhoneAuthVerificationCompleted>(_onPhoneAuthVerified);
    on<CompleteMobileOtpLogin>(_onCompleteMobileOtpLogin);
    on<ResendOtpRequest>(_onResendOtp);
    on<AuthFailureEvent>(_onAuthFailureEvent);
    on<SocialAuthRequest>(_onSocialAuthRequest);
    on<GoogleLoginRequest>(_onGoogleLoginRequest);
    on<AppleLoginRequest>(_onAppleLoginRequest);
    on<StoreRegistrationDataEvent>(_onStoreRegistrationData);
    on<ClearRegistrationDataEvent>(_onClearRegistrationData);
    on<DeleteUserAccount>(_onDeleteUserAccount);
  }

  Future<void> _onStoreRegistrationData(
    StoreRegistrationDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    _pendingRegistrationData = event.registrationData;
    _pendingPhoneNumber = event.phoneNumber;
    _pendingCountryCode = event.countryCode;
    _pendingIsoCode = event.isoCode;

    log('✅ Registration data stored in bloc');
    emit(RegistrationDataStored(
      registrationData: event.registrationData,
      phoneNumber: event.phoneNumber,
      countryCode: event.countryCode,
      isoCode: event.isoCode,
    ));
  }

  Map<String, dynamic>? getPendingRegistrationData() =>
      _pendingRegistrationData;

  String? getPendingPhoneNumber() => _pendingPhoneNumber;
  String? getPendingCountryCode() => _pendingCountryCode;
  String? getPendingIsoCode() => _pendingIsoCode;

  Future<void> _onClearRegistrationData(
    ClearRegistrationDataEvent event,
    Emitter<AuthState> emit,
  ) async {
    _pendingRegistrationData = null;
    _pendingPhoneNumber = null;
    _pendingCountryCode = null;
    _pendingIsoCode = null;
    log('🗑️ Registration data cleared from bloc');
  }

  Future<void> _onLoginRequest(
    LoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _repository.login(
        email: event.email ?? '',
        phoneNumber: event.phoneNumber ?? '',
        password: event.password,
      );

      if (response.first.success == true) {
        final userData = response.first.data!;
        _userDetailBloc.add(SetUserData(UserDataModel(
          token: response.first.accessToken ?? '',
          userId: userData.id.toString(),
          name: userData.name ?? '',
          email: userData.email ?? '',
          mobile: userData.mobile ?? '',
          country: userData.country ?? '',
          iso2: userData.iso2 ?? '',
          profileImage: userData.profileImage ?? '',
          referralCode: userData.referralCode ?? '',
          shopName: userData.shopName ?? '',
          gstNumber: userData.gstNumber ?? '',
          language: 'en',
        )));

        emit(
            AuthSuccess(message: response.first.message ?? 'Login successful'));
      } else {
        emit(AuthFailed(error: response.first.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onRegisterRequest(
    RegisterRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _repository.register(
        name: event.name,
        email: event.email,
        mobile: event.mobile,
        country: event.country,
        iso2: event.iso2,
        password: event.password,
        confirmPassword: event.confirmPassword,
        shopName: event.shopName,
        gstNumber: event.gstNumber,
      );

      if (response.first.success == true) {
        final userData = response.first.data!;
        _userDetailBloc.add(SetUserData(UserDataModel(
          token: response.first.accessToken ?? '',
          userId: userData.id.toString(),
          name: userData.name ?? '',
          email: userData.email ?? '',
          mobile: userData.mobile ?? '',
          country: userData.country ?? '',
          iso2: userData.iso2 ?? '',
          profileImage: userData.profileImage ?? '',
          referralCode: userData.referralCode ?? '',
          shopName: userData.shopName ?? '',
          gstNumber: userData.gstNumber ?? '',
          language: 'en',
        )));
        emit(AuthSuccess(
            message: response.first.message ?? 'Register successful'));
      } else {
        String errorMessage = response.first.message ?? 'Register failed';

        if (errorMessage
            .toLowerCase()
            .contains('mobile has already been taken')) {
          errorMessage =
              'This mobile number is already registered. Please use a different number or login.';
        }

        emit(AuthFailed(error: errorMessage));
      }
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onLogoutUserRequest(
    LogoutUserRequest event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await FirebaseAuth.instance.signOut();
      await _repository.logout();
      _userDetailBloc.add(ClearUserData());

      _pendingRegistrationData = null;
      _pendingPhoneNumber = null;
      _pendingCountryCode = null;
      _pendingIsoCode = null;
      emit(LogoutUserSuccess());
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onDeleteUserRequest(
    DeleteUserRequest event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.delete();
      _userDetailBloc.add(ClearUserData());
      _pendingRegistrationData = null;
      _pendingPhoneNumber = null;
      _pendingCountryCode = null;
      _pendingIsoCode = null;
      emit(DeleteUserSuccess());
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onSendOtpToPhone(
    SendOtpToPhoneEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(LoginCodeSentProgress(
      registrationData: _pendingRegistrationData,
      phoneNumber: _pendingPhoneNumber,
      countryCode: _pendingCountryCode,
      isoCode: _pendingIsoCode,
      isLogin: event.isLogin,
    ));
    try {
      await _verifyPhoneNumber(
        countryCode: event.countryCode,
        phoneNumber: event.number,
        isoCode: event.isoCode,
        isLogin: event.isLogin,
      );
    } catch (e) {
      log('OTP Send Failed: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onVerifySentOtp(
    VerifySentOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(VerifyingOTP());
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otpCode,
      );
      add(OnPhoneAuthVerificationCompleted(
        credential: credential,
        countryCode: event.countryCode,
        number: event.phoneNumber,
        isoCode: event.isoCode,
        isLogin: event.isLogin,
      ));
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  void _onPhoneOtpSent(OnPhoneOtpSend event, Emitter<AuthState> emit) {
    log('📱 Emitting LoginPhoneCodeSentState with ID: ${event.verificationId}');
    emit(LoginPhoneCodeSentState(
      verificationId: event.verificationId,
      registrationData: _pendingRegistrationData,
      phoneNumber: _pendingPhoneNumber,
      countryCode: _pendingCountryCode,
      isoCode: _pendingIsoCode,
      isLogin: event.isLogin,
    ));
  }

  Future<void> _onPhoneAuthVerified(
    OnPhoneAuthVerificationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final credential = event.credential;
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken(true);

      log('Phone Auth Success | Token: $token | Number: ${event.number}');

      if (event.isLogin) {
        // Handle Mobile OTP Login flow
        add(CompleteMobileOtpLogin(
          phoneNumber: event.number ?? '',
          token: token ?? '',
        ));
      } else {
        emit(OTPVerified(message: 'OTP Verified'));
      }
    } catch (e, s) {
      log('Phone verification failed: $e', stackTrace: s);
      String errorMessage = e.toString();
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'The entered OTP is incorrect. Please try again.';
            break;
          case 'session-expired':
            errorMessage =
                'The OTP session has expired. Please request a new OTP.';
            break;
          default:
            errorMessage = e.message ?? 'Verification failed';
        }
      }
      emit(AuthFailed(error: errorMessage));
    }
  }

  Future<void> _onResendOtp(
    ResendOtpRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _verifyPhoneNumber(
        countryCode: event.countryCode,
        phoneNumber: event.phoneNumber,
        isoCode: event.isoCode,
        isLogin: event.isLogin,
      );
    } catch (e) {
      emit(AuthFailed(error: 'Please wait before resending.'));
    }
  }

  Future<void> _verifyPhoneNumber({
    required String countryCode,
    required String phoneNumber,
    required String isoCode,
    required bool isLogin,
  }) async {
    final fullNumber = countryCode + phoneNumber;
    log('Verifying phone: $fullNumber | ISO: $isoCode');

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        add(OnPhoneAuthVerificationCompleted(
          credential: credential,
          countryCode: countryCode,
          number: phoneNumber,
          isoCode: isoCode,
          isLogin: isLogin,
        ));
      },
      verificationFailed: (FirebaseAuthException e) {
        log('Verification failed: ${e.message}');
        add(AuthFailureEvent(error: e.message ?? 'Verification failed'));
      },
      codeSent: (String verificationId, int? resendToken) {
        log('✅ OTP Code Sent! VerificationId: $verificationId');
        add(OnPhoneOtpSend(
            verificationId: verificationId,
            resendToken: resendToken,
            isLogin: isLogin));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        log('Auto retrieval timeout: $verificationId');
      },
      timeout: const Duration(seconds: 120),
    );
  }

  Future<void> _onAuthFailureEvent(
    AuthFailureEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthFailed(error: event.error));
  }

  Future<void> _onSocialAuthRequest(
    SocialAuthRequest event,
    Emitter<AuthState> emit,
  ) async {
    try {
      log('🔵 SocialAuth: Calling backend API...');
      final response = await _repository.socialAuth(
        firebaseToken: event.firebaseToken,
        name: event.name,
        email: event.email,
        isApple: event.isApple,
      );
      log('🔵 SocialAuth: Response received: ${response.keys}');

      final data = response['data'];

      if (response['success'] == false &&
          data is Map &&
          data['new_user'] == true) {
        log('🔵 SocialAuth: New user detected → navigating to register');
        emit(SocialAuthSuccess(
          newUser: true,
          userName: data['name'] ?? '',
          userEmail: data['email'] ?? '',
        ));
      } else if (response['success'] == true) {
        log('🔵 SocialAuth: Existing user → logging in');
        List<AuthModel> userData = [];
        userData.add(AuthModel.fromJson(response));
        final user = userData.first.data!;

        _userDetailBloc.add(SetUserData(UserDataModel(
          token: userData.first.accessToken ?? '',
          userId: user.id.toString(),
          name: user.name ?? '',
          email: user.email ?? '',
          mobile: user.mobile ?? '',
          country: user.country ?? '',
          iso2: user.iso2 ?? '',
          profileImage: user.profileImage ?? '',
          referralCode: user.referralCode ?? '',
          shopName: user.shopName ?? '',
          gstNumber: user.gstNumber ?? '',
          language: 'en',
        )));
        emit(
            AuthSuccess(message: userData.first.message ?? 'Login successful'));
      } else {
        log('🔴 SocialAuth: Unexpected response: $response');
        emit(AuthFailed(
            error: response['message']?.toString() ??
                'Google login failed. Please try again.'));
      }
    } catch (e) {
      log('🔴 SocialAuth error: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onGoogleLoginRequest(
    GoogleLoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tokens = await _repository.googleLogin();
      final firebaseToken = tokens['firebaseToken'] ?? '';
      final userName = tokens['userName'] ?? '';
      final userEmail = tokens['userEmail'] ?? '';

      if (firebaseToken.isEmpty) {
        emit(AuthInitial());
        return;
      }
      add(SocialAuthRequest(
        firebaseToken: firebaseToken,
        name: userName,
        email: userEmail,
        isApple: false,
      ));
    } catch (e) {
      log('🔴 GoogleLoginRequest Error: $e');
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onAppleLoginRequest(
    AppleLoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      String firebaseUserToken = await _repository.appleLogin();
      log('Firebase token via apple  $firebaseUserToken');
      if (firebaseUserToken.isEmpty) {
        emit(AuthInitial());
      }
      add(SocialAuthRequest(firebaseToken: firebaseUserToken, isApple: true));
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onDeleteUserAccount(
      DeleteUserAccount event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _repository.deleteUser();
      if (response['success'] == true) {
        emit(DeleteUserSuccess());
      }
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }

  Future<void> _onCompleteMobileOtpLogin(
      CompleteMobileOtpLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _repository.mobileOtpLogin(
        firebaseToken: event.token,
      );

      if (response['success'] == true) {
        List<AuthModel> userData = [];
        userData.add(AuthModel.fromJson(response));
        final user = userData.first.data!;

        _userDetailBloc.add(SetUserData(UserDataModel(
          token: userData.first.accessToken ?? '',
          userId: user.id.toString(),
          name: user.name ?? '',
          email: user.email ?? '',
          mobile: user.mobile ?? '',
          country: user.country ?? '',
          iso2: user.iso2 ?? '',
          profileImage: user.profileImage ?? '',
          referralCode: user.referralCode ?? '',
          shopName: user.shopName ?? '',
          gstNumber: user.gstNumber ?? '',
          language: 'en',
        )));
        emit(
            AuthSuccess(message: userData.first.message ?? 'Login successful'));
      } else {
        emit(AuthFailed(error: response['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailed(error: e.toString()));
    }
  }
}
