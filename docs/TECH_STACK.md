# Technology Stack — व्यवहार (Vyavahaar)

> **Verified From**: `package.json` & `pnpm-lock.yaml`  
> **Last Verified Date**: 2026-11-21  
> **Package Manager**: `pnpm` exclusively

---

## 1. Core Framework & Runtime

| Technology | Installed Version | Purpose | Source File / Module |
| :--- | :--- | :--- | :--- |
| **Node.js** | 26.13.1 (LTS compatible 18+) | JavaScript / TypeScript runtime | Build & tooling |
| **React** | 19.3.0 | Component rendering engine | Global UI |
| **React Native** | 0.88.1 | Native mobile framework (New Architecture compatible) | Android UI bridge |
| **Expo SDK** | ~58.0.26 | Managed cross-platform runtime & tools | Global foundation |
| **TypeScript** | ~5.9.3 | Type checking & static analysis | `tsconfig.json` |

---

## 2. Navigation & Application Architecture

| Library | Installed Version | Purpose | Usage |
| :--- | :--- | :--- | :--- |
| **`expo-router`** | ~58.0.32 | File-based, typed routing for React Native | `app/` hierarchy |
| **`react-native-safe-area-context`** | ~5.11.1 | Device notch, status bar & gesture navigation insets | `app/(tabs)/index.tsx`, `FloatingTabBar.tsx` |
| **`react-native-screens`** | ~4.30.1 | Native screen container primitives | Native navigation optimization |
| **`react-native-reanimated`** | 4.7.1 | Declarative native animations | Interactive transitions |

---

## 3. Local Storage, Encryption & Database

| Library | Installed Version | Purpose | Usage |
| :--- | :--- | :--- | :--- |
| **`expo-sqlite`** | ^58.0.18 | Embedded SQLite engine with synchronous WAL mode | `src/database/db.ts` |
| **`crypto-js`** | ^4.2.0 | AES-256-GCM encryption & PBKDF2 key derivation | `src/services/BackupService.ts` |
| **`expo-file-system`** | ~58.0.14 | Local device file storage and backup persistence | `BackupService.ts`, `CsvService.ts` |
| **`expo-sharing`** | ~58.0.23 | Native Android share sheet integration | Backup, PDF & CSV export sharing |
| **`expo-secure-store`** | ^58.0.3 | Encrypted keychain/keystore on-device storage | Sensitive settings storage |

---

## 4. UI Components, Forms & Validation

| Library | Installed Version | Purpose | Usage |
| :--- | :--- | :--- | :--- |
| **`zod`** | ^4.6.7 | Type-safe schema validation | `src/validation/schemas.ts` |
| **`react-hook-form`** | ^7.92.0 | High-performance uncontrolled form handling | Transaction & Event forms |
| **`@hookform/resolvers`** | ^7.0.7 | Integrates Zod with React Hook Form | Form validation bridges |
| **`@expo/vector-icons`** | ^15.1.1 | Vector iconography (`Ionicons` exclusively) | All screens & components |
| **`expo-haptics`** | ^58.0.8 | Subtle tactile vibration feedback on button & tab press | `FloatingTabBar.tsx`, quick actions |
| **`expo-status-bar`** | ~58.0.5 | Native Android status bar theme controller | `app/(tabs)/index.tsx` |

---

## 5. Reports & Printing Engine

| Library | Installed Version | Purpose | Usage |
| :--- | :--- | :--- | :--- |
| **`expo-print`** | ~58.0.9 | High-fidelity HTML to A4 PDF conversion | `src/services/PdfService.ts` |
| **`react-native-uuid`** | ^3.0.0 | Cryptographically random UUID v4 generation | Primary keys across all tables |

---

## 6. Development & Quality Assurance Tooling

| Tool / Library | Installed Version | Purpose | Command |
| :--- | :--- | :--- | :--- |
| **`pnpm`** | 12.22.0 | Fast, disk-efficient package manager | `pnpm install` |
| **`tsx`** | Latest (via `pnpm dlx`) | TypeScript execution without precompilation | `pnpm test` |
| **`@resvg/resvg-wasm`** | ^2.6.2 | High-res SVG rasterization for brand assets | `scripts/build-brand-assets.ts` |
| **`opentype.js`** | ^2.0.0 | Font metrics verification | Font embedding tools |

---

## 7. Package Manager Enforcements

- **Default Package Manager**: `pnpm` exclusively.
- **Dependency Installation Rule**: Run `pnpm dlx expo install <package>` for any new Expo-compatible dependency.
- **Never install new packages automatically** without user approval.
