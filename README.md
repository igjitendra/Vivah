# व्यवहार (Vyavahaar) — Digital Family Ledger

> **रिश्तों का हिसाब, हमेशा याद।**  
> Hindi-first Android digital family ledger for recording traditional Indian transactions (shadi, baraat, tilak, mundan, etc.).

---

## 📌 Project Overview

**व्यवहार (Vyavahaar)** replaces the traditional handwritten *bahi-khata* (बही खाता) with an offline-first, easy-to-use digital ledger. It records cash gifts, physical items, relatives, events, and gives a complete transaction history with each family or person.

### Core Principles & Business Rules
1. **मिला (Received) and दिया (Given) are ALWAYS separate** — never net-combined or subtracted.
2. **All currency stored in INTEGER PAISE** — ₹1,100 is stored as `110000`. No floating-point math issues.
3. **Physical gift values are never mixed into cash totals**.
4. **No automatic debt calculation** — the ledger reminds and displays history, but does not dictate obligations.
5. **Offline-first with SQLite** — fully functional without internet access.
6. **Soft-delete pattern** — deleted records are preserved with a timestamp (`deleted_at`), never permanently wiped without explicit action.

---

## 🛠️ Tech Stack

- **Framework**: React Native + Expo (SDK 58)
- **Navigation**: Expo Router (file-based navigation with TypeScript)
- **Local Database**: `expo-sqlite` (synchronous API)
- **Language**: TypeScript (strict mode)
- **Validation**: Zod v4
- **Form State**: React Hook Form
- **Package Manager**: pnpm

---

## 📁 Project Structure

```
vyavahaar/
├── app/
│   ├── _layout.tsx           # Root navigation & SQLite initialization
│   ├── (tabs)/               # Main bottom-tab navigation
│   │   ├── _layout.tsx       # 5-tab layout (Home, Bahi, Events, People, Settings)
│   │   ├── index.tsx         # Dashboard / Home
│   │   ├── bahi.tsx          # Ledger / Bahi Khata
│   │   ├── events.tsx        # Events listing
│   │   ├── people.tsx        # People directory with search
│   │   └── settings.tsx      # DB stats, export, info
│   ├── entry/
│   │   ├── new.tsx           # Add new transaction
│   │   └── [id].tsx          # Transaction detail & soft delete
│   ├── event/
│   │   ├── new.tsx           # Create new event
│   │   └── [id].tsx          # Event details & event-specific ledger
│   └── person/
│       ├── new.tsx           # Add new person
│       └── [id].tsx          # Person profile & relationship history
├── assets/
│   └── brand/                # Approved brand SVG & PNG assets
├── src/
│   ├── components/
│   │   └── ui/               # Reusable UI component library (VCard, VButton, AmountInput, etc.)
│   ├── constants/            # Color tokens, Hindi strings
│   ├── database/             # SQLite database init, schema, migrations, stats & export
│   ├── hooks/                # React custom hooks (useDashboard, usePeople, useEntries, etc.)
│   ├── services/             # Typed feature services (People, Events, Entries, Summary, Families)
│   ├── types/                # TypeScript interface definitions
│   ├── utils/                # Currency (paise conversion), Date formatting, UUID
│   └── validation/           # Zod validation schemas
└── scripts/
    └── test-business-logic.ts # Pure business logic test suite
```

---

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ (tested on Node 26)
- `pnpm` (run `corepack enable` or `npm install -g pnpm`)
- Android device or emulator with Expo Go app installed

### Installation
```bash
# Clone and enter project directory
cd /scratch/vyavahaar

# Install dependencies with pnpm
pnpm install
```

### Running the App
```bash
pnpm start
```
Scan the QR code in the terminal using the **Expo Go** app on your Android device.

---

## 🧪 Testing & Verification

### Business Logic Tests
Run the standalone unit test suite covering currency conversion, date formatting, and Zod schemas:
```bash
pnpm dlx tsx scripts/test-business-logic.ts
```

### TypeScript Verification
Ensure all types and strict checks pass:
```bash
pnpm exec tsc --noEmit
```

---

## 🎨 Brand Identity

- **Deep Navy**: `#1F3352` (Primary actions, headers, navigation)
- **Terracotta**: `#C05A2B` (Highlights, accents, key badges)
- **Warm Cream**: `#F4EFE7` (Background surfaces, contrast)
- **Devanagari Font**: Noto Sans Devanagari

---

## 🗺️ Roadmap

- [x] **Phase 1**: Brand Identity & Vector Design System
- [x] **Phase 2**: SQLite Database Foundation, Services, Hooks & Core Screens
- [ ] **Phase 3**: Supabase Cloud Sync, PDF Export, Image Attachments for gifts
