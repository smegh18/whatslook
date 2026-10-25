# Firebase Auth (Android) troubleshooting

This repo uses Firebase Authentication (email/password, phone OTP) and Google Sign-In.

## Symptoms

- Phone OTP / sign-up fails with:
  - `This request is missing a valid app identifier, meaning that play integrity checks, and recaptcha checks were unsuccessful...`
- Phone OTP fails after Play Integrity returns with:
  - `SMS verification code request failed: unknown status code: 17010`
  - `We have blocked all requests from this device due to unusual activity. Try again later.`
- Google sign-in looks stuck / fails after choosing an account (often a configuration error).

## Most common root cause

Your Android app signature (SHA-1 / SHA-256) registered in Firebase does **not** match the keystore used to sign the APK/AAB you are running.

This can happen when:

- You changed the keystore used for release builds.
- You are testing a **debug** build but Firebase only has the **release** SHA(s) registered (or vice-versa).
- You are testing a Play Store build and didn’t add the **Google Play App Signing** SHA(s).

## Fix checklist (Firebase Console)

1. Firebase Console → **Project settings** → **Your apps** → **Android app**
2. Ensure the **package name** matches `applicationId` in `android/app/build.gradle`.
3. Add all relevant **SHA certificate fingerprints**:
   - Debug keystore SHA-1/SHA-256 (for `flutter run` / debug builds)
   - Upload/release keystore SHA-1/SHA-256 (for locally built release APK/AAB)
   - Google Play App Signing SHA-1/SHA-256 (if distributing via Play Store)
4. Download a fresh `google-services.json` and replace:
   - `android/app/google-services.json`

## Current local fingerprints

The checked-in `google-services.json` already contains the local debug and upload/release **SHA-1** hashes. For Play Integrity, also verify these **SHA-256** fingerprints are registered in Firebase Console:

- Debug SHA-256: `55:85:E2:82:B8:54:E3:31:1B:0C:58:17:69:23:06:C2:05:5C:AB:5C:6F:86:B2:7D:6A:EF:3E:8B:33:B6:36:C5`
- Upload/release SHA-256: `4B:2C:FE:DB:AA:22:AD:91:FE:C4:F5:DB:19:57:C3:B6:A6:24:96:7F:A8:1A:F8:5B:C8:83:94:9C:E2:F9:18:E0`

If the APK/AAB is installed from Google Play, also add the **App signing key certificate** SHA-1 and SHA-256 from Play Console -> Setup -> App integrity. The upload key above is not enough for Play Store installs.

## Firebase SMS blocked / 17010

Status `17010` means Firebase Auth has temporarily rate-limited SMS verification for the device, project, IP, or phone number. In this case Play Integrity may already be working; Firebase is refusing to send another SMS.

To unblock testing:

- Wait before trying again. Repeated attempts extend the block.
- Try a different physical device, network, and phone number.
- For development, add Firebase Auth test phone numbers in Firebase Console -> Authentication -> Sign-in method -> Phone -> Phone numbers for testing.
- Check Firebase Console -> Authentication -> Sign-in method -> Phone for SMS region policy, SMS quota, billing, and abuse/rate-limit settings.

## Get SHA-1 / SHA-256 (Windows / PowerShell)

### Debug keystore (local)

```powershell
& "C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot\bin\keytool.exe" `
  -list -v `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -alias androiddebugkey `
  -storepass android `
  -keypass android | Select-String "SHA1:|SHA256:"
```

### Upload/release keystore (in this repo)

Keystore: `android/app/upload-keystore.jks`  
Alias/passwords are in `android/key.properties`.

```powershell
& "C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot\bin\keytool.exe" `
  -list -v `
  -keystore "android/app/upload-keystore.jks" `
  -alias upload `
  -storepass <storePassword from android/key.properties> | Select-String "SHA1:|SHA256:"
```

## Notes

- After replacing `google-services.json`, run `flutter clean` and rebuild.
- If you enforce Play Integrity / App Check rules, make sure your app is properly linked/configured in Google Play and Firebase.
