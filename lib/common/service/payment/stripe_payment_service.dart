import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shortzz/common/service/api/gift_wallet_service.dart';
import 'package:shortzz/utilities/const_res.dart';

class StripeCoinPaymentResult {
  final String? paymentIntentId;

  StripeCoinPaymentResult({this.paymentIntentId});
}

class StripePaymentService {
  StripePaymentService._();

  static final StripePaymentService shared = StripePaymentService._();

  bool get isConfigured => stripePublishableKey.isNotEmpty;

  Future<StripeCoinPaymentResult?> payForCoinPackage({
    required int coinPackageId,
    required int amountCents,
  }) async {
    if (!isConfigured) {
      throw Exception('Stripe publishable key is not configured.');
    }

    final data = await GiftWalletService.instance
        .createStripeCoinPaymentIntent(coinPackageId: coinPackageId, amountCents: amountCents);

    final clientSecret = _firstString(data, const [
      'paymentIntent',
      'payment_intent',
      'paymentIntentClientSecret',
      'payment_intent_client_secret',
      'clientSecret',
      'client_secret',
    ]);

    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Stripe payment intent client secret is missing.');
    }

    final customerId = _firstString(data, const ['customer', 'customer_id']);
    final ephemeralKey = _firstString(data, const [
      'ephemeralKey',
      'ephemeral_key',
      'customerEphemeralKeySecret',
      'customer_ephemeral_key_secret',
    ]);

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: stripeMerchantDisplayName,
        customerId: customerId,
        customerEphemeralKeySecret: ephemeralKey,
        returnURL: stripeReturnUrl,
        style: ThemeMode.system,
        applePay: stripeAppleMerchantIdentifier.isNotEmpty
            ? PaymentSheetApplePay(
                merchantCountryCode: stripeMerchantCountryCode,
              )
            : null,
        googlePay: PaymentSheetGooglePay(
          merchantCountryCode: stripeMerchantCountryCode,
          testEnv: stripeGooglePayTestEnv,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    return StripeCoinPaymentResult(
      paymentIntentId: _firstString(data, const [
        'paymentIntentId',
        'payment_intent_id',
        'id',
      ]),
    );
  }

  String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      return _firstString(nestedData, keys);
    }
    return null;
  }
}
