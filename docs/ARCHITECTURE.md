# System Architecture — व्यवहार (Vyavahaar)

> **Official Target Architecture**: Feature-First, MVVM + Repository Pattern, Typed Drift ORM, Flutter Riverpod  
> **Legacy Reference MVP**: React Native 0.88.1 / Expo SDK 58.0.26 (Preserved for functional parity)  
> **Target Scope**: 5 Cross-Platform Operating Systems: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**  
> **Offline Policy**: 100% Offline-First; SQLite is the sole source of truth; zero cloud dependencies.  
> **Last Updated**: 2026-11-21  

---

## 1. Official Target Architecture Diagram (Flutter + Dart)

The Flutter target architecture implements strict layer separation where presentation code never touches raw SQL, and business logic remains 100% independent of UI widgets:

```mermaid
flowchart TD
    subgraph Presentation_Layer [Presentation Layer - Widgets & Shell]
        Shell[Adaptive Shell: ResponsiveLayout]
        FloatingBar[FloatingPillTabBar - Mobile]
        Sidebar[NavigationRail - Desktop / Tablet]
        DashboardView[DashboardScreen]
        LedgerView[BahiKhataScreen]
        PeopleView[PeopleDirectoryScreen]
        EventsView[EventsScreen]
        SettingsView[SettingsScreen]
        LangSelector[LanguageSelectorScreen]
    end

    subgraph State_Layer [MVVM & State Management - Riverpod]
        DashboardNotifier[dashboardSummaryProvider]
        EntriesNotifier[entriesListProvider]
        PeopleNotifier[activePeopleListProvider]
        EventsNotifier[activeEventsListProvider]
        LocaleNotifier[localeProvider - 22 Languages]
    end

    subgraph Domain_Layer [Pure Domain & Business Rules]
        FinancialRules[FinancialRules - 12 Mandatory Rules]
        Entities[Domain Entities: TransactionEntry, Person, Event, Family]
        Enums[Enums: TransactionDirection, TransactionType, TransactionStatus]
        CurrencyMath[CurrencyUtils: Integer Paise Math]
        SearchUtils[UnicodeSearchUtils: NFC Normalization across 12 Indic Scripts]
    end

    subgraph Repository_Layer [Repository Contracts & Implementations]
        EntriesRepo[EntriesRepository - Atomic Multi-Item Transactions]
        PeopleRepo[PeopleRepository - Deletion Protection Checks]
        EventsRepo[EventsRepository - Event History & Stats]
        FamiliesRepo[FamiliesRepository - Clan Directory]
        SettingsRepo[SettingsRepository - App Preferences]
    end

    subgraph Data_Layer [Typed SQLite Layer - Drift ORM]
        AppDb[(AppDatabase: vyavahaar.db)]
        EntriesDao[EntriesDao]
        PeopleDao[PeopleDao]
        EventsDao[EventsDao]
        FamiliesDao[FamiliesDao]
        EntryItemsDao[EntryItemsDao]
        RemindersDao[RemindersDao]
        SettingsDao[SettingsDao]
        Migrations[SchemaMigrations: v1 to v4]
        WAL[SQLite WAL Mode + Foreign Keys ON]
    end

    Presentation_Layer --> State_Layer
    State_Layer --> Repository_Layer
    Repository_Layer --> Domain_Layer
    Repository_Layer --> Data_Layer
    Data_Layer --> AppDb
```

---

## 2. Layer Responsibilities & Strict Isolation

1. **Presentation Layer (`lib/src/features/`, `lib/src/shared/`)**:
   - Contains only Flutter widgets, responsive layouts, and animations.
   - Watches Riverpod providers.
   - **Never executes SQL queries, currency conversions, or business logic**.
   - Uses `ResponsiveLayout` to dynamically provide the approved floating pill bottom bar on mobile (<600dp) and a spacious navigation rail/sidebar on desktop (≥1024dp).
2. **State Layer (`lib/src/app/app_providers.dart`, `lib/src/core/localization/`)**:
   - Manages UI state using Riverpod `FutureProvider`, `StreamProvider`, and `StateNotifier`.
   - Dispatches user intents to repositories and reacts to database stream emissions.
3. **Domain Layer (`lib/src/domain/`)**:
   - Contains pure Dart entity classes and financial calculation rules (`FinancialRules`).
   - Zero dependencies on Flutter UI or Drift database packages.
   - Enforces the 12 non-negotiable cultural ledger rules (separating Mila and Diya, isolating gift valuations, and rejecting invalid transaction combinations).
4. **Repository Layer (`lib/src/data/repositories/`)**:
   - Mediates between the domain entities and the Drift database DAOs.
   - Manages atomic multi-record transactions (e.g. inserting an entry and multiple physical gifts atomically with complete rollback on error).
5. **Data Layer (`lib/src/data/database/`)**:
   - Drift typed tables and DAOs.
   - Direct native C-bindings to SQLite in WAL mode with foreign keys enabled (`PRAGMA foreign_keys = ON;`).

---

## 3. Data Integrity & Financial Consistency

* **Integer Paise Arithmetic**: All financial amounts in the repository and database layers are represented in integer paise (`1 Rupee = 100 Paise`). Floating-point numbers are strictly forbidden.
* **Mila & Diya Separation**: Total Received and Total Given are queried and calculated as independent positive sums. Under no circumstances are they subtracted or netted.
* **Soft Archiving**: Destructive deletions are avoided. People, events, families, and entries support soft archiving via `archived_at` timestamps to preserve historical records.
* **Deletion Protection**: A person with associated transactions cannot be deleted (`ON DELETE RESTRICT` enforced by SQLite engine).

---

## 4. Legacy Reference MVP Architecture (React Native)

The repository preserves the original React Native implementation (`app/`, `src/`) for verification and behavioral parity:
* Architecture: Expo Router file-based routing + React Hooks (`useDashboard`, `useEntries`) + Service Layer (`EntriesService`, `BackupService`) + `expo-sqlite`.
* All 27 automated tests pass consistently via `pnpm test`.
