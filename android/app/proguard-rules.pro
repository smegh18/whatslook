# flutter_stripe includes optional push-provisioning bridge code, but the app does
# not package Stripe's push-provisioning SDK classes. Suppress R8 missing-class
# warnings for those optional references.
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider

# ── ZEGO Express SDK ──
# The native lib loads im.zego.connection.ClassLoaderHelper* via JNI.
# R8 strips them because there are no static Java references.
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# ── Flutter ──
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ── Google Mobile Ads ──
-keep class com.google.android.gms.ads.** { *; }

# ── Geolocator ──
-keep class com.baseflow.geolocator.** { *; }

# ── RevenueCat ──
-keep class com.revenuecat.purchases.** { *; }

