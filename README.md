# व्यवहार (Vyavahaar) — Digital Family Ledger

> **"रिश्तों का हिसाब, हमेशा याद।"**  
> A Hindi-first, offline-first cross-platform personal ledger and family transaction management application for traditional Indian cultural gift and money exchanges (*shadi, baraat, tilak, mundan, griha pravesh*, etc.).  
> **Target Platforms**: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**.

[![Target Stack](https://img.shields.io/badge/Stack-Flutter_%2B_Dart_3.x-blue.svg)](docs/TECH_STACK.md)
[![Architecture](https://img.shields.io/badge/Architecture-Feature--First_Riverpod_GoRouter-success.svg)](docs/ARCHITECTURE.md)
[![Database](https://img.shields.io/badge/Database-SQLite_Drift_WAL-003B57.svg)](docs/DATABASE_SCHEMA.md)
[![Security](https://img.shields.io/badge/Security-AES--256--GCM_PBKDF2_600k-red.svg)](docs/SECURITY.md)
[![Languages](https://img.shields.io/badge/Languages-22_Scheduled_Indian_Languages-orange.svg)](docs/LANGUAGE_SUPPORT_MATRIX.md)
[![Tests](https://img.shields.io/badge/Tests-100%25_Passing-brightgreen.svg)](scripts/)
[![Offline First](https://img.shields.io/badge/Mode-100%25_Offline-brightgreen.svg)](docs/SECURITY.md)
[![Platforms](https://img.shields.io/badge/Platforms-Android_%7C_iOS_%7C_Linux_%7C_macOS_%7C_Windows-purple.svg)](docs/PLATFORM_STRATEGY.md)

---

## 📖 Introduction

In Indian culture, family functions such as weddings, tilak, mundan, and festivals involve exchanging cash (*shagun / vyavahaar*) and gifts with relatives and friends. Traditionally, these transactions were recorded in handwritten red cloth-bound notebooks (*Bahi-Khata* / बही-खाता). These physical books are easily misplaced, damaged, difficult to search during reciprocal events, and hard to share with family members.

**व्यवहार (Vyavahaar)** digitizes this cultural tradition into a secure, private, offline-first cross-platform application designed for mobile devices and desktop computers:
- Search decades of family history in milliseconds with Indic Unicode script normalization.
- View exact past exchanges with any relative before attending their family function.
- Plan upcoming व्यवहार entries for future events.
- Generate beautiful, printable Hindi PDF reports with authentic embedded Devanagari typography.
- Securely backup your family records locally with AES-256-GCM encryption and transfer files across platforms.

---

## 💻 Target Platforms Matrix (5 Platforms)

| Platform | Target Type | Interface Modality | Status | Official Implementation |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | Mobile | Touch-First | **VERIFIED** | Flutter + Material 3 |
| **iOS** | Mobile | Touch-First | **ARCHITECTURE READY** | Flutter + Material 3 |
| **Linux** | Desktop | Keyboard & Mouse | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |
| **macOS** | Desktop | Keyboard, Mouse, Trackpad | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |
| **Windows** | Desktop | Keyboard, Mouse, Touch | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |

* **Single Source of Truth**: **Flutter + Dart** (`lib/`)
* For in-depth cross-platform architecture, see [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md) and [`docs/TECH_STACK.md`](docs/TECH_STACK.md).

---

## 🌟 Core Features

- 📱 **Adaptive UI**: Authentic warm Indian palette, tailored Devanagari Hindi interface, custom floating pill navigation on mobile, and wide desktop responsive layout.
- 💰 **Strict Financial Integrity**: 
  - *Mila* (Received) and *Diya* (Given) are **strictly separated** (never net-combined or presented as commercial debt).
  - All currency stored in **integer paise** (zero floating-point math inaccuracies).
  - Physical gift estimates are tracked separately from cash totals.
- 👥 **People & Families**: Comprehensive relationship directory with village/city, phone numbers, and full exchange history.
- 📅 **Events Management**: Create events (*Shaadi, Tilak, Mundan, etc.*) and track all incoming/outgoing transactions per event.
- 📝 **Past & Planned Records**: Track recorded transactions as well as planned gifts for upcoming events.
- 🔍 **Advanced Search & Multi-Filters**: Filter by person, village, event, date range, year, and transaction direction.
- 📄 **Production Hindi PDF Reports**: High-resolution Devanagari-embedded A4 reports generated entirely offline.
- 📊 **Excel-Compatible CSV Export**: RFC-4180 compliant CSV exports with UTF-8 BOM encoding.
- 🔒 **Encrypted Offline Backup & Safe Restore**: AES-256-GCM + PBKDF2 (600,000 iterations) password-protected local backup with atomic rollback safety.
- 🚫 **100% Offline & Private**: Zero cloud tracking, no accounts, no ads, no internet required.

---

## 🛠️ Technology Stack

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | Stable SDK (Dart 3.x) | Single cross-platform UI framework |
| **State Management** | Riverpod | ^2.6.1 | Reactive, testable dependency injection |
| **Routing** | GoRouter | ^14.6.2 | Declarative navigation with nested shell routes |
| **Database** | Drift + SQLite | ^2.24.2 | Type-safe SQL, WAL mode, migrations, reactive streams |
| **Localization** | `flutter_localizations` + Intl | Native SDK | 22 Eighth Schedule Indian languages via ARB catalogs |
| **Encryption** | Cryptography / PointyCastle | AES-256-GCM | Authenticated encryption + PBKDF2 600,000 iterations |
| **PDF Engine** | `pdf` + `printing` | ^3.11.1 / ^5.13.2 | Devanagari font embedding, offline A4 reports |
| **CSV Engine** | `csv` + `share_plus` | ^6.0.0 / ^10.1.3 | RFC-4180 export with UTF-8 BOM |
| **Icons** | Material Icons | Native SDK | Vector iconography (zero emojis) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel, Dart 3.x)
- Android Studio / Xcode / Desktop build toolchains for target platforms
- Python 3.12+ (for local architecture stress test suites)

### Installation
```bash
# Clone the repository
git clone https://github.com/igjitendra/Vivah.git vyavahaar
cd vyavahaar

# Checkout Flutter-only branch
git checkout migration/flutter-only

# Fetch Flutter dependencies
flutter pub get

# Generate Drift database code and models
dart run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Run on connected device or emulator
flutter run
```

---

## 🧪 Verification & Testing

The project maintains automated test suites verifying business logic, financial rules, database stress, and multilingual localization:

```bash
# Run Flutter unit and domain tests
flutter test

# Run Database Architecture stress tests (31,700 records scale test)
python3 scripts/test-database-architecture.py

# Run Multilingual localization & Unicode normalization tests (22 languages)
python3 scripts/test-multilingual-architecture.py
```

---

## 📚 Documentation System

Complete, production-grade technical and product documentation is located in the [`docs/`](docs/) directory:

- 📑 [Documentation Index](docs/README.md)
- 🌐 [Cross-Platform Strategy & Feasibility](docs/PLATFORM_STRATEGY.md)
- 📦 [Cross-Platform Packaging & Release](docs/PLATFORM_RELEASE.md)
- 🎯 [Project Overview & Philosophy](docs/PROJECT_OVERVIEW.md)
- 📋 [Product Requirements Document](docs/PRODUCT_REQUIREMENTS.md)
- 📊 [Verified Project Status](docs/PROJECT_STATUS.md)
- 🗺️ [Product Roadmap & Phases](docs/ROADMAP.md)
- 🏛️ [System Architecture](docs/ARCHITECTURE.md)
- 🗄️ [SQLite Database Schema & Migrations](docs/DATABASE_SCHEMA.md)
- ⚖️ [Domain & Financial Rules](docs/DOMAIN_RULES.md)
- 🎨 [UI/UX Guidelines](docs/UI_UX_GUIDELINES.md)
- 🔒 [Privacy & Security Architecture](docs/PRIVACY_SECURITY.md)
- 💾 [Backup & Restore Specifications](docs/BACKUP_RESTORE.md)
- 📄 [Reports & Export Guide](docs/REPORTS_AND_EXPORTS.md)
- 🤖 [AI Coding Agent Workflow](docs/AI_WORKFLOW.md)
- 🚫 [Non-Negotiable Constraints](docs/KNOWN_CONSTRAINTS.md)

---

## 🔒 Important Architectural Constraints

1. **Multi-Platform Scope**: Vyavahaar is a cross-platform application targeting Android, iOS, Linux, macOS, and Windows.
2. **Phase 4 (Cloud & Sync) is DEFERRED**: Multi-platform support does NOT mean cloud sync. Do not implement cloud databases, Supabase, Firebase, or online authentication.
3. **Never Net-Combine Finances**: Never subtract Given from Received.
4. **Integer Currency Only**: Never use floating-point numbers for money calculations.
5. **No Emojis**: Use vector icons exclusively.
6. **AI Instructions**: Any AI coding agent modifying this repository must follow [`AGENTS.md`](AGENTS.md).
