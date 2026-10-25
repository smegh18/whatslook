# Stripe Payment Setup

This app uses Stripe PaymentSheet for coin package purchases when
`STRIPE_PUBLISHABLE_KEY` is configured. The Flutter app never stores or sends a
Stripe secret key.

## Flutter build configuration

Pass the publishable key and merchant details at build time:

```powershell
flutter build apk --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx --dart-define=STRIPE_MERCHANT_COUNTRY_CODE=US
```

For iOS Apple Pay, also pass:

```powershell
--dart-define=STRIPE_APPLE_MERCHANT_ID=merchant.com.your.id
```

## Required backend endpoint

The app calls:

```text
POST /api/misc/createStripeCoinPaymentIntent
```

Headers are the same as other authenticated app APIs:

```text
apikey: ...
AUTHTOKEN: ...
```

Body:

```text
coin_package_id=<backend coin package id>
```

Expected JSON response:

```json
{
  "status": true,
  "paymentIntent": "pi_xxx_secret_xxx",
  "paymentIntentId": "pi_xxx",
  "customer": "cus_xxx",
  "ephemeralKey": "ek_xxx"
}
```

`customer` and `ephemeralKey` are optional if you do not save/reuse customer
payment methods. `paymentIntent` must be the PaymentIntent client secret.

## Backend responsibilities

1. Read `coin_package_id`.
2. Load the active coin package from the database.
3. Calculate the amount on the backend from `coin_plan_price`.
4. Create a Stripe PaymentIntent using the Stripe secret key from `.env`.
5. Return the PaymentIntent client secret to the app.
6. Confirm successful payments with a Stripe webhook before trusting them for
   financial reporting or fulfillment.

Minimum Laravel-style pseudocode:

```php
\Stripe\Stripe::setApiKey(env('STRIPE_SECRET_KEY'));

$package = CoinPackage::where('id', $request->coin_package_id)
    ->where('status', 1)
    ->firstOrFail();

$intent = \Stripe\PaymentIntent::create([
    'amount' => (int) round($package->coin_plan_price * 100),
    'currency' => strtolower(env('STRIPE_CURRENCY', 'usd')),
    'automatic_payment_methods' => ['enabled' => true],
    'metadata' => [
        'user_id' => $request->user()->id,
        'coin_package_id' => $package->id,
    ],
]);

return response()->json([
    'status' => true,
    'paymentIntent' => $intent->client_secret,
    'paymentIntentId' => $intent->id,
]);
```

Install Stripe on the backend with:

```bash
composer require stripe/stripe-php
```

Do not use Stripe secret keys in Flutter.
