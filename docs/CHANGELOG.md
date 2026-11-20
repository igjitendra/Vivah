# Changelog — व्यवहार (Vyavahaar)

> All notable changes to this project are documented in this file in chronological order.  
> Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

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
