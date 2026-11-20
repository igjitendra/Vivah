# व्यवहार (Vyavahaar) — Digital Family Ledger

> **"रिश्तों का हिसाब, हमेशा याद।"**  
> A Hindi-first, offline-first Android personal ledger and family transaction management application for traditional Indian cultural gift and money exchanges (*shadi, baraat, tilak, mundan, griha pravesh*, etc.).

[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-blue.svg)](https://www.typescriptlang.org/)
[![Expo](https://img.shields.io/badge/Expo-SDK_58-black.svg)](https://expo.dev/)
[![React Native](https://img.shields.io/badge/React_Native-0.88-61DAFB.svg)](https://reactnative.dev/)
[![SQLite](https://img.shields.io/badge/Database-SQLite_WAL-003B57.svg)](https://docs.expo.dev/versions/latest/sdk/sqlite/)
[![Tests](https://img.shields.io/badge/Tests-27%2F27_Passed-success.svg)](scripts/test-phase3-features.ts)
[![Offline First](https://img.shields.io/badge/Mode-100%25_Offline-brightgreen.svg)](docs/PRIVACY_SECURITY.md)

---

## 📖 Introduction

In Indian culture, family functions such as weddings, tilak, mundan, and festivals involve exchanging cash (*shagun / vyavahaar*) and gifts with relatives and friends. Traditionally, these transactions were recorded in handwritten red cloth-bound notebooks (*Bahi-Khata* / बही-खाता). These physical books are easily misplaced, damaged, difficult to search during reciprocal events, and hard to share with family members.

**व्यवहार (Vyavahaar)** digitizes this cultural tradition into a secure, private, offline-first mobile application:
- Search decades of family history in milliseconds.
- View exact past exchanges with any relative before attending their family function.
- Plan upcoming व्यवहार entries for future events.
- Generate beautiful, printable Hindi PDF reports with authentic Devanagari typography.
- Securely backup your family records locally with military-grade AES-256 encryption.

---

## 🌟 Core Features

- 📱 **Premium Modern UI**: Tailored Devanagari Hindi interface, custom floating pill bottom navigation, and refined financial cards.
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
| **Framework** | React Native / Expo | SDK 58.0.26 / RN 0.88.1 | Cross-platform mobile foundation |
| **Routing** | Expo Router | 58.0.32 | Type-safe file-based navigation |
| **Language** | TypeScript | 5.9.3 | Strict type safety |
| **Database** | `expo-sqlite` | 58.0.18 | Synchronous SQLite with WAL mode |
| **Validation** | Zod | 4.6.7 | Runtime schema validation |
| **Forms** | React Hook Form | 7.92.0 | Form state management |
| **Encryption** | CryptoJS | 4.2.0 | AES-256, PBKDF2 key derivation |
| **PDF Engine** | `expo-print` | 58.0.9 | High-res A4 Devanagari PDF rendering |
| **File Sharing** | `expo-sharing` / `expo-file-system` | 58.0.23 / 58.0.14 | Native Android share sheet integration |
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
Scan the displayed QR code using the **Expo Go** app on your Android phone.

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

1. **Phase 4 (Cloud & Sync) is DEFERRED**: Do not implement cloud databases, Supabase, Firebase, or online authentication.
2. **Never Net-Combine Finances**: Never subtract Given from Received.
3. **Integer Currency Only**: Never use floating-point numbers for money calculations.
4. **No Emojis**: Use vector icons (`Ionicons`) exclusively.
5. **AI Instructions**: Any AI coding agent modifying this repository must follow [`AGENTS.md`](AGENTS.md).
