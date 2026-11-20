# Technology Stack & Evaluation — व्यवहार (Vyavahaar)

> **Verified Active Stack**: React Native 0.88.1 / Expo SDK 58.0.26 / TypeScript 5.9  
> **Proposed Multi-Platform Stack**: Flutter 3.24+ / Dart 3.5+ / Riverpod 2.6 / Drift ORM 2.20  
> **Scope**: 5 Target Platforms: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**  
> **Last Verified Date**: 2026-11-21

---

## 1. Active Implemented Technology Stack (React Native / Expo)

| Technology | Installed Version | Purpose | Usage / Module | 5-Platform Support |
| :--- | :--- | :--- | :--- | :--- |
| **Node.js** | 26.13.1 (LTS 18+) | JavaScript / TypeScript runtime | Build & tooling | N/A (Dev runtime) |
| **React** | 19.3.0 | Component rendering engine | UI layer | Mobile & Web |
| **React Native** | 0.88.1 | Native mobile framework | Android & iOS | Android (Verified), iOS (Ready) |
| **Expo SDK** | ~58.0.26 | Managed runtime & APIs | Core mobile engine | Mobile-first |
| **TypeScript** | ~5.9.3 | Type safety & static checking | Entire codebase | 100% cross-platform |
| **`expo-router`** | ~58.0.32 | File-based navigation | `app/` hierarchy | Mobile & Web |
| **`expo-sqlite`** | ^58.0.18 | Synchronous SQLite with WAL | `src/database/db.ts` | Mobile (C native) |
| **`crypto-js`** | ^4.2.0 | AES-256-GCM, PBKDF2 | `BackupService.ts` | 100% portable |
| **`zod`** | ^4.6.7 | Runtime validation schemas | `validation/schemas.ts` | 100% portable |
| **`expo-print`** | ~58.0.9 | HTML to A4 PDF conversion | `PdfService.ts` | Mobile & Web |
| **`expo-sharing`** | ~58.0.23 | Native share sheet | PDF, CSV, backup sharing| Android & iOS |

---

## 2. Proposed 5-Platform Cross-Platform Stack (Flutter / Dart)

For production-grade support across **Android, iOS, Linux, macOS, and Windows** from a single codebase, Flutter & Dart offer a unified compilation pipeline:

| Package | Recommended Version | Purpose | Cross-Platform Rationale |
| :--- | :---: | :--- | :--- |
| **`flutter` / `dart`** | `>=3.24 / >=3.5` | Native compiled multi-platform SDK | Compiles to native ARM/x86_64 machine code across all 5 OS. |
| **`flutter_riverpod`** | `^2.6.1` | Compile-time safe state management | Zero context leaks, highly testable without mocks. |
| **`go_router`** | `^14.6.2` | Declarative routing & deep links | Handles mobile tabs and desktop browser/window URL states. |
| **`drift`** | `^2.20.3` | Type-safe reactive SQLite ORM | Generates compile-time SQL queries, automatic schema migrations. |
| **`sqlite3_flutter_libs`** | `^0.5.26` | Bundled latest C-SQLite engine | Uniform SQLite version across all 5 OS. |
| **`freezed`** | `^2.5.7` | Immutable data classes & unions | Compile-time pattern matching for `EntryStatus` and state. |
| **`flutter_secure_storage`**| `^9.2.2` | Keystore / Keychain / SecretService | Hardware-backed secure storage on all 5 platforms. |
| **`cryptography`** | `^2.7.2` | AES-256-GCM & PBKDF2 encryption | Hardware-accelerated cryptographic operations. |
| **`pdf` & `printing`** | `^3.11.1 / ^5.13.1` | Native vector A4 PDF generation | Direct binary PDF generation with embedded Devanagari TTF. |
| **`csv`** | `^6.0.0` | RFC-4180 CSV serializer | Pure Dart CSV engine with UTF-8 BOM. |
| **`file_picker`** | `^8.1.4` | Native OS file picker dialogs | Unified native file import/export across all 5 OS. |

---

## 3. Technology Comparison & Trade-Offs

| Metric | Current Stack (React Native / Expo) | Proposed Stack (Flutter / Dart) | Analysis |
| :--- | :--- | :--- | :--- |
| **Mobile Quality (Android & iOS)** | High (Native Fabric 0.88) | High (Impeller / Skia Native) | Both deliver fluid 60/120 FPS mobile UX. |
| **Desktop Quality (Linux Desktop)** | Incomplete / Experimental | **First-Class Official Support** | Canonical officially maintains Linux GTK runner for Flutter. |
| **Desktop Quality (Windows & macOS)** | Fragmented (Separate RNW/RNM projects) | **Unified Official Support** | Flutter compiles directly to native Win32/C++ and Cocoa/Metal. |
| **Offline SQLite Parity** | `expo-sqlite` (Mobile only) | `drift` + `sqlite3` (Identical on all 5 OS) | Drift provides type-safe SQLite with zero platform differences. |
| **Single Codebase Maintenance** | High overhead for desktop | **Low overhead (1 unified `lib/` tree)** | Flutter drastically reduces multi-platform maintenance costs. |

*Detailed architectural blueprint available in [`docs/FLUTTER_MIGRATION_ARCHITECTURE.md`](FLUTTER_MIGRATION_ARCHITECTURE.md).*
