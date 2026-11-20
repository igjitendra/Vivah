# व्यवहार (Vyavahaar) — Digital Family Ledger

> **"रिश्तों का हिसाब, हमेशा याद।"**  
> A Hindi-first, offline-first cross-platform personal ledger and family transaction management application for traditional Indian cultural gift and money exchanges (*shadi, baraat, tilak, mundan, griha pravesh*, etc.).  
> **Target Platforms**: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**.

[![Target Stack](https://img.shields.io/badge/Target_Stack-Flutter_%2B_Dart-blue.svg)](docs/TECH_STACK.md)
[![Reference MVP](https://img.shields.io/badge/Reference_MVP-React_Native_Expo_58-61DAFB.svg)](docs/TECH_STACK.md)
[![Database](https://img.shields.io/badge/Database-SQLite_Drift_WAL-003B57.svg)](docs/DATABASE_SCHEMA.md)
[![Security](https://img.shields.io/badge/Security-AES--256--GCM_OWASP-red.svg)](docs/SECURITY.md)
[![Languages](https://img.shields.io/badge/Languages-22_Scheduled_Indian_Languages-orange.svg)](docs/LANGUAGE_SUPPORT_MATRIX.md)
[![Tests](https://img.shields.io/badge/Tests-41%2F41_Passed-success.svg)](scripts/)
[![Offline First](https://img.shields.io/badge/Mode-100%25_Offline-brightgreen.svg)](docs/SECURITY.md)
[![Platforms](https://img.shields.io/badge/Platforms-Android_%7C_iOS_%7C_Linux_%7C_macOS_%7C_Windows-purple.svg)](docs/PLATFORM_STRATEGY.md)

---

## 📖 Introduction

In Indian culture, family functions such as weddings, tilak, mundan, and festivals involve exchanging cash (*shagun / vyavahaar*) and gifts with relatives and friends. Traditionally, these transactions were recorded in handwritten red cloth-bound notebooks (*Bahi-Khata* / बही-खाता). These physical books are easily misplaced, damaged, difficult to search during reciprocal events, and hard to share with family members.

**व्यवहार (Vyavahaar)** digitizes this cultural tradition into a secure, private, offline-first cross-platform application designed for mobile devices and desktop computers:
- Search decades of family history in milliseconds.
- View exact past exchanges with any relative before attending their family function.
- Plan upcoming व्यवहार entries for future events.
- Generate beautiful, printable Hindi PDF reports with authentic Devanagari typography.
- Securely backup your family records locally with military-grade AES-256 encryption and transfer files across platforms.

---

## 💻 Target Platforms Matrix (5 Platforms)

| Platform | Target Type | Interface Modality | Status | Official Implementation |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | Mobile | Touch-First | **VERIFIED** | Flutter scaffolded (`lib/`) + React Native reference MVP (`app/`) |
| **iOS** | Mobile | Touch-First | **ARCHITECTURE READY** | Unified Flutter `lib/` codebase |
| **Linux** | Desktop | Keyboard & Mouse | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |
| **macOS** | Desktop | Keyboard, Mouse, Trackpad | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |
| **Windows** | Desktop | Keyboard, Mouse, Touch | **ARCHITECTURE READY** | Flutter + Drift Native SQLite engine |

* **Official Target Implementation**: **Flutter + Dart** (`lib/`)
* **Legacy Reference Implementation**: **React Native (0.88.1) + Expo SDK 58** (`app/`, `src/`) preserved in full for functional parity.
* For in-depth cross-platform architecture, see [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md) and [`docs/TECH_STACK.md`](docs/TECH_STACK.md).

---

## 🌟 Core Features

- 📱 **Adaptive UI**: Tailored Devanagari Hindi interface, custom floating pill bottom navigation on mobile, and wide desktop layout strategy.
- 💰 **Strict Financial Integrity**: 
  - *Mila* (Received) and *Diya* (Given) are **strictly separated** (never net-combined or presented as commercial debt).
  - All currency stored in **integer paise** (zero floating-point math inaccuracies).
  - Physical gift estimates are tracked separately from cash totals.
- 👥 **People & Families**: Comprehensive relationship directory with village/city, phone numbers, and full exchange history.
- 📅 **Events Management**: Create events (*Shaadi, Tilak, Mundan, etc.*) and track all incoming/outgoing transactions per event.
- 📝 **Past & Planned Records**: Track recorded transactions as well as planned gifts for upcoming events.
- 🔍 **Advanced Search & Multi-Filters**: Filter by person, village, event, date range, year, and transaction type.
- 📄 **Production Hindi PDF Reports**: 6 Devanagari-embedded A4 reports generated entirely offline.
- 📊 **Excel-Compatible CSV Export**: RFC-4180 compliant CSV exports with UTF-8 BOM encoding.
- 🔒 **Encrypted Offline Backup & Safe Restore**: AES-256-GCM + PBKDF2 password-protected local backup with atomic rollback safety.
- 🚫 **100% Offline & Private**: Zero cloud tracking, no accounts, no ads, no internet required.

---

## 🛠️ Technology Stack

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | React Native / Expo | SDK 58.0.26 / RN 0.88.1 | Cross-platform foundation |
| **Routing** | Expo Router | 58.0.32 | Type-safe file-based navigation |
| **Language** | TypeScript | 5.9.3 | Strict type safety across all platforms |
| **Database** | `expo-sqlite` | 58.0.18 | Synchronous SQLite with WAL mode |
| **Validation** | Zod | 4.6.7 | Runtime schema validation |
| **Forms** | React Hook Form | 7.92.0 | Form state management |
| **Encryption** | CryptoJS | 4.2.0 | Standard AES-256, PBKDF2 key derivation |
| **PDF Engine** | `expo-print` | 58.0.9 | High-res A4 Devanagari PDF rendering |
| **File Sharing** | `expo-sharing` / `expo-file-system` | 58.0.23 / 58.0.14 | Local file persistence & native sharing |
| **Icons** | `@expo/vector-icons` (Ionicons) | 15.1.1 | Vector iconography (zero emojis) |

---

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ (tested up to Node 26)
- `pnpm` (run `npm install -g pnpm`)
- Android device or emulator with **Expo Go** app installed

### Installation
```bash
# Clone the repository
git clone https://github.com/igjitendra/Vivah.git vyavahaar
cd vyavahaar

# Install dependencies using pnpm
pnpm install
```

### Running the App
```bash
# Start the Metro development server
pnpm start
```

---

## 🧪 Verification & Testing

The project maintains an automated test suite verifying business logic, financial rules, encryption, and data integrity:

```bash
# Run complete test suite (27/27 tests)
pnpm test

# Run pure business logic tests (16 tests)
pnpm test:logic

# Run Phase 3 features & stress tests (11 tests)
pnpm test:phase3

# Run TypeScript compiler check
pnpm typecheck
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
5. **No Emojis**: Use vector icons (`Ionicons`) exclusively.
6. **AI Instructions**: Any AI coding agent modifying this repository must follow [`AGENTS.md`](AGENTS.md).
