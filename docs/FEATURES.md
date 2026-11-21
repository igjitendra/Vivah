# Feature Catalogue — व्यवहार (Vyavahaar)

> **Document Version**: 3.0  
> **Status**: Comprehensive Inventory of All Features (Flutter + Dart Implementation)  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 1. Feature Breakdown by Module

### 1.1 Dashboard / Home (`lib/src/features/dashboard/presentation/dashboard_screen.dart`)
- **Header**: Deep Navy compact header with app name, tagline, and quick settings access.
- **Financial Cards**: Balanced horizontal display of *Kul Mila* (Received) and *Kul Diya* (Given) in authentic ₹ formatting with green/terracotta styling.
- **Unified Statistics Bar**: Compact single-surface row showing actual counts of *Karyakram* (Events), *Vyakti* (People), and *Vyavahaar* (Transactions).
- **Recent Event Card**: Clean card displaying the latest event with direct navigation to event details.
- **Quick Action Tiles**: Prominent Terracotta primary button for *Naya Vyavahaar*, plus secondary tiles for *Naya Karyakram* and *Naya Vyakti*.
- **Lifecycle Integration**: Reactive Riverpod streams automatically refresh view when database records change.

### 1.2 Bahi Khata / Ledger (`lib/src/features/ledger/presentation/ledger_screen.dart`)
- **Direction Filters**: Toggle between *Sabhi* (All), *Mila* (Received), and *Diya* (Given).
- **Entry Cards**: Direction badge, amount, counterparty name, village/relationship, event title, and date.
- **Interactive Routing**: Tapping any card opens the transaction detail view (`/entry/:id`).
- **Floating Button**: Quick access to add new transaction.

### 1.3 People & Relationship History (`lib/src/features/people/presentation/`)
- **People Directory** (`people_list_screen.dart`): Alphabetical/recency listing with search bar querying name, village, and relationship.
- **Person Profile** (`person_detail_screen.dart`):
  - Personal info: Name, village, relationship tag, phone number, notes.
  - Reciprocal balance sheet: Total cash received and total cash given to this person.
  - Complete history: Chronological list of every transaction, gift, and event shared with this person.
- **Add Person** (`add_person_screen.dart`): Form with validation for name, village, relationship, and optional phone.

### 1.4 Events Management (`lib/src/features/events/presentation/`)
- **Events Directory** (`events_list_screen.dart`): Lists all family ceremonies with event type badges (*Shaadi, Tilak, Mundan, etc.*) and event dates.
- **Event Detail & Ledger** (`event_detail_screen.dart`):
  - Event title, type, date, venue, and description.
  - Event-specific totals: Total Mila and Total Diya (never combined or netted), and number of entries.
  - Complete guest list and gifts received/given during this specific event.
- **Add Event** (`add_event_screen.dart`): Form with title, event type picker, date picker, and venue.

### 1.5 Transaction Entry & Detail (`lib/src/features/entries/presentation/`)
- **Add Transaction** (`add_entry_screen.dart`):
  - Dual Direction: One-tap toggle between *Mila* (Received) and *Diya* (Given).
  - Status Selector: Choose between *Darj Kiya Gaya* (`recorded`) and *Yojana* (`planned`).
  - Amount Input: Real-time rupee formatting with integer paise validation.
  - Counterparty & Event Selectors: Pick from existing people/events.
  - Physical Gift Items: Add multiple items with item name, quantity, unit, and optional estimated valuation.
- **Transaction Detail** (`entry_detail_screen.dart`):
  - View full details, relative profile link, event link, items list.
  - Mark planned transactions as recorded.
  - Cancel planned transactions.
  - Soft archiving with confirmation dialog.

### 1.6 Reminders / अनुस्मारक (`lib/src/features/reminders/presentation/reminders_screen.dart`)
- **Reminders Directory**: Track upcoming ceremonies and planned gifts.
- **Completion Toggle**: Checkbox to mark reminders completed with visual strike-through.
- **Creation Dialog**: Add new reminder with title, date picker, and notes.
- **Swipe-to-Delete**: Dismissible card to delete obsolete reminders.

### 1.7 Multilingual Language Selection (`lib/src/core/localization/presentation/language_selector_screen.dart`)
- **22 Eighth Schedule Indian Languages**: Searchable catalogue of official Indian languages with English fallback.
- **Native Script Names & Direction**: Displays native names (e.g. हिन्दी, বাংলা, اردو) and badges for RTL scripts.
- **Instant Persistence**: Updates active locale in Riverpod and persists to SQLite `app_settings`.

### 1.8 Reports & Exports (`lib/src/features/reports/presentation/reports_screen.dart`)
- **A4 Devanagari Hindi PDF Reports**: High-resolution vector PDF reports with embedded Google Noto Sans Devanagari fonts via `pdf` and `printing`.
- **Excel-Compatible CSV Export**: RFC-4180 compliant CSV with UTF-8 BOM (`\uFEFF`) for seamless opening in Microsoft Excel.
- **System Share Sheet**: Direct sharing via WhatsApp, Gmail, Drive, or local storage.

### 1.9 Backup, Restore & Security (`lib/src/features/settings/presentation/settings_screen.dart`)
- **AES-256-GCM Encrypted Backup**: Password-protected encrypted backup file using OWASP PBKDF2 (600,000 iterations), unique 128-bit salt, and 12-byte nonce.
- **Safe Restore Engine**:
  - Pre-restore validation and decryption in memory.
  - Atomic database transaction replacement with automatic rollback on error.
  - File picker integration for native backup file selection across platforms.
