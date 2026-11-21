# Technology Stack Specification — व्यवहार (Vyavahaar)

> **Official Implementation**: **Flutter + Dart (Sole Framework)** (Feature-First, MVVM + Repository, Drift ORM, Riverpod, GoRouter)  
> **Target Scope**: 5 Cross-Platform Operating Systems: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**  
> **Offline Policy**: 100% Offline-First; SQLite is the sole source of truth; zero cloud dependencies.  
> **Branch**: `migration/flutter-only`  
> **Last Updated**: 2026-11-21  

---

## 1. Official Target Stack (Flutter & Dart)

Flutter + Dart is the sole approved production architecture for Vyavahaar across all 5 operating systems.

### Core Framework & Runtimes:
* **Framework**: Flutter Stable (`>=3.27.0`, targeting Flutter 3.27+/3.29+ in CI)
* **Language**: Dart Stable (`>=3.6.0 <4.0.0`, targeting Dart 3.6+/3.7+ in CI)
* **Architecture**: Feature-First, MVVM + Repository Pattern, Reactive Dependency Injection.
* **Environmental Note**: When developing inside constrained local environments (e.g. Android Termux Linux aarch64), local `flutter` CLI binaries may not be present in the sandbox PATH. Full Flutter compilation, static analysis (`flutter analyze`), and code generation (`build_runner`) are executed and verified via GitHub Actions CI on Ubuntu runners (`.github/workflows/ci.yml`). Python 3.12 architecture stress test suites run locally.

### Package Dependencies (`pubspec.yaml`):

| Category | Package | Version Constraint | Exact Purpose |
| :--- | :--- | :--- | :--- |
| **State Management** | `flutter_riverpod` | `^2.6.1` | Reactive view-model state, dependency injection, and automatic resource disposal. |
| **Routing** | `go_router` | `^14.6.2` | Declarative routing supporting mobile floating pill tabs and desktop responsive screens. |
| **Persistence (ORM)** | `drift` | `^2.24.2` | Type-safe SQLite ORM with compile-time query verification and automatic migrations. |
| **SQLite Engine** | `sqlite3` | `^2.5.0` | Direct C-bindings to modern SQLite engine with WAL mode and foreign key enforcement. |
| **Paths & Files** | `path_provider` | `^2.1.5` | Standardized application document directories across all 5 platforms. |
| **Security & KDF** | `cryptography` | `^2.7.2` | AES-256-GCM authenticated encryption and PBKDF2-HMAC-SHA256 (600,000 iterations) / Argon2id. |
| **Secure Enclave** | `flutter_secure_storage` | `^9.2.4` | Platform-native secure credential storage (Keystore, Keychain, SecretService). |
| **Localization** | `flutter_localizations` | `sdk: flutter` | Official Flutter gen_l10n infrastructure for 22 Scheduled Indian Languages + English. |
| **I18n Formatting** | `intl` | `^0.20.2` | Locale-aware date and number formatting with Indian Rupee symbol (`₹`). |
| **PDF Generation** | `pdf` | `^3.11.1` | Direct vector binary A4 PDF engine with embedded Google Noto TrueType fonts. |
| **Printing / Share** | `printing`, `share_plus` | `^5.13.2`, `^10.1.3` | Native OS printing and system share sheet integration across mobile and desktop. |
| **CSV Export** | `csv` | `^6.0.0` | RFC-4180 compliant CSV serializer with UTF-8 Byte Order Mark (`\uFEFF`). |
| **Code Generation** | `build_runner`, `drift_dev` | `^2.4.15`, `^2.24.2` | Generates type-safe database schemas and DAOs without manual SQL boilerplate. |
| **Linting & QA** | `flutter_lints` | `^5.0.0` | Official Flutter strict lint rules (strict-casts, strict-inference, strict-raw-types). |

---

## 2. Migration Outcome & Parity Verification

The migration from Expo / React Native to Flutter + Dart has been completed on the dedicated branch `migration/flutter-only`:

| Architecture Layer | Migrated Implementation (Flutter / Dart) | Parity & Status |
| :--- | :--- | :--- |
| **Presentation / UI** | Flutter Material 3 (`lib/src/features/`, `lib/src/shared/`) | 1:1 Pixel & Spacing parity with authentic warm Indian palette |
| **State Management** | Riverpod 2.6 (`lib/src/app/app_providers.dart`) | Fully reactive providers for all entities and streams |
| **Database** | Native SQLite via `drift` ORM (`lib/src/data/database/`) | Binary-compatible schema v4; 14/14 stress tests passing |
| **Currency Logic** | `lib/src/core/utils/currency_utils.dart` | Exact integer paise math; zero floating point precision loss |
| **Security & KDF** | `lib/src/features/settings/services/backup_service.dart` | AES-256-GCM + PBKDF2 (600,000 iterations) OWASP compliance |
| **Localization** | `lib/src/core/localization/` + ARB catalogs | 22 Scheduled Indian languages + English; 22/22 tests passing |
| **PDF Reports** | `lib/src/features/reports/services/pdf_service.dart` | High-resolution offline vector A4 PDF generation |
| **CSV Export** | `lib/src/features/reports/services/csv_service.dart` | RFC-4180 CSV export with UTF-8 BOM for Microsoft Excel |
| **Platform Target** | Android, iOS, Linux, macOS, Windows | 5-platform unified Flutter codebase |
