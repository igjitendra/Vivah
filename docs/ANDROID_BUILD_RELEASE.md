# Android Build, Packaging & Release Guide — व्यवहार (Vyavahaar)

> **Platform**: Android Mobile  
> **Package Identifier**: `com.vyavahaar.app` (Target Play Store ID)  
> **Runtime**: React Native 0.88.1 / Expo SDK 58  
> **Last Updated**: 2026-11-21

---

## 1. Android Configuration (`app.json`)

```json
{
  "expo": {
    "name": "व्यवहार",
    "slug": "vyavahaar",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/images/icon.png",
    "scheme": "vyavahaar",
    "userInterfaceStyle": "light",
    "android": {
      "package": "com.vyavahaar.app",
      "versionCode": 1,
      "adaptiveIcon": {
        "backgroundColor": "#1F3352",
        "foregroundImage": "./assets/images/android-icon-foreground.png",
        "backgroundImage": "./assets/images/android-icon-background.png",
        "monochromeImage": "./assets/images/android-icon-monochrome.png"
      },
      "predictiveBackGestureEnabled": false
    },
    "plugins": [
      "expo-router",
      [
        "expo-splash-screen",
        {
          "image": "./assets/images/splash-icon.png",
          "resizeMode": "contain",
          "backgroundColor": "#1F3352"
        }
      ],
      "expo-sharing"
    ]
  }
}
```

---

## 2. SDK & Target Requirements

- **Minimum SDK (minSdkVersion)**: Android 8.0 (API Level 26) — Supports 95%+ of active Android devices in India.
- **Target SDK (targetSdkVersion)**: Android 15 (API Level 35) — Complies with Google Play Store 2025/2026 requirements.
- **Architectures Supported**: `arm64-v8a`, `armeabi-v7a`, `x86_64`.

---

## 3. Brand Assets & Adaptive Icons

All icons and splash screens follow the official brand palette (Navy `#1F3352` & Terracotta `#C05A2B`):
- `assets/images/icon.png`: 1024x1024 px full-bleed app icon.
- `assets/images/android-icon-foreground.png`: 432x432 px adaptive foreground logo with safe-zone margin.
- `assets/images/android-icon-background.png`: 432x432 px solid Navy `#1F3352` background.
- `assets/images/android-icon-monochrome.png`: Monochrome icon for Android 13+ themed icons.
- `assets/images/splash-icon.png`: Centered brand emblem on `#1F3352` background.

---

## 4. Build Profiles & Generation

### 4.1 Development Testing (Expo Go)
For daily rapid development:
```bash
pnpm start
```
Scan the terminal QR code in the Expo Go app.

### 4.2 Production Android App Bundle (`.aab`) via EAS
```bash
# 1. Install EAS CLI globally if needed
pnpm dlx eas-cli login

# 2. Configure build profile in eas.json
pnpm dlx eas-cli build --platform android --profile production
```
Produces an optimized `.aab` file ready for upload to Google Play Console.

### 4.3 Standalone Production APK for Direct Sideloading
```bash
pnpm dlx eas-cli build --platform android --profile preview
```

---

## 5. Google Play Store Pre-Launch Checklist

- [ ] **Data Safety Declaration**:
  - Personal Data: None collected remotely.
  - Financial Data: Stored 100% locally on device in SQLite.
  - Third-Party Sharing: Zero data shared with third parties.
- [ ] **Privacy Policy**: Host a static privacy policy web page stating 100% offline-first local data storage.
- [ ] **Content Rating**: Rated for Everyone (3+) / General audience.
- [ ] **Store Listing Copy (Hindi & English)**:
  - Title: व्यवहार — Digital Family Ledger (बही खाता)
  - Short Description: रिश्तों का हिसाब, हमेशा याद। शादी, तिलक और पारिवारिक आयोजनों का डिजिटल बही खाता।
  - Full Description: Highlight offline-first, PDF reports, AES-256 backup, and zero commercial debt framing.
- [ ] **Screenshots**: High-res screenshots featuring the Redesigned Home Screen, Bahi Khata, Person History, and Hindi PDF preview.
