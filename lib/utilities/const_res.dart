const String apiURL = String.fromEnvironment('API_URL',
    defaultValue: 'https://login.whatslook.com/api/');
const String baseURL = String.fromEnvironment('BASE_URL',
    defaultValue: 'https://login.whatslook.com/');

/// API key required by backend `CheckHeader` middleware.
/// Override per build with: `--dart-define=API_KEY=...`
const String apiKey = String.fromEnvironment('API_KEY', defaultValue: 'retry123');
const String notificationTopic = 'shortzz';

const String revenueCatAndroidApiKey = '';
const String revenueCatAppleApiKey = '';

/// Stripe publishable key for client-side PaymentSheet.
/// Keep the secret key on your backend only.
/// Override per build with: `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_...`
const String stripePublishableKey =
    String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: 'pk_test_51Tla1XJtar6xmk7MAppv7QEQrz86NzQUZRjOf61WJCx0OXpW04oHEy4ttAkWsxwGIQoQohTAx0GxkGYaoZ48k1WS00tSaRSCAa');
const String stripeMerchantDisplayName = String.fromEnvironment(
  'STRIPE_MERCHANT_DISPLAY_NAME',
  defaultValue: 'Whatslook',
);
const String stripeMerchantCountryCode =
    String.fromEnvironment('STRIPE_MERCHANT_COUNTRY_CODE', defaultValue: 'US');
const String stripeAppleMerchantIdentifier =
    String.fromEnvironment('STRIPE_APPLE_MERCHANT_ID', defaultValue: '');
const bool stripeGooglePayTestEnv =
    bool.fromEnvironment('STRIPE_GOOGLE_PAY_TEST_ENV', defaultValue: true);
const String stripeReturnUrl = 'whatslookstripe://redirect';
