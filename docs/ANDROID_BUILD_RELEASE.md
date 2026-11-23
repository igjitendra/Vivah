# Android Build, Packaging & Release Guide — व्यवहार (Vyavahaar)

> **Platform**: Android Mobile (Tier 1 Target)  
> **Package Identifier**: `com.procsctools.vyavahaar` (Target Play Store ID)  
> **Runtime**: Flutter Stable / Dart 3.x  
> **Master Multi-Platform Release Guide**: [`docs/PLATFORM_RELEASE.md`](PLATFORM_RELEASE.md) (Covers Android, iOS, Linux, macOS, and Windows)  
> **Last Updated**: 2026-11-21  

---

## 1. Android Configuration

The repository tracks a full, dedicated native Android platform project directly under `android/`:
- **Application ID / Package Name**: `com.procsctools.vyavahaar`
- **Application Label**: `व्यवहार` (Vyavahaar)
- **Primary Language**: 100% Kotlin (`.kt`) with Gradle Kotlin DSL (`build.gradle.kts`)
- **Native Architecture**:
  - `MainActivity.kt` extending `FlutterFragmentActivity` with `vyavahaar/security` MethodChannel for hardware-backed privacy.
  - Native home widgets, notification bridges, and local file storage helpers.
  - Zero-network manifest: explicitly removes `INTERNET` and `ACCESS_NETWORK_STATE` permissions.

### Target SDK Specifications:
- **Minimum SDK (`minSdk`)**: Android 5.0 (API Level 21) / Target baseline API 26
- **Target SDK (`targetSdk`)**: Android 15 (API Level 35) — Complies with Google Play Store mandates.
- **Compile SDK (`compileSdk`)**: Android 16 Preview / Android 15 (API Level 36/35) with `android.suppressUnsupportedCompileSdk=36`
- **Supported ABIs**: `arm64-v8a`, `armeabi-v7a`, `x86_64`

---

## 2. Brand Assets & Adaptive Icons

All icons and splash screens follow the official brand palette (Navy `#1F3352` & Terracotta `#C05A2B`):
- `assets/images/icon.png`: 1024x1024 px full-bleed app icon.
- `assets/images/android-icon-foreground.png`: 432x432 px adaptive foreground logo with safe-zone margin.
- `assets/images/android-icon-background.png`: 432x432 px solid Navy `#1F3352` background.
- `assets/images/android-icon-monochrome.png`: Monochrome icon for Android 13+ themed icons.
- `assets/images/splash-icon.png`: Centered brand emblem on `#1F3352` background.

---

## 3. Build & Packaging Commands (Flutter)

### 3.1 Local Development Run
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <android-device-id>
```

### 3.2 Production Android App Bundle (`.aab`) for Google Play
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
Produces an optimized `.aab` file at `build/app/outputs/bundle/release/app-release.aab` ready for upload to Google Play Console.

### 3.3 Standalone Production APK for Direct Sideloading
```bash
flutter build apk --release --split-per-abi
```
Produces optimized APKs per ABI (`app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`) reducing download size for end users.

---

## 4. Google Play Store Pre-Launch Checklist

- [ ] **Data Safety Declaration**:
  - Personal Data: None collected remotely.
  - Financial Data: Stored 100% locally on device in SQLite.
  - Third-Party Sharing: Zero data shared with third parties.
- [ ] **Privacy Policy**: Host a static privacy policy web page stating 100% offline-first local data storage.
- [ ] **Content Rating**: Rated for Everyone (3+) / General audience.
- [ ] **Store Listing Copy (Hindi & English)**:
  - Title: व्यवहार — Digital Family Ledger (बही खाता)
  - Short Description: रिश्तों का हिसाब, हमेशा याद। शादी, तिलक और पारिवारिक आयोजनों का डिजिटल बही खाता।
  - Full Description: Highlight offline-first, PDF reports, AES-256-GCM backup, and zero commercial debt framing.
- [ ] **Screenshots**: High-res screenshots featuring the Redesigned Home Screen, Bahi Khata, Person History, and Hindi PDF preview.

---

## 5. Native Android Runner & Security Hardening (`android/`)

The Android platform runner is fully configured under `android/`:
1. **Runner Configuration**:
   - `android/settings.gradle.kts`: Declares `rootProject.name = "vyavahaar"`.
   - `android/app/build.gradle.kts`: Configured with `namespace = "com.procsctools.vyavahaar"`, `applicationId = "com.procsctools.vyavahaar"`, `minSdk = 26`, `targetSdk = 35`, Java 11 compatibility with core library desugaring (`desugar_jdk_libs:2.1.5`).
2. **Security & Financial Privacy Bridge**:
   - `android/app/src/main/kotlin/com/procsctools/vyavahaar/MainActivity.kt`: Extends `FlutterFragmentActivity` and registers the `vyavahaar/security` MethodChannel.
   - Calling `setSecure(true)` dynamically applies `WindowManager.LayoutParams.FLAG_SECURE` to the window, preventing screenshots and screen recordings while viewing sensitive family financial transactions.
3. **100% Offline Manifest Hardening**:
   - `android/app/src/main/AndroidManifest.xml`: Strips `INTERNET` and `ACCESS_NETWORK_STATE` via `tools:node="remove"`.
   - App label set to `व्यवहार`.
   - Launch background set to Deep Navy `#1F3352` (`@color/brand_navy`) for zero-flicker transitions into Flutter's `SplashScreen`.
4. **Data Backup & Transfer Policies**:
   - `android/app/src/main/res/xml/backup_rules.xml` and `data_extraction_rules.xml`: Exclude cloud uploads while permitting secure local device-to-device transfers of `vyavahaar.db` and preferences.

---

## 6. Automated Keystore Signing & 'App not installed' Resolution

### 6.1 Automated v1 + v2 Signature Scheme in CI
To eliminate the Android "App not installed" (`INSTALL_PARSE_FAILED_NO_CERTIFICATES` / signature mismatch) error:
- `.github/workflows/build-apk.yml` automatically generates an RSA-2048 upload keystore and `key.properties`.
- `scripts/configure-android-sdk.py` injects `signingConfigs.release` configured with `v1SigningEnabled true` and `v2SigningEnabled true`.
- Post-build step verifies both `app-debug.apk` and `app-release.apk` with `jarsigner -verify` before publishing release assets, guaranteeing valid certificates.

### 6.2 Troubleshooting on Device (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)
- When updating from an earlier test build, Android requires that the existing installation be uninstalled first if the cryptographic certificate or package name has changed.
- Users must uninstall the old version from **Settings ➔ Apps** before installing the newly signed APK.
