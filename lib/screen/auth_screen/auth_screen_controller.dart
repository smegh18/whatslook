import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/functions/debounce_action.dart';
import 'package:shortzz/common/manager/firebase_notification_manager.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/common_service.dart';
import 'package:shortzz/common/service/api/notification_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/service/subscription/subscription_manager.dart';
import 'package:shortzz/languages/dynamic_translations.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/model/user_model/user_model.dart' as user;
import 'package:shortzz/screen/auth_screen/otp_screen.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen.dart';
import 'package:shortzz/screen/edit_profile_screen/widget/phone_codes_screen_controller.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreenController extends BaseController {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController forgetEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  // OTP related variables
  RxInt otpResendTimer = 60.obs;
  RxBool canResendOtp = false.obs;
  String? verificationId;
  int? forceResendingToken;
  bool _forceRecaptchaFlow = false;
  bool _googleInitialized = false;
  static const String _androidPhoneAuthConfigurationMessage =
      'Phone verification is temporarily unavailable. Please try again later or continue with Gmail.';

  @override
  void onInit() {
    if (SessionManager.instance.getSettings() == null) {
      CommonService.instance.fetchGlobalSettings();
    }
    FirebaseNotificationManager.instance;

    // Initialize PhoneCodesScreenController if not already registered
    if (!Get.isRegistered<PhoneCodesScreenController>()) {
      Get.put(PhoneCodesScreenController());
    }

    super.onInit();
  }

  Future<void> onLogin() async {
    await sendOtp();
  }

  String getFullPhoneNumber() {
    final phone = phoneNumberController.text.trim().replaceAll(' ', '');

    if (phone.isEmpty) return '';
    if (phone.startsWith('+')) return phone;

    if (!Get.isRegistered<PhoneCodesScreenController>()) {
      return '';
    }

    final phoneCodeController = Get.find<PhoneCodesScreenController>();
    final prefix = phoneCodeController.selectedCode.value?.phoneCode ?? '';

    if (prefix.isEmpty) return '';

    return '$prefix${phone.replaceAll('+', '')}';
  }

  Future<void> onCreateAccount() async {
    final fullPhoneNumber = getFullPhoneNumber();

    if (fullNameController.text.trim().isEmpty) {
      return showSnackBar(LKey.fullNameEmpty.tr);
    }

    if (fullPhoneNumber.isEmpty) {
      return showSnackBar(LKey.enterPhoneNumber.tr);
    }

    await sendOtp();
  }

  void onGoogleTap() async {
    showLoader(barrierDismissible: false);
    try {
      final credential = await signInWithGoogle();
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        showSnackBar('Google sign-in cancelled');
        return;
      }

      final identity = firebaseUser.email ?? '';
      final fullname =
          firebaseUser.displayName ?? (firebaseUser.email?.split('@')[0] ?? '');

      final user.User? data = await _registration(
        identity: identity,
        loginMethod: LoginMethod.google,
        fullname: fullname,
        loginVia: LoginVia.loginInUser,
      );
      if (data != null) {
        _navigateScreen(data);
      }
    } on GoogleSignInException catch (e) {
      Loggers.error(e);
      final msg = (e.description ?? '').trim();
      showSnackBar(msg.isNotEmpty ? msg : 'Google sign-in failed');
    } on FirebaseAuthException catch (e) {
      Loggers.error(e.message);
      showSnackBar(e.message ?? 'Google sign-in failed');
    } catch (e) {
      Loggers.error(e);
      showSnackBar('Google sign-in failed');
    } finally {
      stopLoader();
    }
  }

  void onAppleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      Loggers.info(
          'EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName ?? credential.user?.email?.split('@')[0]}');
    } catch (e) {
      Loggers.error(e);
      Get.back();
    }
    if (credential?.user == null) return;
    user.User? data = await _registration(
        identity: credential?.user?.email ?? '',
        loginMethod: LoginMethod.apple,
        fullname: credential?.user?.displayName ??
            credential?.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    Get.back();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<user.User?> _registration(
      {required String identity,
      required LoginMethod loginMethod,
      String? fullname,
      required LoginVia loginVia,
      String? password}) async {
    // Retry token fetch (Firebase can take a moment to initialize)
    String? deviceToken;
    for (int i = 0; i < 3; i++) {
      deviceToken =
          await FirebaseNotificationManager.instance.getNotificationToken();
      if (deviceToken != null && deviceToken.isNotEmpty) break;
      if (i < 2) await Future.delayed(const Duration(seconds: 2));
    }
    if (deviceToken == null || deviceToken.isEmpty) {
      showSnackBar(LKey.deviceTokenRequiredForLogin.tr);
      return null;
    }

    user.User? userData;
    switch (loginVia) {
      case LoginVia.loginInUser:
        userData = await UserService.instance.logInUser(
            identity: identity,
            loginMethod: loginMethod,
            deviceToken: deviceToken,
            fullName: fullname);
        break;
      case LoginVia.logInFakeUser:
        userData = await UserService.instance.logInFakeUser(
            identity: identity,
            loginMethod: loginMethod,
            deviceToken: deviceToken,
            password: password);
        break;
    }

    Setting? setting = SessionManager.instance.getSettings();
    if (userData?.isDummy == 0 &&
        userData?.newRegister == true &&
        setting?.registrationBonusStatus == 1) {
      final translations = Get.find<DynamicTranslations>();
      final languageData = translations.keys[userData?.appLanguage] ?? {};

      NotificationService.instance.pushNotification(
          title: languageData[LKey.registrationBonusTitle] ??
              LKey.registrationBonusTitle.tr,
          body: languageData[LKey.registrationBonusDescription] ??
              LKey.registrationBonusDescription.tr,
          type: NotificationType.other,
          deviceType: userData?.device,
          token: userData?.deviceToken,
          authorizationToken: userData?.token?.authToken);
    }
    if (userData != null) {
      await SubscriptionManager.shared.login('${userData.id}');
      // Subscribe My Following Ids For Live streaming notification
      return userData;
    }
    return null;
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());
      SessionManager.instance.setPassword(passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      Loggers.error(e.message);
      if (e.code == 'weak-password') {
        showSnackBar(LKey.weakPassword.tr);
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(LKey.accountExists.tr);
      } else {
        showSnackBar(e.message);
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      if (e.code == 'user-not-found') {
        showSnackBar(LKey.noUserFound.tr);
        Loggers.info(LKey.noUserFound.tr);
      } else if (e.code == 'wrong-password') {
        showSnackBar(LKey.incorrectPassword.tr);
        Loggers.info(LKey.incorrectPassword.tr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    if (!_googleInitialized) {
      await googleSignIn.initialize(
        serverClientId:
            '57465937772-uordso9r0k73rv4lqbo1ps5hpu75un4d.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }

    if (!googleSignIn.supportsAuthenticate()) {
      throw StateError('Google sign-in not supported on this platform');
    }

    final GoogleSignInAccount account =
        await googleSignIn.authenticate().timeout(const Duration(seconds: 60));

    final GoogleSignInAuthentication auth = account.authentication;

    if (auth.idToken == null || auth.idToken!.isEmpty) {
      throw StateError('Failed to get Google ID token');
    }

    // google_sign_in v7 separates ID tokens (authentication) from OAuth access tokens (authorization).
    // FirebaseAuth expects both when available.
    final authClient = account.authorizationClient;
    const scopes = <String>['email'];
    final silentAuthz = await authClient.authorizationForScopes(scopes);
    final authz = silentAuthz ?? await authClient.authorizeScopes(scopes);

    final credential = GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: authz.accessToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode);

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  Future<void> sendOtp() async {
    final fullPhoneNumber = getFullPhoneNumber();

    if (fullPhoneNumber.isEmpty) {
      return showSnackBar(LKey.enterPhoneNumber.tr);
    }

    showLoader();

    await _verifyPhoneNumber(
      fullPhoneNumber,
      navigateToOtpOnCodeSent: true,
      showOtpSentSnackBar: false,
      allowRetryOnMissingAppIdentifier: true,
    );
  }

  Future<void> _verifyPhoneNumber(String phoneNumber,
      {required bool navigateToOtpOnCodeSent,
      required bool showOtpSentSnackBar,
      required bool allowRetryOnMissingAppIdentifier}) async {
    try {
      await _configurePhoneAuthFallbackIfNeeded();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          stopLoader();
          // Auto-verification completed
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _completePhoneRegistration();
        },
        verificationFailed: (FirebaseAuthException e) async {
          stopLoader();

          // Some devices/build types fail Play Integrity app verification and don't reliably
          // fall back to reCAPTCHA. Force reCAPTCHA and retry once.
          if (allowRetryOnMissingAppIdentifier &&
              !_forceRecaptchaFlow &&
              GetPlatform.isAndroid &&
              _isMissingAppIdentifierError(e)) {
            _forceRecaptchaFlow = true;
            showLoader();
            await _configurePhoneAuthFallbackIfNeeded();
            await _verifyPhoneNumber(
              phoneNumber,
              navigateToOtpOnCodeSent: navigateToOtpOnCodeSent,
              showOtpSentSnackBar: showOtpSentSnackBar,
              allowRetryOnMissingAppIdentifier: false,
            );
            return;
          }

          Loggers.error(e.message);
          if (_isFirebaseSmsBlockedError(e)) {
            showSnackBar(
                'OTP is temporarily blocked by Firebase for this device. Please try again later or continue with Gmail.');
            return;
          }
          if (_isMissingAppIdentifierError(e)) {
            _logAndroidPhoneAuthConfigurationError(e);
            showSnackBar(_androidPhoneAuthConfigurationMessage);
            return;
          }
          showSnackBar(e.message ?? "Verification failed");
        },
        codeSent: (String verificationId, int? resendToken) {
          stopLoader();
          this.verificationId = verificationId;
          forceResendingToken = resendToken;
          _startOtpTimer();
          if (navigateToOtpOnCodeSent) {
            Get.to(() => const OtpScreen());
          }
          if (showOtpSentSnackBar) {
            showSnackBar(LKey.otpSent.tr);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
        },
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      stopLoader();
      Loggers.error(e);
      if (e is FirebaseAuthException && _isMissingAppIdentifierError(e)) {
        _logAndroidPhoneAuthConfigurationError(e);
        showSnackBar(_androidPhoneAuthConfigurationMessage);
        return;
      }
      showSnackBar("Failed to send OTP");
    }
  }

  Future<void> _configurePhoneAuthFallbackIfNeeded() async {
    if (!GetPlatform.isAndroid) return;

    try {
      await FirebaseAuth.instance.setSettings(
        forceRecaptchaFlow: _forceRecaptchaFlow,
        appVerificationDisabledForTesting: kDebugMode,
      );
    } catch (e) {
      Loggers.error(e);
    }
  }

  void _logAndroidPhoneAuthConfigurationError(FirebaseAuthException e) {
    Loggers.error(
        'Firebase Android phone auth app verification failed. Add the Android build SHA-256 fingerprints in Firebase Console and Google Play Console if Play App Signing is used. code=${e.code}, message=${e.message}');
  }

  Future<void> resendOtp() async {
    final phoneNumber = getFullPhoneNumber();

    if (phoneNumber.isEmpty) {
      return showSnackBar(LKey.enterPhoneNumber.tr);
    }

    showLoader();

    try {
      await _verifyPhoneNumber(
        phoneNumber,
        navigateToOtpOnCodeSent: false,
        showOtpSentSnackBar: true,
        allowRetryOnMissingAppIdentifier: true,
      );
    } catch (e) {
      stopLoader();
      Loggers.error(e);
      showSnackBar("Failed to resend OTP");
    }
  }

  bool _isMissingAppIdentifierError(FirebaseAuthException e) {
    final message = (e.message ?? '').toLowerCase();
    return message.contains('missing a valid app identifier') ||
        message.contains('play integrity') ||
        e.code == 'missing-client-identifier';
  }

  bool _isFirebaseSmsBlockedError(FirebaseAuthException e) {
    final message = (e.message ?? '').toLowerCase();
    return e.code == 'too-many-requests' ||
        e.code == '17010' ||
        message.contains('17010') ||
        message.contains('blocked all requests') ||
        message.contains('unusual activity') ||
        message.contains('try again later');
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      return showSnackBar(LKey.enterValidOTP.tr);
    }

    if (verificationId == null) {
      return showSnackBar("Verification ID not found");
    }

    showLoader();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _completePhoneRegistration();
    } on FirebaseAuthException catch (e) {
      stopLoader();
      Loggers.error(e.message);
      if (e.code == 'invalid-verification-code') {
        showSnackBar(LKey.invalidOTP.tr);
      } else {
        showSnackBar(e.message ?? "OTP verification failed");
      }
    } catch (e) {
      stopLoader();
      Loggers.error(e);
      showSnackBar("OTP verification failed");
    }
  }

  Future<void> _completePhoneRegistration() async {
    final phoneNumber = getFullPhoneNumber();
    final fullName = fullNameController.text.trim();
    final user.User? data = await _registration(
        identity: phoneNumber,
        loginMethod: LoginMethod.phone,
        fullname: fullName.isNotEmpty ? fullName : phoneNumber,
        loginVia: LoginVia.loginInUser);
    stopLoader();

    if (data != null) {
      _navigateScreen(data);
    } else {
      showSnackBar('Unable to complete login. Please try again.');
    }
  }

  void _startOtpTimer() {
    otpResendTimer.value = 60;
    canResendOtp.value = false;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      otpResendTimer.value--;
      if (otpResendTimer.value <= 0) {
        canResendOtp.value = true;
        return false;
      }
      return true;
    });
  }

  void forgetPassword() async {
    final email = forgetEmailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    showLoader();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      stopLoader();
      Get.back(); // Close the BottomSheet
      showSnackBar(LKey.resetPasswordLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message ?? "An error occurred. Please try again.");
    }
  }

  void _navigateScreen(user.User? data) {
    DebounceAction.shared.call(() async {
      SessionManager.instance.setLogin(true);
      SessionManager.instance.setUser(data);
      Get.offAll(() => DashboardScreen(myUser: data));
    }, milliseconds: 250);
  }
}

enum LoginVia { loginInUser, logInFakeUser }
