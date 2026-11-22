# Cross-Platform Packaging & Release Specifications — व्यवहार (Vyavahaar)

> **Document Scope**: Build, Packaging, Signing & Distribution for **Android, iOS, Linux, macOS, and Windows**  
> **Status**: Approved Release Blueprint  
> **Last Updated**: 2026-11-21

---

## 1. Multi-Platform Release Matrix

| Platform | Package Format | Distribution Channel | Signing & Security Requirements | Target Phase |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | `.aab` (Bundle), `.apk` (Sideload) | Google Play Store, Direct APK download | Android Keystore (v2/v3 signature), Google Play App Signing | Phase 5 (Current) |
| **iOS** | `.ipa` (Archive) | Apple App Store, TestFlight | Apple Developer ID, Provisioning Profile, App Store Connect | Phase 5 |
| **Linux** | `AppImage`, `Flatpak`, `.deb` | Flathub, Snap Store, GitHub Releases | GPG Signature, AppStream metadata | Post-MVP Desktop |
| **macOS** | `.dmg`, `.app` | Mac App Store, Direct DMG Download | Apple Developer ID Application certificate, Apple Notarization (`notarytool`) | Post-MVP Desktop |
| **Windows** | `.msix`, `.exe` (Inno Setup) | Microsoft Store, Direct Installer | Authenticode Code Signing Certificate (EV or standard) | Post-MVP Desktop |

---

## 2. Platform-Specific Build Specifications

### 2.1 Android Build & Release
- **Package Identifier**: `com.vyavahaar.app`
- **Output Formats**:
  - Production App Bundle: `app-release.aab` (uploaded to Google Play Console).
  - Standalone Testing APK: `app-release.apk` (for direct offline sideloading on user devices).
- **Compilation Tooling**: Flutter Gradle (`flutter build appbundle --release` or `flutter build apk --release`).
- **Permissions**: Zero internet permissions requested.

### 2.2 iOS Build & Release
- **Bundle Identifier**: `com.vyavahaar.app`
- **Minimum iOS Version**: iOS 15.0+ (supported by Flutter stable).
- **Output Format**: Signed `.ipa` archive via `flutter build ipa --release` or Xcode.
- **App Store Review Compliance**:
  - Offline functional verification (App operates 100% without Wi-Fi/cellular).
  - Privacy Nutrition Labels: "Data Not Collected" (all records stored locally in private SQLite sandbox).

### 2.3 Linux Desktop Packaging
- **Target Distributions**: Ubuntu/Debian, Fedora/RHEL, Arch Linux.
- **Recommended Formats**:
  1. **AppImage**: Single self-contained executable running on any modern Linux distribution without root installation.
  2. **Flatpak**: Sandboxed package distributed via Flathub with isolated local storage permissions (`~/.var/app/com.vyavahaar.app/`).
- **Desktop Entry**: Standard `com.vyavahaar.app.desktop` file with HiDPI icon and Hindi localization.

### 2.4 macOS Desktop Packaging
- **Target Architectures**: Apple Silicon (`arm64` - M1/M2/M3/M4) and Intel (`x86_64`) via Universal Binary.
- **Packaging Format**: Signed `.dmg` with drag-to-Applications installer.
- **Security & Gatekeeper**:
  - Hardened Runtime enabled.
  - Codesigned with valid Apple Developer ID.
  - Submitted to Apple Notary Service (`xcrun notarytool submit`) to ensure prompt Gatekeeper approval without security warnings.

### 2.5 Windows Desktop Packaging
- **Target Versions**: Windows 10 (Version 1809+) and Windows 11 (64-bit).
- **Packaging Formats**:
  1. **MSIX**: Modern, clean install/uninstall package for Windows 10/11 and Microsoft Store.
  2. **EXE Installer**: Standard Inno Setup installer for enterprise and offline PC setups.
- **Storage Sandbox**: Stored in `%LocalAppData%\Vyavahaar\` or `%APPDATA%\Vyavahaar\`.

---

## 3. Unified Cross-Platform Versioning

All five platform releases follow strict Semantic Versioning (`MAJOR.MINOR.PATCH`):
- **App Version**: `1.0.0`
- **Database Schema Version**: `4` (Must match across all 5 platforms).
- **Backup Envelope Version**: `4` (Guarantees seamless JSON backup interchange between Android, iOS, Linux, macOS, and Windows).
