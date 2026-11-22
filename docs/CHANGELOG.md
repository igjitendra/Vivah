# Changelog — व्यवहार (Vyavahaar)

> All notable changes to this project are documented in this file in chronological order.  
> Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.4.4] — 2026-11-22

### Added
- **Official Brand Logo & Symbols System (`AppLogo`, `AppSymbol`)**:
  - Implemented `VyavahaarSymbolPainter`: pure Flutter resolution-independent vector rendering of the Open Ledger Bahi + Terracotta Checkmark symbol with zero external dependencies.
  - Implemented `AppSymbol`: standalone brand icon with automatic fallback to high-resolution asset PNGs.
  - Implemented `AppLogo`: full brand lockup with multiple layout variants (`vertical`, `horizontal`, `compactHeader`, `symbolOnly`) and theme support (`darkCanvas`, `lightCanvas`).
  - Integrated `AppSymbol` directly into `DashboardScreen` header, replacing generic icons.
- **Animated Splash Screen (`SplashScreen`)**:
  - Fullscreen Deep Navy (`#1F3352`) background with subtle radial gradient aura.
  - Smooth 1200ms fade-in and spring scale animation of the official Vyavahaar logo lockup.
  - Bottom "100% ऑफ़लाइन और सुरक्षित" trust pill and status indicator.
  - Intelligent first-launch routing: checks SQLite `SettingsRepository` for `'onboarding_completed'`. Routes to `/onboarding` on first launch or directly to `/` (Dashboard) for returning users.
- **3-Stage Cultural Onboarding Walkthrough (`OnboardingScreen`)**:
  - Culturally resonant, beautifully crafted 3-slide interactive walkthrough:
    - *Slide 1 (पारिवारिक उत्सवों का सच्चा साथी)*: Traditional Indian digital bahi khata, strict separation of Mila (Received) & Diya (Given), cash vs physical gift tracking.
    - *Slide 2 (रिश्तों का मान-सम्मान)*: Family goodwill, zero commercial debt mindset, pre-ceremony budget planning.
    - *Slide 3 (पूर्णतः ऑफ़लाइन और निजी)*: 100% offline privacy guarantee, AES-256-GCM encryption, PDF/CSV reports, and direct 1-tap language switch chip.
  - Smooth page dots indicator, skip action ("छोड़ें"), and tactile `ExpressSquish` "आगे बढ़ें" / "शुरू करें" CTA button.
  - Automatically persists `'onboarding_completed' = 'true'` in SQLite on completion or skip.
  - Re-accessible at any time from **Settings ➔ Display & Preferences ➔ ऐप परिचय (ऑनबोर्डिंग)** via `/onboarding?fromSettings=true`.
- **Navigation & Multilingual Integration**:
  - Configured `initialLocation: '/splash'` in `appRouter` (`app_router.dart`).
  - Added new localized strings across `app_en.arb`, `app_hi.arb`, and `app_ur.arb` with complete key parity.
  - Verified with 22/22 multilingual automated tests and 14/14 SQLite architecture stress tests.

---

## [1.4.3] — 2026-11-22

### Added
- **Full Pixel-Perfect Theme Gallery (थीम गैलरी)**:
  - Implemented 3-mode switcher (`Auto (System)`, `Light`, `Dark`) with active purple border and subtle glow.
  - Curated 8 Light Themes: `Porcelain`, `Lavender`, `Sky`, `Sakura`, `Mint`, `Linen`, `Paper`, `Solarized Light`.
  - Curated 17 Dark Themes: `Midnight Aurora`, `Obsidian`, `Graphite`, `Midnight`, `High Contrast`, `Amber Night`, `Mocha`, `Neon City`, `Aurora`, `Nord`, `Dracula`, `Velvet`, `Deep Ocean`, `Ember`, `Forest`, `Sunset`, `Solarized Dark`.
  - Realistic card mockup previews with primary line, accent pill, and 5-swatch palette circles.
  - Star badges on default favorite themes (`Porcelain`, `Midnight Aurora`).
- **Tactile ExpressSquish & ExpressCard Motion (InlitX/streak Design System)**:
  - Added `ExpressSquish` spring bounce animation (`ExpressSpring` curve with stiffness 380, damping 0.58).
  - Added `ExpressCard` with hairline border and smooth 16-24dp rounded corners.
  - Interactive tabs, theme cards, transaction cards, and action buttons wrapped in tactile squish.
- **Complete End-to-End Dynamic Theming**:
  - Eliminated all hardcoded background and surface colors across all screens (`DashboardScreen`, `LedgerScreen`, `AddEntryScreen`, `EntryDetailScreen`, `PeopleListScreen`, `PersonDetailScreen`, `AddPersonScreen`, `EventsListScreen`, `EventDetailScreen`, `AddEventScreen`, `SettingsScreen`, `ThemeGalleryScreen`, `LanguageSelectorScreen`, `ReportsScreen`, `RemindersScreen`, `FloatingPillTabBar`).
  - All screens react dynamically to active light and dark palettes.
- **Persistent Theme Preferences**:
  - `ThemeNotifier` loads and saves `app_theme_mode`, `app_theme_light_palette`, and `app_theme_dark_palette` directly in SQLite `SettingsRepository`.
- **SQLite Isolate Native Binding Fix**:
  - Bound `@pragma('vm:entry-point') _isolateSetup` with `applyWorkaroundToOpenSqlite3OnOldAndroidVersions()` in `app_database.dart` ensuring background Drift isolates load SQLite native `.so` libraries reliably across all Android architectures.

---

## [1.4.2] — 2026-11-22

### Added
- **Dynamic Quick Shagun Amounts (त्वरित शगुन राशि चिप्स)**:
  - Added 1-tap quick Shagun amount chips (`₹101, ₹251, ₹501, ₹1,100, ₹2,100, ₹5,100, ₹11,000`) in `AddEntryScreen` for fast cultural recording.
- **Dynamic Relationship Suggestions (रिश्तेदारी सुझाव)**:
  - Added kinship quick-selection chips (`मामा, चाचा, ताऊ, बुआ, मौसी, फूफा, जीजा, साला, समधी, मित्र, पड़ोसी`) in `AddPersonScreen` with localized support (Hindi, English, Urdu).
- **Dynamic Custom Event Ceremonies (कस्टम कार्यक्रम प्रकार)**:
  - Added custom ceremony input and tags (`जन्मदिन, नामकरण, जनेऊ / उपनयन, छठी, गोद भराई, सत्संग, रिटायरमेंट, श्राद्ध`) in `AddEventScreen` when `EventType.other` is selected.
- **Dynamic Physical Gift Items & Units (भौतिक उपहार व इकाइयाँ)**:
  - Added interactive dialog and list to record physical gifts with custom units (`संख्या, ग्राम, तोला, पीस, थान / मीटर, किलो, डिब्बा`) and isolated estimated values in `AddEntryScreen`.
- **Dynamic Transaction Status & Historical/Future Date Picker**:
  - Unlocked `TransactionStatus` selection (Recorded vs Planned) and dynamic date picker in `AddEntryScreen` allowing entries on any date.
- **Locale-Aware Dynamic Calendar Date Formatting**:
  - Updated `AppDateUtils.formatIsoDate` to dynamically render month names matching the active language (Hindi, English, Urdu) across all screens.

---

## [1.4.1] — 2026-11-22

### Added
- **Mandatory 4-Pillar Documentation Synchronization Rules (अनिवार्य दस्तावेजीकरण नियम)**:
  - Formally established and codified mandatory documentation synchronization rules across `GEMINI.md`, `CLAUDE.md`, `AGENTS.md`, `docs/AI_WORKFLOW.md`, and `docs/README.md`.
  - Mapped all future development modifications into 4 explicit categories with their corresponding `.md` documentation files:
    - **Design (डिज़ाइन)**: `docs/DESIGN_SYSTEM.md`, `docs/UI_UX_GUIDELINES.md`, `docs/NAVIGATION.md`
    - **Working (कार्यप्रणाली / लॉजिक)**: `docs/DOMAIN_RULES.md`, `docs/ARCHITECTURE.md`, `docs/USER_FLOWS.md`
    - **Backend (बैकएंड / डेटाबेस)**: `docs/DATABASE_SCHEMA.md`, `docs/FLUTTER_MIGRATION_ARCHITECTURE.md`, `docs/BACKUP_RESTORE.md`
    - **Features (फ़ीचर्स)**: `docs/FEATURES.md`, `docs/PROJECT_STATUS.md`, `docs/PRODUCT_REQUIREMENTS.md`, `docs/ROADMAP.md`
  - Required that every AI agent and developer update the corresponding `.md` file in the same task before work is deemed complete.

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
