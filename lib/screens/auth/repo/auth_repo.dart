import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;
import 'package:grofery_user/config/api_base_helper.dart';
import 'package:grofery_user/config/api_routes.dart';
import 'package:grofery_user/config/constant.dart';
import 'package:grofery_user/config/notification_service.dart';
import 'package:grofery_user/screens/auth/model/auth_model.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _serverClientId = AppConstant.serverClientId;
  late final g_auth.GoogleSignIn _googleSignIn = g_auth.GoogleSignIn.instance;

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
      required String confirmPassword,
      String? shopName,
      String? gstNumber}) async {
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
        if (shopName != null && shopName.isNotEmpty) 'shop_name': shopName,
        if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
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
      await _auth.signOut();
      await _googleSignIn.signOut();
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
    String? name,
    String? email,
    required bool isApple,
  }) async {
    try {
      String? fcmToken = await getFCMToken();
      String? apiUrl =
          isApple ? ApiRoutes.appleAuthApi : ApiRoutes.googleAuthApi;

      log('🔑 Sending SocialAuth: firebase_token=${firebaseToken.substring(0, 10)}..., name=$name, email=$email');

      final response = await AppConstant.apiBaseHelper.postAPICall(apiUrl, {
        'id_token': firebaseToken,
        'idToken': firebaseToken, // Compatibility
        'name': name,
        'email': email,
        'device_type': getDeviceType(),
        'fcm_token': fcmToken,
      });
      log('🔑 API Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return response.data;
      }
      final msg = response.data is Map ? response.data['message'] : null;
      throw ApiException(
          msg?.toString() ?? 'Social auth failed (${response.statusCode})');
    } catch (e) {
      log('🔴 SocialAuth Repository Error: $e');
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, String>> googleLogin() async {
    try {
      log('🔵 Step 1: Authenticating user');
      final g_auth.GoogleSignInAccount googleUser =
          await _googleSignIn.authenticate(scopeHint: ['email']);

      log('🔵 Step 2: Got Google user - ID: ${googleUser.id}');

      log('🔵 Step 3: Getting authentication details');
      final g_auth.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      log('🔵 Step 4: Got auth - idToken: ${googleAuth.idToken != null ? "EXISTS" : "NULL"}');

      log('🔵 Step 5: Creating Firebase credential');
      String? accessToken;
      try {
        // Attempt to get access token, but don't let it block the whole flow if it fails
        // as idToken is often sufficient for Firebase login.
        final authorization =
            await googleUser.authorizationClient.authorizeScopes(['email']);
        accessToken = authorization.accessToken;
        log('🔵 Step 6: Got access token: ${accessToken.isNotEmpty ? "EXISTS" : "EMPTY"}');
      } catch (authzError) {
        log('⚠️ Warning: Failed to authorize scopes for access token: $authzError');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      log('🔵 Step 7: Signing in to Firebase with credential');
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      log('🔵 Step 8: Firebase user: ${user != null ? "ID: ${user.uid}" : "NULL"}');
      if (user != null) {
        log('🔵 Step 9: Getting Firebase ID token');
        final String? firebaseToken = await user.getIdToken();

        log('🔵 Step 10: Firebase token: ${firebaseToken != null ? "EXISTS" : "NULL"}');
        if (firebaseToken != null) {
          log('✅ Google login successful');
          return {
            'firebaseToken': firebaseToken,
            'googleToken': googleAuth.idToken ?? '',
            'userName': user.displayName ?? '',
            'userEmail': user.email ?? '',
          };
        } else {
          throw ApiException('Failed to get Firebase token');
        }
      } else {
        throw ApiException('Failed to sign in to Firebase');
      }
    } catch (e, stack) {
      log('❌ Google login error: $e');
      log('❌ Stack trace: $stack');
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('cancel') || errorMessage.contains('12501')) {
        log('⚠️ User cancelled - returning empty map');
        return {};
      } else {
        log('🔴 Throwing exception: $e');
        throw ApiException('Google login failed: $e');
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
