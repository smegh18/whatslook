import 'dart:async';
import 'package:get/get.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/common_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/service/network_helper/network_helper.dart';
import 'package:shortzz/common/widget/no_internet_sheet.dart';
import 'package:shortzz/languages/dynamic_translations.dart';
import 'package:shortzz/languages/language_loader.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/screen/auth_screen/login_screen.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen.dart';
import 'package:shortzz/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:shortzz/screen/select_language_screen/select_language_screen.dart';
import 'package:shortzz/utilities/app_res.dart';

class SplashScreenController extends BaseController {
  late StreamSubscription _subscription;
  bool isOnline = true;

  @override
  void onReady() {
    super.onReady();

    unawaited(fetchSettings());
    //Get.off(() => const LoginScreen());

    _subscription = NetworkHelper().onConnectionChange.listen((status) {
      isOnline = status;
      if (isOnline) {
        Get.back();
      } else {
        Get.to(() => const NoInternetSheet(), transition: Transition.downToUp);
      }
    });
  }

  @override
  void onClose() {
    super.onClose();
    _subscription.cancel();
  }

  Future<void> fetchSettings() async {
    bool showNavigate;
    try {
      showNavigate = await CommonService.instance.fetchGlobalSettings();
    } catch (e) {
      Loggers.error('fetchSettings failed: $e');
      showNavigate = false;
    }
    if (showNavigate) {
      final translations = Get.find<DynamicTranslations>();
      var setting = SessionManager.instance.getSettings();
      var languages = setting?.languages ?? [];
      List<Language> downloadLanguages = languages.where((element) => element.status == 1).toList();
      if (downloadLanguages.isEmpty) {
        showSnackBar(AppRes.languageAdd, second: 5);
        return;
      }

      var defaultLang = languages.firstWhereOrNull((element) => element.isDefault == 1);

      if (defaultLang != null) {
        SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
      }

      // Load language CSVs in background to keep startup fast.
      unawaited(() async {
        final downloadedFiles = await LanguageLoader.instance
            .downloadAndParseLanguages(downloadLanguages);
        translations.addTranslations(downloadedFiles);
        Get.forceAppUpdate();
      }());
      if (SessionManager.instance.isLogin()) {
        UserService.instance.fetchUserDetails(userId: SessionManager.instance.getUserID()).then((value) {
          if (value != null) {
            Get.off(() => DashboardScreen(myUser: value));
          } else {
            Get.off(() => const LoginScreen());
          }
        });
      } else {
        bool isLanguageSelect = SessionManager.instance.getBool(SessionKeys.isLanguageScreenSelect);
        bool onBoardingShow = SessionManager.instance.getBool(SessionKeys.isOnBoardingScreenSelect);
        if (isLanguageSelect == false) {
          Get.off(() => const SelectLanguageScreen(languageNavigationType: LanguageNavigationType.fromStart));
        } else if (onBoardingShow == false && (setting?.onBoarding ?? []).isNotEmpty) {
          Get.off(() => const OnBoardingScreen());
        } else {
          Get.off(() => const LoginScreen());
        }
      }
    } else {
      // If fetch settings is not available, route to login screen
      Loggers.error('fetch settings is not available');
      Get.off(() => const LoginScreen());
    }
  }

}
