# Android Build, Packaging & Release Guide — व्यवहार (Vyavahaar)

> **Platform**: Android Mobile (Tier 1 Target)  
> **Package Identifier**: `com.vyavahaar.app` (Target Play Store ID)  
> **Runtime**: Flutter Stable / Dart 3.x  
> **Master Multi-Platform Release Guide**: [`docs/PLATFORM_RELEASE.md`](PLATFORM_RELEASE.md) (Covers Android, iOS, Linux, macOS, and Windows)  
> **Last Updated**: 2026-11-21  

---

## 1. Android Configuration

In the Flutter Android project configuration:
- **Application ID / Package Name**: `com.vyavahaar.app`
- **Application Label**: व्यवहार
- **Version Name**: `1.0.0`
- **Version Code**: `1`
- **Orientation**: `portrait`

### Target SDK Specifications:
- **Minimum SDK (`minSdkVersion`)**: Android 8.0 (API Level 26) — Supports 95%+ of active Android devices in India.
- **Target SDK (`targetSdkVersion`)**: Android 15 (API Level 35) — Complies with Google Play Store 2025/2026 submission mandates.
- **Compile SDK (`compileSdkVersion`)**: Android 15 (API Level 35)
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
