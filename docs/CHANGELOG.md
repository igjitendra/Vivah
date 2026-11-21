# Changelog — व्यवहार (Vyavahaar)

> All notable changes to this project are documented in this file in chronological order.  
> Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.4.0] — 2026-11-21

### Added
- **Complete Expo / React Native Removal & Flutter-Only Migration**:
  - Dedicated migration branch: `migration/flutter-only`.
  - Migrated and created all feature presentation screens in Flutter:
    - `LedgerScreen`: Bahi-Khata ledger list with Mila/Diya direction filtering, live search, and rupee cards.
    - `PeopleListScreen` & `AddPersonScreen`: Contacts directory, search by name/phone/village, and person creation.
    - `PersonDetailScreen`: Relative profile with Mila/Diya stats and chronological transaction history.
    - `EventsListScreen` & `AddEventScreen`: Family ceremonies list and event creation.
    - `EventDetailScreen`: Event ceremony summary, total received/given for the event, and guest transactions list.
    - `AddEntryScreen`: Record transaction form with person & event dropdowns, direction toggle, rupee-to-paise conversion, and atomic save.
    - `EntryDetailScreen`: Transaction detail, edit/cancel/soft-archive actions.
    - `ReportsScreen`: PDF & CSV reports triggers.
    - `SettingsScreen`: Language selection, reports, reminders, encrypted backup, restore picker, and privacy guarantee.
    - `RemindersScreen`: Upcoming ceremonies and planned transactions management with completion toggles.
  - Implemented all export and security services in Flutter:
    - `PdfService`: High-resolution A4 Devanagari PDF reports (Complete Ledger, Received Only, Given Only) with embedded Noto Sans Devanagari fonts via `pdf` and `printing`.
    - `CsvService`: RFC-4180 CSV export with UTF-8 BOM (`\uFEFF`) for Microsoft Excel compatibility.
    - `BackupService`: Authenticated backup & restore using AES-256-GCM + OWASP KDF (PBKDF2-HMAC-SHA256 with 600,000 iterations), unique 128-bit salt and 12-byte nonce, envelope v4, and atomic transaction rollback.
  - Connected declarative routing via GoRouter (`lib/src/app/router/app_router.dart`):
    - 5 navigation tabs (`/` Dashboard, `/bahi` Bahi Khata, `/events` Events, `/people` People, `/settings` Settings).
    - Subroutes: `/entry/new`, `/entry/:id`, `/person/new`, `/person/:id`, `/event/new`, `/event/:id`, `/reports`, `/language`, `/reminders`.

### Removed
- **Obsolete Expo, React Native & TypeScript Mobile Runtime**:
  - Completely deleted `app/` (Expo file-based router pages) and `src/` (old React Native code).
  - Completely deleted `components/`, `constants/`, and `dist/`.
  - Completely removed root JavaScript tooling: `package.json`, `pnpm-lock.yaml`, `tsconfig.json`, `app.json`, `expo-env.d.ts`, and `.expo/`.
  - Removed legacy React Native test scripts; preserved standalone Python SQLite and multilingual test suites.
  - Updated CI workflow (`.github/workflows/ci.yml`): removed `react-native-verify` job; enhanced `flutter-verify` job with Python architecture tests.

## [1.3.0] — 2026-11-21

### Changed
- **Final Technology Stack Validation & Documentation Correction**:
  - Formally approved **Flutter + Dart** as the official target implementation for all 5 platforms (Android, iOS, Linux, macOS, Windows).
  - Explicitly classified the verified **React Native (0.88.1) + Expo SDK 58** codebase as a preserved **Legacy Reference MVP** for functional and schema parity.
  - Updated Flutter target SDK constraint to modern stable (`>=3.27.0`) and Dart (`>=3.6.0 <4.0.0`) in `pubspec.yaml` and `.github/workflows/ci.yml`.
  - Documented exact local environment reality: Termux on Android lacks local Flutter CLI; verification is automated via GitHub Actions CI on Ubuntu runners.
  - Published comprehensive cryptographic architecture in `docs/SECURITY.md`:
    - Authenticated encryption: AES-256-GCM with unique CSPRNG nonce per operation.
    - OWASP password-based key derivation alignment: Argon2id (primary) or PBKDF2-HMAC-SHA256 with 600,000 iterations.
    - Empirical device benchmarks: Native C/Dart PBKDF2 600,000 iterations executes in ~210ms vs pure JavaScript taking 854ms for only 10,000 iterations.
    - Zero hardcoded keys policy and versioned backup envelope format v4.
  - Clarified database benchmarks: distinguished in-memory indexed queries (3.43ms for 10K rows) from physical flash disk write barriers.
  - Updated `AGENTS.md`, `README.md`, `docs/TECH_STACK.md`, `docs/ARCHITECTURE.md`, `docs/PLATFORM_STRATEGY.md`, `docs/DECISIONS.md`, and `docs/PROJECT_STATUS.md`.

## [1.2.5] — 2026-11-21

### Added
- **Complete Indian Multilingual Localization & Internationalization Architecture (Step 2.5)**:
  - Central `LanguageRegistry` covering all 22 Scheduled Indian Languages of the Eighth Schedule of the Constitution of India + English fallback.
  - Extensible language registration API (`LanguageRegistry.instance.registerLanguage()`) to dynamically support regional languages and dialects (Bhojpuri, Rajasthani, Tulu, Khasi, Garo, Mizo, etc.).
  - BCP 47 compliant locale modeling with script distinction (`Deva`, `Beng`, `Guru`, `Gujr`, `Orya`, `Taml`, `Telu`, `Knda`, `Mlym`, `Olck`, `Mtei`, `Arab`).
  - Right-to-Left (RTL) engine supporting Urdu, Kashmiri Arabic, and Sindhi Arabic with mixed-direction numeral and currency isolation.
  - Dedicated documentation suite:
    - `docs/LOCALIZATION_I18N.md`: Complete architecture specification.
    - `docs/LANGUAGE_SUPPORT_MATRIX.md`: 22-language matrix with ISO tags, scripts, direction, fonts, and review statuses.
    - `docs/TRANSLATION_WORKFLOW.md`: 7-stage QA lifecycle and cultural financial terminology guidelines.
    - `docs/FONT_AND_SCRIPT_SUPPORT.md`: Noto font mapping, OpenType Indic shaping, and licensing.
  - Official Flutter localization setup via `l10n.yaml` with template `app_en.arb`, `app_hi.arb`, and `app_ur.arb` featuring ICU pluralization.
  - `LocaleFormatter` for display-only Indian Rupee formatting (`₹1,100`) from pure integer paise and locale-adapted dates.
  - `UnicodeSearchUtils` implementing NFC normalization and matra-safe substring matching across 12 Indic writing systems.
  - `LanguageSelectorScreen` UI displaying native language names, English subtitles, instant search, script badges, active indicators, and zero country flags.
  - Riverpod `localeProvider` for instant runtime language switching with SQLite `app_settings` persistence.
  - Automated test suites: `test/unit/localization_test.dart` and `scripts/test-multilingual-architecture.py` (22/22 tests passing).

## [1.2.0] — 2026-11-21

### Added
- **Complete Database Architecture & SQLite + Drift Implementation (Step 3)**:
  - 7 relational tables in Drift: `Families`, `People`, `Events`, `Entries`, `EntryItems`, `Reminders`, `AppSettings`.
  - Type converters: `TransactionDirectionConverter`, `TransactionTypeConverter`, `TransactionStatusConverter`, `EventTypeConverter`.
  - 7 specialized DAOs: `FamiliesDao`, `PeopleDao`, `EventsDao`, `EntriesDao`, `EntryItemsDao`, `RemindersDao`, `SettingsDao`.
  - Repository layer with MVVM integration: `EntriesRepository`, `PeopleRepository`, `EventsRepository`, `FamiliesRepository`, `SettingsRepository`.
  - Atomic multi-item transaction management: guarantees saving entry and multiple physical gifts atomically with automatic rollback on error.
  - 14 performance indexes covering all foreign keys, status flags, and search columns.
  - Automated SQLite test suite (`scripts/test-database-architecture.py`) testing constraints, cascades, rollbacks, and scale stress test across 31,700 records (10K transactions aggregated in 3.43ms).
  - Version-controlled schema migration engine (`SchemaMigrations`) from v1 through v4 with `PRAGMA foreign_key_check`.

## [1.1.0] — 2026-11-21

### Added
- **Flutter Cross-Platform Architecture Foundation (Step 2)**:
  - Multi-platform setup in `pubspec.yaml` and `analysis_options.yaml` targeting Android, iOS, Linux, macOS, and Windows.
  - Core layer (`lib/src/core/`) including brand colors (`AppColors`), spacing system (`AppSpacing`), strings (`AppStrings`), integer paise utilities (`CurrencyUtils`), Hindi Devanagari calendar formatting (`AppDateUtils`), `Result<T>` monad, and platform detection flags (`PlatformInfo`).
  - Domain layer (`lib/src/domain/`) with strict transaction enums, entities, and pure implementation of the 12 financial rules (`FinancialRules`).
  - Data layer with Drift ORM schemas (`lib/src/data/database/tables/`) mirroring SQLite v3 schema byte-for-byte (`Households`, `Families`, `People`, `Events`, `Entries`, `EntryItems`, `Reminders`, `Attachments`).
  - Reactive DAOs (`EntriesDao`) enforcing strict Mila/Diya separation and cash/gift isolation in SQL queries.
  - Riverpod state management providers (`lib/src/app/app_providers.dart`) for database, repositories, and reactive streams.
  - Presentation layer including Material 3 theme (`AppTheme`), `DirectionBadge`, `FloatingPillTabBar` (expanding terracotta chip), `ResponsiveLayout` (mobile touch / desktop split-screen & sidebar), and redesigned modern `DashboardScreen`.
  - Comprehensive Flutter unit test suite: `currency_utils_test.dart`, `financial_rules_test.dart`, and `date_utils_test.dart`.
  - Unified CI pipeline (`.github/workflows/ci.yml`) automating both React Native and Flutter verification checks.

## [1.0.0] — 2026-11-21

### Added
- **Master Multi-Platform Architecture Specification (`docs/FLUTTER_MIGRATION_ARCHITECTURE.md`)**:
  - Detailed 5-platform blueprint (Android, iOS, Linux, macOS, Windows) with Flutter 3.24+, Riverpod 2.6, and Drift ORM 2.20.
  - Complete feature-first folder organization and Drift table definitions.
  - Migration risk analysis and step-by-step roadmap with zero data loss guarantee.
- **Cross-Platform Strategy & Release Guides**:
  - `docs/PLATFORM_STRATEGY.md`: 5-platform support matrix, desktop keyboard/mouse vs mobile touch UX, and technical feasibility report.
  - `docs/PLATFORM_RELEASE.md`: Packaging specifications for APK, AAB, IPA, AppImage, Flatpak, DMG, and MSIX.
  - ADR 013 and ADR 014 recorded in `docs/DECISIONS.md`.
- **Complete Project Documentation & AI Working Instructions System**:
  - Central instruction manual `AGENTS.md` with enforceable pre-coding and post-coding checklists.
  - Lightweight entry points `CLAUDE.md`, `GEMINI.md`, and `.github/copilot-instructions.md`.
  - Comprehensive 24-document knowledge base in `docs/` covering architecture, schema, domain rules, test evidence, and roadmaps.
- **Redesigned Modern Home Screen (`app/(tabs)/index.tsx`)**:
  - Compact Deep Navy header (`#1F3352`) with white app title and subtle subtitle.
  - Two refined financial cards for *Kul Mila* (`#E2F5EB`) and *Kul Diya* (`#FCE9E7`) with large readable rupee typography.
  - Unified single-bar overview statistics for *Karyakram*, *Vyakti*, and *Vyavahaar*.
  - Clean recent event card with direct navigation to event details.
  - Modern action tiles featuring Terracotta primary button for *Naya Vyavahaar*.
  - Focus auto-refresh (`useFocusEffect`) and pull-to-refresh (`RefreshControl`).
- **Floating Pill-Shaped Bottom Navigation (`src/components/FloatingTabBar.tsx`)**:
  - Capsule-style floating bar with soft elevation.
  - Expanding Terracotta (`#C05A2B`) chip for active tab.
  - Resilient navigation handlers calling `navigateToTab(route.key)` and `router.navigate`.
  - 12dp `hitSlop` on all tabs for responsive touch feedback.
- **Devanagari Hindi PDF Reports Engine (`src/services/PdfService.ts`)**:
  - 6 A4 PDF reports (Complete, Person-wise, Event-wise, Year-wise, Gift-wise, Custom date).
  - Embedded Google Noto Sans Devanagari font with correct ligature shaping.
- **AES-256 Encrypted Offline Backup & Safe Restore (`src/services/BackupService.ts`)**:
  - Password-protected local backup using PBKDF2 (10,000 iterations) + AES-256-GCM.
  - Pre-restore in-memory safety snapshot with atomic database rollback on failure.
  - Plain and encrypted backup envelope specification v3.
- **RFC-4180 CSV Export Engine (`src/services/CsvService.ts`)**:
  - CSV serializer with UTF-8 Byte Order Mark (`\uFEFF`) for Microsoft Excel compatibility.
- **Automated Comprehensive Test Suites (`scripts/`)**:
  - `test-business-logic.ts`: 16 automated tests.
  - `test-phase3-features.ts`: 11 automated tests including 31,500 records stress test.

### Changed
- Replaced all Unicode emojis across the codebase with `@expo/vector-icons` (`Ionicons`).
- Upgraded SQLite database to schema v3 with `status` (`'planned' | 'recorded' | 'cancelled'`) and `expected_date`.
- Set `paddingBottom: 110` across all main scroll views to prevent bottom bar overlap.

### Fixed
- Fixed runtime crash `Cannot read property 'emit' of undefined` in `FloatingTabBar.tsx` by adapting to Expo Router 58's custom tab bar props.
- Fixed `tabBarStyle` clipping on Android by setting `{ position: 'absolute', bottom: 0 }`.

### Deferred
- **Phase 4 Cloud & Family Sharing**: Intentionally frozen and deferred to maintain 100% offline-first privacy.
