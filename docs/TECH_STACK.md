# Technology Stack Specification — व्यवहार (Vyavahaar)

> **Official Target Implementation**: **Flutter + Dart** (Feature-First, MVVM + Repository, Drift ORM, Riverpod, GoRouter)  
> **Legacy / Reference MVP**: **React Native (0.88.1) + Expo (SDK 58.0.26) + TypeScript** (Preserved in full for parity)  
> **Target Scope**: 5 Cross-Platform Operating Systems: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**  
> **Offline Policy**: 100% Offline-First; SQLite is the sole source of truth; zero cloud dependencies.  
> **Last Updated**: 2026-11-21  

---

## 1. Official Target Stack (Flutter & Dart)

Flutter + Dart is the approved production target architecture for Vyavahaar across all 5 operating systems.

### Core Framework & Runtimes:
* **Framework**: Flutter Stable (`>=3.27.0`, targeting Flutter 3.27+/3.29+/3.50+ in CI)
* **Language**: Dart Stable (`>=3.6.0 <4.0.0`, targeting Dart 3.6+/3.7+/3.14+ in CI)
* **Architecture**: Feature-First, MVVM + Repository Pattern, Reactive Dependency Injection.
* **Environmental Note**: When developing inside constrained local environments (e.g. Android Termux Linux aarch64), local `flutter` CLI binaries may not be present in the sandbox PATH. Full Flutter compilation, static analysis (`flutter analyze`), and code generation (`build_runner`) are executed and verified via GitHub Actions CI on Ubuntu runners (`.github/workflows/ci.yml`).

### Package Dependencies (`pubspec.yaml`):

| Category | Package | Version Constraint | Exact Purpose |
| :--- | :--- | :--- | :--- |
| **State Management** | `flutter_riverpod` | `^2.6.1` | Reactive view-model state, dependency injection, and automatic resource disposal. |
| **Routing** | `go_router` | `^14.6.2` | Declarative routing supporting mobile floating pill tabs and desktop split-screen sidebars. |
| **Persistence (ORM)** | `drift` | `^2.20.3` | Type-safe SQLite ORM with compile-time query verification and automatic migrations. |
| **SQLite Engine** | `sqlite3` | `^2.4.6` | Direct C-bindings to modern SQLite engine with WAL mode and foreign key enforcement. |
| **Paths & Files** | `path_provider` | `^2.1.5` | Standardized application document directories across all 5 platforms. |
| **Security & KDF** | `cryptography` | `^2.7.2` | AES-256-GCM authenticated encryption and PBKDF2-HMAC-SHA256 (600,000 iterations) / Argon2id. |
| **Secure Enclave** | `flutter_secure_storage` | `^9.2.2` | Platform-native secure credential storage (Keystore, Keychain, SecretService). |
| **Localization** | `flutter_localizations` | `sdk: flutter` | Official Flutter gen_l10n infrastructure for 22 Scheduled Indian Languages + English. |
| **I18n Formatting** | `intl` | `^0.19.0` | Locale-aware date and number formatting with Indian Rupee symbol (`₹`). |
| **PDF Generation** | `pdf` | `^3.11.1` | Direct vector binary A4 PDF engine with embedded Google Noto TrueType fonts. |
| **Printing / Share** | `printing`, `share_plus` | `^5.13.1`, `^10.1.2` | Native OS printing and system share sheet integration across mobile and desktop. |
| **CSV Export** | `csv` | `^6.0.0` | RFC-4180 compliant CSV serializer with UTF-8 Byte Order Mark (`\uFEFF`). |
| **Code Generation** | `build_runner`, `drift_dev` | `^2.4.13`, `^2.20.3` | Generates type-safe database schemas and DAOs without manual SQL boilerplate. |
| **Linting & QA** | `flutter_lints` | `^5.0.0` | Official Flutter strict lint rules (strict-casts, strict-inference, strict-raw-types). |

---

## 2. Legacy / Reference MVP Implementation (React Native / Expo)

The repository contains an existing, fully working React Native application developed in Phases 1–3.

### Audit Findings & Status:
* **Preservation Policy**: The React Native source code (`app/`, `src/`, `scripts/`, `package.json`) is **100% preserved**. It is not deleted or overwritten.
* **Role**: Serves as the golden functional reference and behavioral benchmark for all database schemas, financial calculations, and UI layouts during Flutter development.
* **Verification**: All 27 automated tests pass consistently via `pnpm test`, with 0 TypeScript compilation errors (`pnpm typecheck`).

### Installed Package Manifest (`package.json`):
* **Core**: `react@19.3.0`, `react-native@0.88.1`, `expo@~58.0.26`, `typescript@~6.0.3`
* **Navigation**: `expo-router@~58.0.32`, `react-native-screens@~4.30.1`, `react-native-safe-area-context@~5.11.1`
* **Database**: `expo-sqlite@^58.0.18` (Schema v3/v4 in WAL mode)
* **Security**: `crypto-js@^4.2.0` (PBKDF2 + AES)
* **Validation**: `zod@^4.6.7`
* **Exports**: `expo-print@~58.0.9`, `expo-sharing@~58.0.23`

---

## 3. Technology Parity & Migration Mapping

| Architecture Layer | Legacy Reference (React Native) | Official Target (Flutter / Dart) | Parity Status |
| :--- | :--- | :--- | :--- |
| **Presentation / UI** | React 19 JSX / NativeWind | Flutter Material 3 (`lib/src/features/`, `lib/src/shared/`) | 1:1 Pixel & Spacing parity |
| **State Management** | React hooks (`useState`, `useCallback`) | Riverpod 2.6 (`lib/src/app/app_providers.dart`) | Fully reactive providers |
| **Database** | SQLite via `expo-sqlite` (Synchronous) | Native SQLite via `drift` ORM (`lib/src/data/database/`) | Binary-compatible schema v4 |
| **Currency Logic** | `src/utils/currency.ts` (Paise math) | `lib/src/core/utils/currency_utils.dart` | Exact integer paise math |
| **Security & KDF** | `crypto-js` (PBKDF2 10k iter in pure JS) | `cryptography` (PBKDF2 600k iter / Argon2id) | Upgraded to OWASP standards |
| **Localization** | Hardcoded Hindi labels | Official `gen_l10n` + ARB for 22 Indian languages | Fully multilingual |
| **PDF Reports** | HTML string to `expo-print` | Direct binary vector generation via `pdf` package | High-resolution embedded TTF |
| **Platform Target** | Android primarily, iOS experimental | Android, iOS, Linux, macOS, Windows | 5-platform native binaries |
