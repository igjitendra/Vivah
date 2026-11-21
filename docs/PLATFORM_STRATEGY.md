# Cross-Platform Strategy & Architectural Feasibility — व्यवहार (Vyavahaar)

> **Approved Scope**: Five Target Platforms: **Android, iOS, Linux Desktop, macOS Desktop, Windows Desktop**  
> **Core Principle**: Shared Business Logic, Local-First SQLite Persistence, Tailored Platform UI/UX  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 1. Executive Summary & Vision

व्यवहार (Vyavahaar) is architected as a **multi-platform personal ledger application**. The product serves Indian households, business owners, and extended families who manage traditional gift records not only on mobile phones (Android and iOS) but also on desktop computers (Linux, macOS, and Windows) in home offices, shops, and family registries.

### Multi-Platform ≠ Cloud Synchronization
- **Multi-Platform**: The ability for the application to compile, execute natively, and store records locally on five operating system families.
- **Offline-First Storage**: Each platform installation operates as an autonomous, self-contained local ledger with its own local SQLite database via Drift ORM.
- **No Cloud Synchronization**: Phase 4 remains **DEFERRED**. The application introduces **NO** remote database, Supabase, Firebase, or online authentication.
- **Interoperability**: Data interchange between platforms is achieved through standardized, local, password-protected **AES-256-GCM encrypted JSON backups** and **Devanagari PDF/CSV exports**, safely transferred via physical storage (USB flash drives, SD cards) or local file sharing.

---

## 2. Platform Support Matrix

| Platform | Family | Interface Type | Target Priority | Current Status | Official Implementation & Verification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Android** | Mobile | Touch-First | Tier 1 (Primary) | **IMPLEMENTED** | Flutter + Material 3 implementation (`lib/`). Screen layouts, navigation, and SQLite database verified. |
| **iOS** | Mobile | Touch-First | Tier 1 (Primary) | **ARCHITECTURE READY** | Unified Flutter `lib/` codebase; cross-platform Drift SQLite and reactive Riverpod architecture. |
| **Linux** | Desktop | Keyboard & Mouse | Tier 2 | **ARCHITECTURE READY** | Flutter + Drift ORM native SQLite desktop engine ready (`lib/src/data/database/`). |
| **macOS** | Desktop | Keyboard, Mouse, Trackpad | Tier 2 | **ARCHITECTURE READY** | Flutter + Drift ORM native SQLite desktop engine ready (`lib/src/data/database/`). |
| **Windows** | Desktop | Keyboard, Mouse, Touch | Tier 2 | **ARCHITECTURE READY** | Flutter + Drift ORM native SQLite desktop engine ready (`lib/src/data/database/`). |

### Status Definitions:
- **`VERIFIED`**: Full application compiles, renders, executes all business logic, passes automated tests, and has been verified on target hardware/runtime.
- **`IMPLEMENTED`**: Code exists and compiles, awaiting full end-to-end device testing.
- **`ARCHITECTURE READY`**: Codebase uses standard cross-platform libraries compatible with the platform without breaking changes.
- **`PLANNED`**: Approved long-term target; platform adapter layer designed; native build pipeline pending.

---

## 3. Technical Implementation & 5-Platform Architecture

Flutter + Dart serves as the unified cross-platform technology stack across all 5 operating systems:

```mermaid
flowchart TD
    subgraph Shared_Dart [Unified Shared Flutter Codebase (lib/)]
        UI[Material 3 UI & ResponsiveLayout]
        State[Riverpod Providers & GoRouter]
        Domain[FinancialRules & CurrencyUtils (Paise)]
        Data[Drift ORM & SQLite Schema v4]
        Services[PdfService, CsvService, BackupService]
    end

    subgraph Native_Embedders [Official Native Platform Embedders]
        Android[Android: Gradle / NDK / JVM]
        iOS[iOS: Xcode / CocoaPods]
        Linux[Linux Desktop: GTK 3.0 / CMake / C++]
        macOS[macOS Desktop: Cocoa / Metal / Swift]
        Windows[Windows Desktop: Win32 / C++]
    end

    Shared_Dart --> Android
    Shared_Dart --> iOS
    Shared_Dart --> Linux
    Shared_Dart --> macOS
    Shared_Dart --> Windows
```

| Layer / Capability | Android | iOS | Linux Desktop | macOS Desktop | Windows Desktop |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **UI Engine** | Impeller / Skia | Impeller | Skia (GTK) | Impeller / Metal | Skia (Win32) |
| **Domain Logic** | Dart AOT | Dart AOT | Dart AOT | Dart AOT | Dart AOT |
| **Local SQLite Database** | `drift` + `sqlite3` | `drift` + `sqlite3` | `drift` + `sqlite3` | `drift` + `sqlite3` | `drift` + `sqlite3` |
| **AES-256-GCM Crypto** | `cryptography` | `cryptography` | `cryptography` | `cryptography` | `cryptography` |
| **PDF Generation** | `pdf` + `printing` | `pdf` + `printing` | `pdf` + `printing` | `pdf` + `printing` | `pdf` + `printing` |
| **CSV Export** | `csv` + `share_plus`| `csv` + `share_plus`| `csv` + `share_plus`| `csv` + `share_plus`| `csv` + `share_plus`|
| **File System Access** | `path_provider` | `path_provider` | `path_provider` | `path_provider` | `path_provider` |

---

## 4. UI/UX Strategy: Mobile vs. Desktop

| UX Dimension | Mobile (Android & iOS) | Desktop (Linux, macOS, Windows) |
| :--- | :--- | :--- |
| **Input Modality** | Touch-first, swipe gestures, virtual keyboard. | Keyboard, mouse, trackpad, multi-window. |
| **Primary Navigation** | Floating pill-shaped bottom navigation bar (`FloatingPillTabBar`). | Navigation rail / sidebar or top bar via `ResponsiveLayout`. |
| **Information Density** | Compact vertical cards, stacked statistics. | Wide multi-column tables, master-detail side panes. |
| **Forms & Data Entry** | Fullscreen modal forms with bottom action buttons. | Inline dialogs, tab-key navigation, enter-to-submit. |
| **Window Sizing** | Fixed portrait orientation (phones) / responsive tablet. | Fully resizable windows (minimum 960x600 px). |

---

## 5. Cross-Platform Local Database & Backup Interoperability

To guarantee that a backup created on an Android phone can be restored on a Linux desktop, macOS laptop, or Windows PC:
1. **Schema Parity**: SQLite schema v4 is strictly identical across all platforms.
2. **Unified Currency**: Integer paise is universally supported across every platform without floating-point errors.
3. **Crypto Parity**: AES-256-GCM and PBKDF2 (600,000 iterations) implementation in `BackupService` follows open cryptographic standards (NIST SP 800-38D, RFC 2898 / PKCS #5), allowing cross-platform encryption and decryption with zero platform-specific locks.
4. **File Format**: Backups are standardized UTF-8 JSON files with `.json` extensions, readable on any operating system.
