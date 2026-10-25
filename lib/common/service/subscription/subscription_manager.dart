import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/utilities/const_res.dart';

bool isPurchaseConfig = false;
RxBool isSubscribe = false.obs;

class SubscriptionManager {
  static var shared = SubscriptionManager();
  List<Package> packages = [];
  List<Package> offering = [];

  Future<void> initPlatformState() async {
    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      if (revenueCatAndroidApiKey.isNotEmpty) {
        configuration = PurchasesConfiguration(revenueCatAndroidApiKey);
        if (kDebugMode) {
          Purchases.setLogLevel(LogLevel.debug);
        }
        await Purchases.configure(configuration);
      }
    } else if (Platform.isIOS) {
      if (revenueCatAppleApiKey.isNotEmpty) {
        configuration = PurchasesConfiguration(revenueCatAppleApiKey);
        if (kDebugMode) {
          Purchases.setLogLevel(LogLevel.debug);
        }
        await Purchases.configure(configuration);
      }
    }
    await checkIsConfigured();
    if (isPurchaseConfig) {
      await fetchOfferings();
    }
  }

  bool checkSubscription(CustomerInfo customerInfo) {
    if (customerInfo.latestExpirationDate == null ||
        customerInfo.latestExpirationDate!.isEmpty) {
      isSubscribe.value = false;
    } else {
      DateTime dt1 =
          DateTime.parse(customerInfo.latestExpirationDate ?? '').toLocal();
      DateTime dt2 = DateTime.now();

      int leftSecond = dt1.difference(dt2).inSeconds;
      log('⏱️ Expire Time : $dt1 == Current Time : $dt2 || Time Left: ${leftSecond > 0 ? leftSecond : 0} seconds');

      if (dt1.compareTo(dt2) < 0) {
        isSubscribe.value = false;
      }
      if (dt1.compareTo(dt2) > 0) {
        isSubscribe.value = true;
      }
    }

    log('🔔 Subscription Status : ${isSubscribe.value ? 'Active' : 'InActive'}');
    return isSubscribe.value;
  }

  Future<void> subscriptionListener() async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat listener skipped: Purchases not configured');
        return;
      }
      Purchases.addCustomerInfoUpdateListener((customerInfo) async {
        int status = checkSubscription(customerInfo) ? 1 : 0;
        User? user = SessionManager.instance.getUser();
        if (user?.isVerify == status) {
          return;
        }
        UserService.instance.updateUserDetails(isVerify: status);
      });
    } on PlatformException catch (e) {
      // Error fetching purchaser info
      log('RevenueCat Error : ${e.message.toString()}');
    }
  }

  Future<void> checkIsConfigured() async {
    try {
      isPurchaseConfig = await Purchases.isConfigured;
      log('isPurchaseConfig  :$isPurchaseConfig');
    } on PlatformException catch (e) {
      isPurchaseConfig = false;
      log('RevenueCat configuration check failed: ${e.message}');
    }
  }

  Future<LogInResult?> login(String appUserID) async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat login skipped: Purchases not configured');
        return null;
      }
      return await Purchases.logIn(appUserID);
    } on PlatformException catch (e) {
      log('RevenueCat login failed: ${e.message}');
      return null;
    } catch (e) {
      log('RevenueCat login failed: $e');
      return null;
    }
  }

  Future<(Offering?, String?)> fetchOfferings() async {
    try {
      final configured = await Purchases.isConfigured;
      if (!configured) {
        return (null, 'Purchases not configured');
      }
      Offerings offerings = await Purchases.getOfferings();
      // Display current offering with offerings.current
      offering.addAll(offerings.current?.availablePackages
              .where((element) => element.packageType == PackageType.custom) ??
          []);

      packages.addAll(offerings.current?.availablePackages
              .where((element) => element.packageType != PackageType.custom) ??
          []);
      packages
          .sort((a, b) => b.storeProduct.price.compareTo(a.storeProduct.price));

      return (offerings.current, null);
    } on PlatformException catch (e) {
      // Error restoring purchases
      log('Fetch Offering : ${e.message.toString()}');
      return (null, e.message);
    }
  }

  Future<bool?> checkSubscriptionStatus() async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat subscription check skipped: Purchases not configured');
        return null;
      }
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return checkSubscription(customerInfo);
    } on PlatformException catch (e) {
      log(e.message.toString());
      // Error fetching purchaser info
    }
    return null;
  }

  Future<bool?> makePurchase(Package package) async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat purchase skipped: Purchases not configured');
        return null;
      }
      CustomerInfo customerInfo = (await Purchases.purchase(
              PurchaseParams.storeProduct(package.storeProduct)))
          .customerInfo;
      return checkSubscription(customerInfo);
    } on PlatformException catch (e) {
      log("makePurchase $e");

      return null;
    }
  }

  Future<CustomerInfo?> makePurchaseCustom(Package package) async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat custom purchase skipped: Purchases not configured');
        return null;
      }
      CustomerInfo info = (await Purchases.purchase(
              PurchaseParams.storeProduct(package.storeProduct)))
          .customerInfo;
      return info;
    } on PlatformException catch (e) {
      log("makePurchaseCustom: ${e.message}");
      return null;
    }
  }

  Future<bool?> restorePurchase() async {
    try {
      final configured = await Purchases.isConfigured;
      isPurchaseConfig = configured;
      if (!configured) {
        log('RevenueCat restore skipped: Purchases not configured');
        return null;
      }
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      return checkSubscription(restoredInfo);
      // ... check restored customerInfo to see if entitlement is now active
    } on PlatformException catch (e) {
      log(e.toString());
      return null;
      // Error restoring purchases
    }
  }
}
