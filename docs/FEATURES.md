# Feature Catalogue — व्यवहार (Vyavahaar)

> **Document Version**: 2.0  
> **Status**: Comprehensive Inventory of All Features  
> **Last Updated**: 2026-11-21

---

## 1. Feature Breakdown by Module

### 1.1 Dashboard / Home (`app/(tabs)/index.tsx`)
- **Header**: Deep Navy compact header with app name, tagline, and quick settings access.
- **Financial Cards**: Balanced horizontal display of *Kul Mila* (Received) and *Kul Diya* (Given) in authentic ₹ formatting with green/red styling.
- **Unified Statistics Bar**: Compact single-surface row showing actual counts of *Karyakram* (Events), *Vyakti* (People), and *Vyavahaar* (Transactions).
- **Recent Event Card**: Clean card displaying the latest event with direct navigation to event details.
- **Quick Action Tiles**: Prominent Terracotta primary button for *Naya Vyavahaar*, plus secondary tiles for *Naya Karyakram* and *Naya Vyakti*.
- **Lifecycle Integration**: Pull-to-refresh and `useFocusEffect` auto-refresh on screen focus.

### 1.2 Bahi Khata / Ledger (`app/(tabs)/bahi.tsx`)
- **Direction Filters**: Toggle between *Sabhi* (All), *Mila* (Received), and *Diya* (Given).
- **Entry Cards**: Direction badge, amount, counterparty name, village/city, event title, and date.
- **Interactive Routing**: Tapping any card opens the transaction detail view (`app/entry/[id].tsx`).
- **Floating Button**: Quick access to add new transaction.

### 1.3 People & Relationship History (`app/(tabs)/people.tsx` & `app/person/[id].tsx`)
- **People Directory**: Alphabetical/recency listing with search bar querying name, village, and relationship.
- **Person Profile**:
  - Personal info: Name, village, relationship tag, phone number with native dialer link, notes.
  - Reciprocal balance sheet: Total cash received and total cash given to this person.
  - Complete history: Chronological list of every transaction, gift, and event shared with this person.
- **Add Person**: Modal form with validation for name, village, relationship, and optional phone.

### 1.4 Events Management (`app/(tabs)/events.tsx` & `app/event/[id].tsx`)
- **Events Directory**: Lists all family functions with event type badges (*Shaadi, Tilak, Mundan, etc.*) and event dates.
- **Event Detail & Ledger**:
  - Event title, type, date, and description.
  - Event-specific totals: Total Mila, Total Diya, and number of entries.
  - Complete guest list and gifts received/given during this specific event.
- **Add Event**: Form with title, event type picker, date picker, and optional guest of honor.

### 1.5 Transaction Entry & Editing (`app/entry/new.tsx` & `app/entry/[id].tsx`)
- **Dual Direction**: One-tap toggle between *Mila* (Received) and *Diya* (Given).
- **Status Selector**: Choose between *Darj Kiya Gaya* (`recorded`) and *Yojana* (`planned`).
- **Amount Input**: Real-time rupee formatting with integer paise validation.
- **Counterparty & Event Selectors**: Quick pick from existing people/events with inline creation.
- **Physical Gift Items**: Add multiple items with item name, quantity, unit, and optional estimated valuation.
- **Soft Deletion**: Safe deletion preserving audit timestamp.

### 1.6 Reports & Exports (`app/reports/index.tsx`)
- **6 A4 Devanagari Hindi PDF Reports**:
  1. Complete Vyavahaar Ledger Report.
  2. Person-wise Relationship History Report.
  3. Event-wise Function Report.
  4. Year-wise Annual Summary Report.
  5. Gift/Item-wise Physical Inventory Report.
  6. Custom Date Range Report.
- **CSV Data Export**: RFC-4180 compliant CSV with UTF-8 BOM (`\uFEFF`) for seamless opening in Excel.
- **Native Share Integration**: Direct sharing via WhatsApp, Gmail, Drive, or local file save.

### 1.7 Backup, Restore & Security (`app/(tabs)/settings.tsx`)
- **Plain Offline Backup**: Full database serialization to JSON format for local storage.
- **AES-256 Encrypted Backup**: Password-protected encrypted backup file using PBKDF2 key derivation and unique salt/IV.
- **Safe Restore Engine**:
  - Automatic pre-restore safety snapshot of active data.
  - Integrity and password validation before database modification.
  - Atomic transaction replacement with automatic rollback if corruption occurs.
  - Support for restoring both plain and encrypted backup files.
