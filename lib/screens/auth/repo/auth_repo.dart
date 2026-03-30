import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/notification_service.dart';
import 'package:grofery_user/screens/auth/model/auth_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _serverClientId = AppConstant.serverClientId;

  String deviceType = '';
  String getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'unknown';
    }
  }

  Future<List<AuthModel>> login({
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      final response =
          await AppConstant.apiBaseHelper.postAPICall(ApiRoutes.loginApi, {
        if (email.isNotEmpty) 'email': email,
        if (phoneNumber.isNotEmpty) 'mobile': phoneNumber,
        'password': password,
        'fcm_token': fcmToken,
        'device_type': getDeviceType()
      });
      if (response.data['success'] == true) {
        List<AuthModel> userData = [];
        userData.add(AuthModel.fromJson(response.data));
        return userData;
      } else {
        // API returned failure — throw a meaningful exception with the message
        String message = response.data['message']?.toString() ?? 'Login failed';
        throw ApiException(message);
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<AuthModel>> register(
      {required String name,
      required String email,
      required String mobile,
      required String country,
      required String iso2,
      required String password,
      required String confirmPassword}) async {
    try {
      String? fcmToken = await getFCMToken();
      Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
        'country': country,
        'iso_2': iso2,
        'password_confirmation': confirmPassword,
        'fcm_token': fcmToken,
        'device_type': getDeviceType()
      };

      log("REGISTER DATA: ${jsonEncode(data)}");

      final response = await AppConstant.apiBaseHelper
          .postAPICall(ApiRoutes.registerApi, data);

      if (response.data['success'] == true) {
        List<AuthModel> userData = [];
        userData.add(AuthModel.fromJson(response.data));
        return userData;
      }
      return [];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> verifyUser(
      {required String type, required String value}) async {
    try {
      final response = await AppConstant.apiBaseHelper
          .postAPICall(ApiRoutes.verifyUserApi, {'type': type, 'value': value});
      return response.data;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await AppConstant.apiBaseHelper.postAPICall(ApiRoutes.logoutApi, {});
    } catch (e) {
      throw ApiException('Failed to logout user');
    }
  }

  Future<String> sendOTP({required String phoneNumber}) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          throw ApiException(e.message ?? 'Failed to send OTP');
        },
        codeSent: (String verificationId, int? resendToken) {},
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );

      return '';
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, String>> sendOTPWithCallback({
    required String phoneNumber,
    Function(String verificationId)? onCodeSent,
  }) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final Completer<String> completer = Completer<String>();

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          completer.completeError(e.message ?? 'Failed to send OTP');
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete(verificationId);
          if (onCodeSent != null) {
            onCodeSent(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );

      final verificationId = await completer.future;
      return {'verificationId': verificationId};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<bool> verifyOTP(
      {required String verificationId, required String otpCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> mobileOtpLogin({
    required String firebaseToken,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      final response = await AppConstant.apiBaseHelper
          .postAPICall(ApiRoutes.mobileOtpAuthApi, {
        'id_token': firebaseToken,
        // 'idToken': "",
        'device_type': getDeviceType(),
        'fcm_token': fcmToken,
      });
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> socialAuth({
    required String firebaseToken,
    required bool isApple,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      String? apiUrl = '';
      if (isApple) {
        apiUrl = ApiRoutes.appleAuthApi;
      } else {
        apiUrl = ApiRoutes.googleAuthApi;
      }

      final response = await AppConstant.apiBaseHelper.postAPICall(apiUrl, {
        'id_token': firebaseToken,
        'device_type': getDeviceType(),
        'fcm_token': fcmToken,
      });
      log('🔑 Sending to API: id_token=${firebaseToken.isEmpty ? "EMPTY" : "HAS_VALUE"}, device_type=${getDeviceType()}, fcm_token=${fcmToken?.isEmpty ?? true ? "EMPTY" : "HAS_VALUE"}');
      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> googleLogin() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    try {
      log('🔵 Step 1: Initializing Google Sign-In');
      await googleSignIn.initialize(serverClientId: _serverClientId);

      log('🔵 Step 2: Authenticating user');
      final GoogleSignInAccount googleUser =
          await googleSignIn.authenticate(scopeHint: ['email']);

      log('🔵 Step 3: Got Google user - ID: ${googleUser.id}');
      if (googleUser.id.isEmpty) {
        throw ApiException('User cancelled the login');
      }

      log('🔵 Step 4: Getting authentication details');
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      log('🔵 Step 5: Got auth - idToken: ${googleAuth.idToken != null ? "EXISTS" : "NULL"}');

      final authClient = googleSignIn.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email']);
      log('🔵 Step 6: Got authorization - accessToken: ${authorization?.accessToken != null ? "EXISTS" : "NULL"}');

      log('🔵 Step 7: Creating Firebase credential');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      log('🔵 Step 8: Signing in to Firebase');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      log('🔵 Step 9: Firebase user: ${user != null ? "EXISTS" : "NULL"}');
      if (user != null) {
        log('🔵 Step 10: Getting Firebase ID token');
        final IdTokenResult idTokenResult = await user.getIdTokenResult();
        final String? accessToken = idTokenResult.token;

        log('🔵 Step 11: Firebase token: ${accessToken != null ? "EXISTS (length: ${accessToken.length})" : "NULL"}');
        if (accessToken != null) {
          log('✅ Google login successful - returning token');
          return accessToken;
        } else {
          throw ApiException('Failed to get token');
        }
      } else {
        throw ApiException('Failed to sign in');
      }
    } catch (e) {
      log('❌ Google login error: $e');
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('cancel')) {
        log('⚠️ User cancelled - returning empty string');
        return '';
      } else {
        // Any other error — treat as real failure
        log('🔴 Throwing exception: $e');
        throw ApiException(e.toString());
      }
    }
  }

  Future<String> appleLogin() async {
    try {
      // Trigger Apple Sign In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create Firebase credential from Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await userCredential.user!.getIdToken(true);

      final user = userCredential.user;
      if (user != null) {
        // Get Firebase ID token (this is the JWT you likely want, similar to Google's accessToken in your example)
        final idTokenResult = await user.getIdTokenResult();
        final String? accessToken = idTokenResult.token;

        if (accessToken != null) {
          return accessToken;
        } else {
          throw ApiException('Failed to get Firebase ID token');
        }
      } else {
        throw ApiException('Failed to sign in with Apple');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle Apple-specific errors (e.g., user cancelled)
      if (e.code == AuthorizationErrorCode.canceled) {
        throw ApiException('User cancelled the Apple login');
      } else {
        throw ApiException('Apple login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await AppConstant.apiBaseHelper
          .postAPICall(ApiRoutes.forgotPasswordApi, {'email': email});

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteUser() async {
    try {
      final response = await AppConstant.apiBaseHelper
          .getAPICall(ApiRoutes.deleteUserApi, {});
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {};
      }
    } catch (e) {
      throw ApiException('Failed to get user profile');
    }
  }
}
