import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/extensions/common_extension.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/gift_wallet_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/service/payment/stripe_payment_service.dart';
import 'package:shortzz/common/service/subscription/subscription_manager.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/model/user_model/user_model.dart';

class CoinWalletScreenController extends BaseController {
  Rx<User?> myUser = Rx<User?>(null);
  RxList<Package> offerings = <Package>[].obs;

  Setting? get settings => SessionManager.instance.getSettings();
  RxList<CoinPlan> coinPlans = <CoinPlan>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
    fetchOfferings();
  }

  void fetchData() {
    myUser.value = SessionManager.instance.getUser();
  }

  void fetchOfferings() {
    if (settings?.coinPackages == null) return;

    // Always load RevenueCat offerings if available
    List<Package> items = SubscriptionManager.shared.offering;
    offerings.addAll(items);

    for (var data in settings!.coinPackages!) {
      if (data.status == 0) continue;

      // Try to find a matching RevenueCat product
      Package? matchedPackage;
      for (var element in items) {
        if ([data.appstoreProductId, data.playStoreProductId]
            .contains(element.storeProduct.identifier)) {
          matchedPackage = element;
          break;
        }
      }

      if (matchedPackage != null) {
        // Use RevenueCat price string (localized from store)
        coinPlans.add(CoinPlan(
          data.coinAmount ?? 0,
          data.id ?? -1,
          matchedPackage.storeProduct.identifier,
          matchedPackage.storeProduct.priceString,
          (matchedPackage.storeProduct.price * 100).toInt(),
        ));
      } else {
        // Fallback: use admin-set price from backend (Stripe or direct display)
        coinPlans.add(CoinPlan(
          data.coinAmount ?? 0,
          data.id ?? -1,
          data.playStoreProductId ?? data.appstoreProductId ?? '${data.id}',
          (data.coinPlanPrice ?? 0).currencyFormat,
          (data.coinPlanPrice ?? 0).toInt() * 100,
        ));
      }
    }
  }

  void onPurchase(CoinPlan offer) async {
    showLoader(barrierDismissible: false);
    try {
      User? purchasedUser;

      if (StripePaymentService.shared.isConfigured) {
        // Pay via Stripe
        final result = await StripePaymentService.shared.payForCoinPackage(
          coinPackageId: offer.coinPackageId,
          amountCents: offer.rawPrice,
        );
        if (result == null) return;
        purchasedUser = await GiftWalletService.instance.buyCoins(
          id: offer.coinPackageId,
          purchasedAt: DateTime.now().millisecondsSinceEpoch.toString(),
          transactionCode: result.paymentIntentId,
        );
      } else if (offerings.any(
          (element) => element.storeProduct.identifier == offer.id)) {
        // Pay via RevenueCat (in-app purchase)
        Package package = offerings.firstWhere(
            (element) => element.storeProduct.identifier == offer.id);
        final value =
            await SubscriptionManager.shared.makePurchaseCustom(package);
        if (value == null) return;
        String isoTime = value.nonSubscriptionTransactions.last.purchaseDate;
        DateTime dt = DateTime.parse(isoTime);
        int millis = dt.millisecondsSinceEpoch;
        purchasedUser = await GiftWalletService.instance.buyCoins(
          id: offer.coinPackageId,
          purchasedAt: millis.toString(),
        );
      } else {
        // No payment gateway configured
        stopLoader();
        showSnackBar('Payment gateway is not configured. Please contact support.');
        return;
      }

      if (purchasedUser != null) {
        User? user = await UserService.instance
            .fetchUserDetails(userId: myUser.value?.id);
        if (user != null) {
          myUser.value = user;
          SessionManager.instance.setUser(myUser.value);
        }
      }
      stopLoader();
    } catch (e) {
      stopLoader();
      showSnackBar(e.toString());
    }
  }
}

class CoinPlan {
  int coin;
  int coinPackageId;
  String id;
  String priceString;
  int rawPrice;

  CoinPlan(this.coin, this.coinPackageId, this.id, this.priceString, this.rawPrice);
}
