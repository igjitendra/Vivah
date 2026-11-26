# Changelog — व्यवहार (Vyavahaar)

> All notable changes to this project are documented in this file in chronological order.  
> Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.4.16] — 2026-11-26

### Added
- **`AppSemanticColors` ThemeExtension (`lib/src/core/theme/app_semantic_colors.dart`)**:
  - Dynamically derives hero gradients, highlights, overlapping card tints, Mila/Diya semantic containers, gift/cash split accents, and shadow tokens from any active `ThemePalette`.
  - Registered inside `AppTheme.fromPalette` with full `lerp` transition support across all 25 light & dark curated palettes.
- **Professional Hero + Bento Home Dashboard (`lib/src/features/dashboard/presentation/dashboard_screen.dart`)**:
  - Theme-adaptive curved hero banner with framed `AppSymbol`, title/tagline, live pending reminder notification bell badge, and settings trigger.
  - Floating overlapping Family Profile banner (`हमारा परिवार`, location/subtitle, live member count, quick view/setup CTA).
  - Side-by-side gradient Mila/Diya hero metric cards with vibrant icon badge, mini trend bars, quick `+` logging trigger, and tinted footer bar.
  - Live Cash vs Gifts (`नकद` & `उपहार`) breakdown strip aggregated from recorded entries.
  - 5-tile Quick Actions card (Entry, Event, People, Reports, Backup) and responsive side-by-side Bento cards for Upcoming Events (`आगामी आयोजन`) & Upcoming Reminders (`आगामी यादें`).
  - Enhanced Recent Transactions card (`हाल के व्यवहार`) with directional pills, relative dates, and cash/gift indicators.

### Changed
- **Bottom Footer Tab Bar Upgrade (`More` / `अधिक` Tab)**:
  - Replaced the 5th bottom navigation tab ("Settings") with a dedicated **"More"** (`अधिक` / `•••`) tab routed to `/more` (`lib/src/features/more/presentation/more_screen.dart`).
  - Added theme-adaptive `MoreScreen` hub providing 1-tap access to Family Profile, Reports & Exports, Reminders (with live pending badge), Theme Gallery, Language Selector, App Tour, Quick Shortcuts, and Full-Screen Settings (`/settings`).
  - Moved `/settings` to a full-screen subroute accessible from the Home Hero gear icon and the More hub.
- **Zero-Hardcoded-Color Compliance**:
  - Eliminated all hardcoded hex/static color literals from `DashboardScreen` and `FloatingPillTabBar`, binding every visual token strictly to `AppSemanticColors` and `ThemeData`.
- **Localized Dashboard Labels (`lib/src/core/localization/app_localizations.dart`)**:
  - Added multilingual English, Hindi, and Urdu strings for all new Home Dashboard sections and countdown labels.

---

## [1.4.15] — 2026-11-25

### Added
- **Pro-Level Relative & People Management Architecture**:
  - **Live Financial Ledger Snapshot on Relative Cards**:
    - Aggregates person-wise transactions from ledger streams in real-time.
    - Displays total received (`मिला: ₹...`, Emerald Green) and total given (`दिया: ₹...`, Diya Red) with transaction count badge directly on each relative card.
  - **Pro Smart Multi-Sorting**:
    - Sort relatives by: Alphabetical Name (`A-Z`), Most Transactions (`सर्वाधिक लेन-देन`), Highest Received (`सर्वाधिक मिला`), Highest Given (`सर्वाधिक दिया`), and Recently Added (`हाल ही में जोड़े गए`).
  - **Pro Dynamic Filters**:
    - Smart filter chips: All (`सारे`), Active Ledger (`सक्रिय लेन-देन` with past exchanges), Zero Transactions (`बिना लेन-देन`), Phone Contacts (`फ़ोन से आयातित`), and Manual Entries (`मैन्युअल प्रविष्टि`).
  - **One-Tap Direct Transaction Actions**:
    - Integrated direct `+ व्यवहार जोड़ें` shortcut popup (`+ मिला दर्ज करें` / `+ दिया दर्ज करें`) on every card in the relative directory.
    - Added dual tactile primary action buttons (`+ मिला दर्ज करें` and `+ दिया दर्ज करें`) inside `PersonDetailScreen` ledger passbook section.
    - Pre-selects relative and direction instantly without navigation overhead.

### Changed
- **Modern Minimalist Header Redesign (Streak / Apple Level Polish)**:
  - **Global `AppBarTheme` Overhaul**:
    - Migrated app bar backgrounds across the application from dark navy (`theme.colorScheme.secondary`) to clean surface/white (`palette.surface`).
    - Title text styled with high-contrast `palette.textPrimary`, bold font weight (800), and crisp tracking (-0.2).
    - Applied subtle 1px hairline bottom divider (`palette.cardBorder.withValues(alpha: 0.6)`) and zero elevation for modern flush layout.
  - **Home Dashboard Header Modernization**:
    - Replaced heavy dark navy container and 20px rounded corners with clean flush surface header.
    - Added subtle brand-tinted logo container (`primaryAccent.withValues(alpha: 0.10)`) with `AppSymbol`.
    - Transformed live date indicator into a minimalist calendar capsule pill with calendar icon and high legibility.
    - Modernized tactile circular settings button matching search and filter controls.
  - **Unified Master Screen Headers**:
    - Connected `LedgerScreen`, `EventsListScreen`, and `PeopleListScreen` AppBars seamlessly with their respective search and filter containers, creating unified header blocks.
  - **Detail and Form Screens**:
    - Updated `AddEntryScreen`, `EntryDetailScreen`, `AddEventScreen`, `EventDetailScreen`, `AddPersonScreen`, `PersonDetailScreen`, `ReportsScreen`, `RemindersScreen`, and `LanguageSelectorScreen` with consistent light clean headers and dark crisp icons.
  - **Analyzer Parity**:
    - Eliminated all unused local variables and resolved `AppColors.gold` references. Verified with `flutter analyze` (0 issues).

### Added
- **Record Transaction Architecture Redesign (`AddEntryScreen`)**:
  - **Dedicated Mila vs Diya Workflows**:
    - Distinct entry routes (`/entry/new?direction=received`, `/entry/new?direction=given`) with dedicated color themes: Emerald Green (`#15803D`) for Received (मिला) and Diya Red (`#B91C1C`) for Given (दिया).
    - Top tactile hero switcher allowing instant tab toggling between Mila and Diya.
  - **Dedicated Dual Action Buttons on Dashboard & Ledger**:
    - **+ मिला** (Emerald Green) and **+ दिया** (Diya Red) dedicated action buttons on both Home (`DashboardScreen`) and Bahi Khata (`LedgerScreen`), fulfilling explicit separate button workflows.
  - **100% People-Page Parity for Inline Relative Creation**:
    - "+ नया रिश्तेदार जोड़ें (विस्तृत फॉर्म)" opens the complete `AddPersonScreen` form (phone book contact import, phone numbers, WhatsApp, village/city/address, relationship chips, notes, family group).
    - Returning created `Person` entity automatically selects the new relative into the transaction entry without navigation friction.
  - **Inline Event Creation with Auto-Selection**:
    - "+ नया कार्यक्रम बनाएं" button launches `AddEventScreen` directly inline, creating and immediately auto-selecting the ceremony.
  - **Reciprocal Past Exchange History Peek**:
    - Asynchronous query displaying past reciprocal transactions with the selected relative (*"इन्होंने हमें पूर्व में दिया था: ₹..."* or *"पहला व्यवहार"*).
  - **Rapid Entry / Munshi Mode for Received (मिला)**:
    - "दर्ज करें और अगला जोड़ें" (`saveAndAddNext`) button saves current entry and immediately clears person/amount while keeping event, date, and receiver intact for continuous fast guest logging.
  - **Specialized Fields per Transaction Direction**:
    - Given: Payment Mode (Cash, UPI/Online, Gift only), Handed Over By tracking, and Recorded vs Planned status.
    - Received: Received By tracking, and polite cultural WhatsApp thank-you slip generator.
  - **Multilingual ARB & Localization Parity**:
    - Complete key parity across `app_en.arb`, `app_hi.arb`, and `app_ur.arb` with zero hardcoding and zero emojis.

---

## [1.4.13] — 2026-11-23

### Added
- **Native Multi-Platform Runners Tracked Directly in Repository**:
  - **Android Platform (`android/`)**:
    - Complete native Android project written in **Kotlin** with Gradle Kotlin DSL (`build.gradle.kts`).
    - Configured package namespace `com.procsctools.vyavahaar`, compileSdk 36, targetSdk 35, and minSdk 21.
    - Zero-network offline manifest hardening stripping `INTERNET` and `ACCESS_NETWORK_STATE`.
    - Integrated native Kotlin components (`MainActivity.kt`, widgets, bridges, and storage helpers).
  - **Apple iOS & macOS Platform Projects (`ios/`, `macos/`)**:
    - Complete native Apple runner projects configured with **Swift** (`AppDelegate.swift`, `MainFlutterWindow.swift`).
    - Xcode project definitions, configurations, entitlements, and Podfile specifications matching bundle identifier `com.procsctools.vyavahaar`.
  - **GitHub Linguist Multi-Language Breakdown Parity**:
    - Matches InlitX/streak repository structure: **Dart** (~70%), **Kotlin** (~21%), **Swift** (~4%), **C++** (~3%), **CMake** (~1%), and **Inno Setup** (~0.1%).
  - **CI Workflow Optimization**:
    - Updated `.github/workflows/build-apk.yml` to preserve and build against the committed repository `android/` project rather than recreating it on the fly.

---

## [1.4.12] — 2026-11-23

### Added
- **Dual-Primary Typography Architecture (Poppins & Figtree)**:
  - Bundled authentic **Poppins** font family (`assets/fonts/Poppins-*.ttf`, weights 400 to 800) designed by Indian Type Foundry (ITF) for authentic Devanagari ligature shaping.
  - Bundled **Figtree** font family (`assets/fonts/Figtree-*.ttf`, weights 300 to 900) directly matched from the InlitX/streak aesthetic for geometric sans-serif Latin typography.
  - Wired dynamic, locale-aware font resolution via `AppTheme.fromPalette(palette, locale: activeLocale)` and `ExpressType.theme(onSurface, locale: locale)` with fallback chain `['Poppins', 'Figtree', 'NotoSansDevanagari', 'sans-serif']`.
  - Registered all font weights in `pubspec.yaml`.

### Refactored
- **Complete Elimination of Hard-Coded Strings Across UI Screens**:
  - Replaced hard-coded strings across all screens (`AddEntryScreen`, `AddPersonScreen`, `AddEventScreen`, `OnboardingScreen`, `PeopleListScreen`, `ThemeGalleryScreen`, `ReportsScreen`, `ShortcutsSheet`, `EmptyDetailPane`, and detail screens tooltips).
  - Expanded `AppLocalizations` with type-safe getters and helper collections:
    - `quickTags`: Cultural occasion chips (विवाह शगुन, भात, दिखावा, गृह प्रवेश, etc.).
    - `quickGiftSuggestions`: Common physical gifts (सोने की अंगूठी, चांदी का सिक्का, कपड़े, बर्तन, etc.).
    - `quickRelations`: Traditional kinship chips (मामा, चाचा, ताऊ, बुआ, मौसी, etc.).
    - `quickCustomEvents`: Ceremonies (जन्मदिन, नामकरण, जनेऊ, छठी, गोद भराई, etc.).
    - `unitOptions` & `defaultUnit`: Physical gift units (संख्या, ग्राम, तोला, पीस, आदि).
    - `desktopShortcutsHint`, `shortcutGuide`, `themeGalleryDescription`, `noFamilyMembersYet`, etc.
  - Achieved 100% key parity across `app_en.arb`, `app_hi.arb`, and `app_ur.arb` verified by automated test suites.

---

## [1.4.11] — 2026-11-23

### Fixed
- **Resolved Android 'App not installed' Error (`INSTALL_PARSE_FAILED_NO_CERTIFICATES` & Update Incompatibility)**:
  - **Automated Keystore Generation**: Configured `.github/workflows/build-apk.yml` to automatically generate an RSA-2048 signing keystore and `android/key.properties` during CI.
  - **Dual Scheme v1 + v2 Signing**: Patched `scripts/configure-android-sdk.py` to inject `v1SigningEnabled true` and `v2SigningEnabled true` into `signingConfigs.release`, with safe fallback to debug certificates if keys are missing.
  - **Automated Signature Verification**: Added CI post-build step executing `jarsigner -verify` on both release and debug APKs, actively signing any unsigned release artifact before distribution.
  - **Package Identifier Unification**: Harmonized `--org com.procsctools` in workflow and `scripts/configure-android-sdk.py` (`applicationId = "com.procsctools.vyavahaar"`).
  - **Installation Guidance**: Added comprehensive bilingual installation and signature conflict troubleshooting notes to GitHub Release bodies.

---

## [1.4.10] — 2026-11-22

### Changed
- **Application Package Identifier Alignment (`com.procsctools.vyavahaar`)**:
  - Aligned global package identifier, application ID, and namespace across all platforms to `com.procsctools.vyavahaar`:
    - **Android Build & CI**: Configured `.github/workflows/build-apk.yml` with `--org com.procsctools` and `scripts/configure-android-sdk.py` to enforce `applicationId = "com.procsctools.vyavahaar"` and `namespace = "com.procsctools.vyavahaar"`.
    - **SQLite Dynamic Native Loader**: Added primary extraction paths for `/data/data/com.procsctools.vyavahaar/lib/libsqlite3.so` in `lib/src/data/database/sqlite_loader.dart`.
    - **Windows x64 Desktop**: Updated Inno Setup installer `windows/installer.iss` with `AppUserModelID: "com.procsctools.vyavahaar"`.
    - **Linux GTK+ Desktop**: Updated `linux/CMakeLists.txt` (`APPLICATION_ID`), XDG specification `linux/com.procsctools.vyavahaar.desktop`, and `linux/package.sh`.
    - **Documentation**: Updated `docs/PRIVACY_POLICY.md`, `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/ANDROID_BUILD_RELEASE.md`, and `docs/PLATFORM_RELEASE.md`.

---

## [1.4.9] — 2026-11-22

### Added
- **Native Android Platform Project (`android/`)**:
  - Full Flutter Android platform runner configured under `android/`:
    - `namespace = "com.vyavahaar.app"` and `applicationId = "com.vyavahaar.app"`.
    - Android 15 ready: `compileSdk = 35`, `targetSdk = 35`, `minSdk = 26`, Java 11 with core library desugaring.
    - `MainActivity.kt` extending `FlutterFragmentActivity` with `vyavahaar/security` MethodChannel for toggling `FLAG_SECURE` privacy mode.
    - Zero-network manifest hardening: explicitly strips `INTERNET` and `ACCESS_NETWORK_STATE` permissions via `tools:node="remove"`.
    - Cleaned launcher colors, Deep Navy `#1F3352` cold-start splash drawable, and local backup/extraction rules.
- **Form Action Migration to ExpressButton**:
  - Fully migrated save action buttons in `AddEntryScreen`, `AddPersonScreen`, and `AddEventScreen` to `ExpressButton` (`filled` tone with tactile squish, morphing squircle radii, and loading states).
- **Responsive Desktop Dual-Pane Master-Detail View**:
  - Activated responsive dual-pane split view (`splitWidth = 900.0`, `paneWidth = 440.0`) for `LedgerScreen`, `PeopleListScreen`, and `EventsListScreen`.
  - Added tactile active selection indicator on master list cards (highlighted `2.0dp` accent border, elevated tone, and spring squish).
  - Implemented `EmptyDetailPane` (`lib/src/shared/widgets/empty_detail_pane.dart`) with official brand watermark, Devanagari labels, and hardware shortcut cheat sheet.

## [1.4.8] — 2026-11-22

### Added
- **Native PC Desktop Dual-Pane (Split-View) Architecture**:
  - Implemented responsive dual-pane master-detail interface on PC Desktop (`isWideLayout` / `splitWidth >= 900dp`):
    - **Ledger Master-Detail (`LedgerScreen`)**: Left pane (440dp width) with search, direction tabs, filters, and transaction cards. Right pane embeds `EntryDetailScreen` with live transaction breakdown or `EmptyDetailPane` placeholder when no transaction is selected.
    - **People & Family Master-Detail (`PeopleListScreen`)**: Left pane displays relatives and families directory. Right pane embeds `PersonDetailScreen` with balance passbook or `EmptyDetailPane`.
    - **Events Master-Detail (`EventsListScreen`)**: Left pane displays celebration ceremonies. Right pane embeds `EventDetailScreen` with ceremony totals and timeline or `EmptyDetailPane`.
  - Added tactile active selection indicator on master list cards (highlighted accent border, elevated tone, and spring squish).
  - Implemented `EmptyDetailPane` (`lib/src/shared/widgets/empty_detail_pane.dart`) with official brand lockup, keyboard shortcuts hint pill, and CTA button.
  - Added `showBackButton` and `onClose` callback parameters to `EntryDetailScreen`, `PersonDetailScreen`, and `EventDetailScreen` to support seamless embedding and closing in desktop panes.
- **Cross-Platform Package Alignment & Linux / Windows Distribution Cleanup**:
  - Aligned desktop application IDs to official standard `com.vyavahaar.app` across `linux/CMakeLists.txt`, `windows/installer.iss`, and Linux XDG desktop entry `linux/com.vyavahaar.app.desktop`.
  - Updated `linux/package.sh` AppImage packaging script to build `Vyavahaar-x86_64.AppImage`.
  - Configured `scripts/configure-android-sdk.py` to guarantee `namespace = "com.vyavahaar.app"` and `applicationId = "com.vyavahaar.app"`.
- **Google Play Store Data Safety & Privacy Policy Compliance**:
  - Published comprehensive offline-first `docs/PRIVACY_POLICY.md` detailing 100% offline zero-collection policy, permissions audit, AES-256-GCM encryption, COPPA and India DPDP Act 2023 compliance.
  - Aligned `docs/ROADMAP.md` and `docs/PLATFORM_RELEASE.md` to SQLite schema v4 and backup envelope v4.

---

## [1.4.7] — 2026-11-22

### Added
- **InlitX/streak Redesign of 'Add Entry' Screen (नया व्यवहार दर्ज करें)**:
  - **Tactile Mila / Diya Switcher**: Smooth spring animation with positive emerald and terracotta glow, icons, and cultural guidance subtitles.
  - **Searchable Relative Picker Sheet**: Interactive modal bottom sheet with search-as-you-type, avatar badges, and relationship chips.
  - **Inline Quick Relative Creator**: `+ नया व्यक्ति जोड़ें` sheet directly inside the transaction form, instantly creating and selecting a relative without leaving the screen.
  - **Hero Rupee Amount Card with Words Preview**: Large ₹ typography and dynamic real-time amount in words (`CurrencyUtils.formatRupeesInWords`) in Hindi and English.
  - **Quick Shagun Denomination Chips**: Traditional Indian amounts (`₹101`, `₹251`, `₹501`, `₹1,100`, `₹2,100`, `₹5,100`, `₹11,000`) and quick increment pills (`+₹100`, `+₹500`, `+₹1000`).
  - **Tactile 3-Pill Transaction Type Selector**: Cash, Gift, and Cash & Gift modes with instant suggested gift chips (Gold ring, silver coin, clothes, utensils, sweets).
  - **Smart Date Presets**: 1-tap "आज" (Today), "कल" (Yesterday), and custom date picker.
  - **Ceremony Notes & Quick Tags**: 1-tap cultural tags (विवाह शगुन, भात / मायरा, दिखावा / टीका, गृह प्रवेश, मुंडन संस्कार, जन्मदिन).
  - **Zero Hardcoded Strings**: Full key parity across English, Hindi, and Urdu.

---

## [1.4.6] — 2026-11-22

### Added
- **Complete Family & Clan Management System (परिवार एवं कुल प्रबंधन प्रणाली)**:
  - Integrated full UI support for `Families` in `PeopleListScreen` via tab switcher (`लोग` vs `परिवार`).
  - Added "+ नया परिवार जोड़ें" dialog with name, description/village, and notes with reactive SQLite persistence.
  - Added family membership inspection sheet displaying all relatives belonging to a family.
  - Linked family association dropdown in `AddPersonScreen` ensuring every relative can be grouped by clan/family.
  - Added `activeFamiliesListProvider` reactive stream in `app_providers.dart`.
- **Comprehensive Visual Insights & Analytics in Reports (सांख्यिकी एवं विज़ुअल अंतर्दृष्टि)**:
  - Added financial overview cards (*Kul Mila* and *Kul Diya* with counts and strict non-netting).
  - Added Top Shagun Transactions cards displaying the highest received and given transactions.
  - Added Event-wise Activity breakdown showing transactional totals per ceremony.
- **Advanced Ledger Filter & Sorting System (बही उन्नत फ़िल्टर व सॉर्टिंग)**:
  - Integrated modal filter sheet with Event dropdown, Transaction Type chips (*Cash, Item, Both*), Status chips (*Recorded, Planned*), and 4 Sort options (*Newest, Oldest, Amount High-to-Low, Amount Low-to-High*).
  - Added active filter badge counter on filter icon and interactive dismissible filter tags row.
- **Full-Lifecycle Entity Editing & Management (संपूर्ण संपादन एवं प्रबंधन प्रणाली)**:
  - **Person Management (`PersonDetailScreen`)**:
    - Added "Edit Person" dialog allowing updates to Name, Relationship, Village/Address, Phone, Family association, and Notes with atomic SQLite persistence.
    - Added "Delete Person" with relational integrity guard: prevents deletion if recorded transactions exist, or safely soft-archives if clean.
    - Added dynamic family/clan badge displaying the relative's clan (*e.g. शर्मा परिवार*).
  - **Event Management (`EventDetailScreen`)**:
    - Added "Edit Event" dialog allowing updates to Event Title, Ceremony Type, Date (with picker), Venue, and Notes.
  - **Transaction Management (`EntryDetailScreen`)**:
    - Added "Edit Transaction" dialog allowing updates to Amount, Transaction Date, and Notes with atomic multi-item consistency.

---

## [1.4.5] — 2026-11-22

### Added
- **InlitX/streak UI/UX Buttons, Typography Scale & Motion**:
  - Implemented `ExpressButton` (`lib/src/shared/widgets/express_button.dart`):
    - Tones: `filled`, `tonal`, and `ghost`.
    - Dynamic tactile bouncy scale down to `0.94` on tap with `Express.fast` and spring bounce on release with `Express.bouncy`.
    - Morphing corner radius: rests at capsule shape (`height / 2`), morphing smoothly into rounded squircle (`14dp`) on press.
    - Compact (`40dp`) and regular (`52dp`) height modes.
  - Implemented `ExpressIconButton`: 40dp squircle tactile icon button with desktop hover state and spring squish.
  - Implemented `ExpressType` (`lib/src/core/theme/express_type.dart`):
    - Exact typography scale from InlitX/streak (display 57/45/36, headline 32/28/24, title 22/16/14, body 16/14/12, label 14/12/11).
    - Optimized for Noto Sans Devanagari and multilingual Indic scripts.
- **InlitX/streak PC Desktop Software Architecture**:
  - Implemented `responsive.dart` (`lib/src/core/utils/responsive.dart`):
    - Exact streak breakpoints (`phoneWidth = 560.0`, `railWidth = 640.0`, `splitWidth = 900.0`, `wideWidth = 1060.0`, `paneWidth = 480.0`).
    - Helper queries: `hasSideRail(context)`, `isWideLayout(context)`, `isCompactRail(context)`.
  - Implemented `ExpressNavRail` (`lib/src/shared/navigation/express_nav_rail.dart`):
    - Dedicated desktop side navigation rail with brand header, interactive mouse hover highlights, active squircle pills, and tooltips in compact mode.
    - Integrated seamlessly into GoRouter `ShellRoute`: automatically displays `ExpressNavRail` on PC desktop/tablet (`>=640dp`) and `FloatingPillTabBar` on mobile (<640dp).
  - Implemented Hardware Keyboard Shortcuts (`AppShortcuts` & `ShortcutsSheet`):
    - Global keyboard handler: `Ctrl+1..5` tab switching, `Ctrl+N` new transaction, `Ctrl+F` search, `Ctrl+,` settings, `F1` or `Ctrl+/` shortcuts modal, and `Esc` dismiss.
    - Installed at root in `lib/src/app/app.dart`.
- **Native PC Desktop Runners (Windows & Linux)**:
  - Added native Windows x64 C++ runner project (`windows/`):
    - `windows/runner/main.cpp` with single-instance mutex (`VyavahaarSingleInstance`).
    - Per-Monitor V2 DPI scaling manifest (`runner.exe.manifest`).
    - Windows Inno Setup installer script (`windows/installer.iss`) for standalone setup distribution.
  - Added native Linux GTK+ C++ runner project (`linux/`):
    - `linux/runner/main.cc` and `my_application.cc` with window state restoration and header bar.
    - Standard XDG Desktop specification: `linux/com.igjitendra.vyavahaar.desktop`.

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
