# iOS App Store Build & Deploy Guide — Whatslook (Shortzz)

## Prerequisites

- **Mac** with macOS (required; iOS cannot be built on Windows)
- **Xcode** (latest from Mac App Store)
- **Apple Developer account** ($99/year) — [developer.apple.com](https://developer.apple.com)
- **Flutter** installed and `flutter doctor` passing for iOS

---

## 1. One-time setup on Mac

### Install Xcode & tools
```bash
# Install Xcode from App Store, then:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Flutter iOS setup
```bash
cd /path/to/Whatslook
flutter pub get
flutter doctor
# Ensure "Xcode" and "iOS toolchain" are OK
```

### Open in Xcode and configure signing
1. Open the iOS project:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select the **Runner** project → **Runner** target.
3. **Signing & Capabilities**:
   - Check **Automatically manage signing**.
   - Choose your **Team** (Apple Developer account).
   - Set **Bundle Identifier** (e.g. `com.retrytech.app.shortzz.v2` — must match App Store Connect).
4. Repeat for any other targets (e.g. extensions) if present.

---

## 2. App Store Connect setup (one-time)

1. Go to [App Store Connect](https://appstoreconnect.apple.com).
2. **My Apps** → **+** → **New App**:
   - Platform: iOS
   - Name: Whatslook (or Shortzz)
   - Bundle ID: same as in Xcode (e.g. `com.retrytech.app.shortzz.v2`)
   - SKU: e.g. `whatslook-ios`
3. Fill in **App Information**, **Pricing**, **App Privacy**, etc., as required.

---

## 3. Build the release IPA/archive

### Option A: Build archive from Xcode (recommended for first upload)

1. In Xcode: **Product** → **Scheme** → **Runner**.
2. Set destination: **Any iOS Device (arm64)** (no simulator).
3. **Product** → **Archive**.
4. When Organizer opens: select the archive → **Distribute App**.
5. Choose **App Store Connect** → **Upload** → follow the wizard (signing, options, upload).

### Option B: Build from command line

```bash
cd /path/to/Whatslook

# Clean and get dependencies
flutter clean
flutter pub get

# Build release (version from pubspec.yaml: 1.0.0+1)
flutter build ipa
```

Output is under: `build/ios/ipa/`. You can then upload this IPA with:

- **Transporter** (Mac App Store): open the `.ipa` and deliver to App Store Connect, or  
- **Xcode**: **Window** → **Organizer** → **Distribute App** and choose the built IPA if applicable.

To override version/build:
```bash
flutter build ipa --build-name=1.0.0 --build-number=2
```

---

## 4. After upload

1. In **App Store Connect** → your app → **TestFlight** (optional: add internal/external testers).
2. When ready: go to the **iOS App** → **+** to create a version (e.g. 1.0.0), select the build you uploaded, add **What’s New**, screenshots, description, etc.
3. Submit for **App Review**.

---

## 5. If you don’t have a Mac: use CI

You can build and upload from the cloud:

- **Codemagic** — [codemagic.io](https://codemagic.io) (Flutter-friendly, can sign and upload to App Store).
- **GitHub Actions** — use a `macos-latest` runner and run `flutter build ipa` plus upload steps.
- **Codemagic / GitHub Actions** can store your Apple credentials and signing certificates securely and upload to App Store Connect.

---

## Quick reference

| Step              | Command / Action                          |
|-------------------|-------------------------------------------|
| Check environment | `flutter doctor`                          |
| Build IPA         | `flutter build ipa`                       |
| Custom version    | `flutter build ipa --build-name=1.0.0 --build-number=2` |
| Open iOS project  | `open ios/Runner.xcworkspace`             |
| Upload            | Xcode Organizer or Transporter app        |

Your app’s display name in `Info.plist` is **Shortzz**; ensure the name in App Store Connect matches what you want on the store (e.g. Whatslook or Shortzz).
