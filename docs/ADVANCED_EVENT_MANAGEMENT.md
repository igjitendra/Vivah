# व्यवहार (Vyavahaar) — Advanced Event Management System

## 1. Executive Summary & Overview

The Advanced Event Management System upgrades the basic single-date event functionality of व्यवहार into a complete, culturally nuanced, production-grade event planning and financial tracking ecosystem. 

Designed specifically for traditional Indian family events (विवाह, मुंडन, सगाई, गृह प्रवेश, आदि), the system accommodates multi-day, multi-ceremony celebrations with deep interconnection to People, Family, Transactions, and Ledger modules while maintaining absolute offline reliability and zero-data-loss guarantees.

---

## 2. Core Relational Schema (Version 5 & Version 9 Migration)

The system introduces SQLite Schema v5 (plus Schema v9 2-Type Event Scope support and self-healing `archived_at = NULL` repair) with non-destructive `ALTER TABLE` upgrades and 10 relational child tables governed by foreign keys and cascades.

### A. Extended `events` Table
| Column | Type | Description |
|---|---|---|
| `event_scope` | `TEXT` | `'ownFamily'` (household event) or `'relative'` (invited relative event, Schema v9) |
| `host_person_id` | `TEXT` | Linked `people.id` of hosting relative for `'relative'` events (Schema v9) |
| `host_person_name` | `TEXT` | Host relative display name (Schema v9) |
| `attending_family_note` | `TEXT` | Household members attending summary (Schema v9) |
| `category` | `TEXT` | Predefined or custom event category |
| `end_date` | `TEXT` | Multi-day celebration ending date (ISO 8601) |
| `start_time` | `TEXT` | Primary function start time (`HH:mm`) |
| `end_time` | `TEXT` | Primary function completion time (`HH:mm`) |
| `is_all_day` | `INTEGER` | Boolean flag (1 = All Day) |
| `status` | `TEXT` | `draft`, `planned`, `confirmed`, `inProgress`, `completed`, `cancelled`, `archived` |
| `priority` | `TEXT` | `low`, `normal`, `high`, `urgent` |
| `budget_estimated_paise` | `INTEGER` | Overarching budget in paise (e.g. ₹5,00,000 = 50,000,000 paise) |
| `address` | `TEXT` | Detailed venue street address |
| `village_city` | `TEXT` | City, town, or ancestral village |
| `landmark` | `TEXT` | Navigational landmark |
| `map_link` | `TEXT` | Google Maps navigation link or coordinates |
| `description` | `TEXT` | Detailed event brief and instructions |

### B. Child Relational Entities
1. **`event_functions`**: Sub-ceremonies under parent event (e.g., हल्दी, मेहंदी, बारात, वरमाला, रिसेप्शन). Supports individual date, time, venue, and status (`ON DELETE CASCADE`).
2. **`event_participants`**: Role assignments linking people and families (Host, Bride, Groom, Organizer, Guest of Honour, Family Member). Linked to `people` and `families` via `ON DELETE SET NULL`.
3. **`event_guests`**: RSVP and invitation management. Tracks invitation status (`notSent`, `sent`, `accepted`, `declined`, `maybe`), attendance status (`notConfirmed`, `attending`, `notAttending`, `attended`), accompanying guest count, and notes (`ON DELETE CASCADE`).
4. **`event_tasks`**: Checklist items with assigned owners, due dates, priority tags, and status (`pending`, `inProgress`, `completed`, `cancelled`).
5. **`event_schedule_items`**: Chronological minute-by-minute itinerary items linked to ceremonies.
6. **`event_budget_categories`**: Itemized budget allocations (Catering, Venue, Clothing, Decoration, Gifts, Photography, etc.).
7. **`event_notes`**: Timestamped instructions, catering contacts, and reminders.
8. **`event_attachments`**: Documents and invitation cards stored locally with file size and type metadata.
9. **`event_activity_logs`**: Immutable audit logs capturing status transitions, edits, cancellations, and duplicate operations.
10. **`event_reminders`**: Offline event alarms and due-date notifications.

---

## 3. UI/UX Architecture & Progressive Disclosure

### A. Add / Edit Event Screen (`AddEventScreen`)
- **Essential Core Section**: Immediate entry of Title, Event Type, Priority, Date, End Date, Start/End Time, All-Day toggle, and Venue.
- **Expandable Advanced Accordions**:
  1. *Sub-Ceremonies (रस्में व कार्यक्रम)*: Add multiple functions with individual timings and venues.
  2. *People & Family Association (लोग व परिवार)*: Select existing contacts, assign roles, or tap "+ नया व्यक्ति जोड़ें" to create a new person inline without losing form data.
  3. *Location & Navigation (स्थान व पता)*: Street address, Village/City, Landmark, and Google Maps URL.
  4. *Task Checklist (चेकलिस्ट)*: Pre-populate key event milestones.
  5. *Budget & Reminders (बजट व अनुस्मारक)*: Target budget and offline reminder presets (1 day, 3 days, 7 days, 15 days, 30 days before).
- **Real-Time Conflict Detection**: Non-intrusive warning banners flagging overlapping dates/times with other family celebrations.

### B. Event Detail Screen (`EventDetailScreen`)
Structured into 8 dedicated Material 3 tabs:
1. **अवलोकन (Overview)**: Event Scope badge (Own Family vs Host Relative with tappable profile jump & attending members note), live Budget/Remaining progress bar, 4 tappable KPI cards jumping directly to Checklist, Guests/Invitations, Mila, and Diya tabs, quick `+ शगुन मिला / दिया` actions, and upcoming sub-ceremonies.
2. **रस्में (Functions & Schedule)**: Chronological timeline of all functions and scheduled itinerary items.
3. **लोग (People & Families)**: Linked hosts, bride/groom, organizers, and families with phone shortcuts.
4. **मेहमान (Guests & Invitations)**: Full Invitation & RSVP Command Center — live summary (`कुल परिवार`, `निमंत्रण गया`, `निमंत्रण बाकी`, `कुल सदस्य`), **Bulk Import from People Directory** (`रिश्तेदारों से जोड़ें`), status filter pills (`सभी`, `निमंत्रण गया`, `बाकी है`, `आएंगे`, `नहीं आएंगे`), search, 1-tap Invitation Sent/Pending toggle, quick RSVP selector, personalized guest invite copy, and sent-vs-pending status report copy.
5. **कार्य (Tasks & Checklist)**: Visual progress bar (`X/Y कार्य (Z%)`), quick status toggle checkboxes, and priority tags.
6. **बजट (Budget & Ledger)**:
   - Budget vs Spent vs Remaining (`शेष बचा`) progress bar and Mila/Diya summary.
   - Category-wise expense cards with preset Indian wedding/event categories (`टेंट व सजावट`, `खान-पान / हलवाई`, etc.), vendor/payee notes (`कहाँ / किसको`), remaining per category, and 1-tap `+ खर्चा जोड़ें` quick-entry (with optional auto-linked `Diya` ledger transaction).
   - Automatic Payee/Vendor-wise breakdown (`किसको / कहाँ कितना दिया`) aggregated from recorded given entries.
   - Direct "+ दिया / खर्चा जोड़ें" and "+ शगुन मिला जोड़ें" actions linking straight to `/entry/new?eventId=...`.
   - Printable PDF & CSV ledger export.
7. **नोट्स (Notes & Attachments)**: Instruction notes and locally attached files.
8. **इतिहास (Reminders & Activity Log)**: Configured alarms and chronological audit log.

### C. Events List & Calendar (`EventsListScreen`)
- **2-Type Scope Switcher**: Segmented switcher for `All`, `Own Family` (`अपना परिवार`), and `Relative Event` (`रिश्तेदार का आयोजन`) with live counts, host/attending badges, upcoming countdown pills, live Mila/Diya totals, and 1-tap Shagun quick actions.
- **View Toggle**: List View / Interactive Month Calendar View.
- **Filter Chips**: All, Upcoming, Today, Completed, Draft, Archived.
- **Calendar Engine**:
  - Month-by-month navigation with quick "आज (Today)" jump.
  - Event indicator dots on days with scheduled celebrations.
  - Tapping any calendar day filters and displays events scheduled for that day below.
- **Sort Options**: Date Ascending (Upcoming first), Date Descending (Latest first), Name A-Z, Priority (Urgent first).
- **Responsive Dual-Pane**: Master-detail view on tablets and wide screens.

---

## 4. Financial Non-Destructive Invariants

To guarantee that cultural financial records remain 100% sacred and untampered:
1. **Separation of Workflows**: Event planning and transaction entries are completely decoupled. Creating or editing an event NEVER generates automated financial records.
2. **Safe Deletion Policy**:
   - `entries` table holds `FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL`.
   - When an event is deleted via `deleteEventSafely(id)`, all linked transaction records have their `event_id` safely nullified.
   - Zero cash transactions, Mila records, or Diya records are ever deleted.
3. **Accounting Integrity**:
   - Total Received (मिला) and Total Given (दिया) calculations remain strictly isolated without arithmetic netting.
   - Budget calculations only sum recorded expenses and ignore planned/cancelled entries.

---

## 5. Conflict Detection Engine

The repository exposes `detectConflicts(Event event)` checking:
1. **Calendar Collisions**: Identifies active events whose date ranges intersect with the new event.
2. **Duplicate Titles**: Flags if an event with the exact same name already exists in the same calendar month.
3. **Task Due Dates**: Flags tasks with deadlines set after the event conclusion date.

---

## 6. Verification & Test Suite

The system is tested and verified across three independent test tiers:
1. **Multilingual Architecture Test (`test-multilingual-architecture.py`)**: 22/22 tests passed (100% key parity across English, Hindi, and Urdu).
2. **Database Architecture Test (`test-database-architecture.py`)**: 14/14 tests passed (Foreign keys, cascade integrity, 31,700-row scale test).
3. **Advanced Event Architecture Test (`test-advanced-event-architecture.py`)**: 10/10 tests passed (Schema v5, 10 child tables, guest RSVP tallies, task progress, financial isolation, conflict detection).
4. **Flutter Domain Unit Tests (`test/unit/event_management_test.dart`)**: 5/5 test groups covering budget utilization, task percentages, guest headcounts, and immutability.

---

## 7. Offline Event QR Sharing & Header Scanner

- **Offline Payload (`EventQrService`)**: Serializes event metadata (`title`, `eventType`, `eventDate`, `venue`, `villageCity`, host family/relative name, notes, and up to 8 ceremony functions) into a compact JSON QR payload requiring zero internet access.
- **QR Card Generation (`EventQrSheet`)**: Automatically prompts after creating a new event in `AddEventScreen`, and is accessible anytime from `EventDetailScreen` AppBar/menu. Supports high-DPI PNG image sharing via `share_plus`.
- **Header QR Scanner (`EventQrScannerScreen`)**: Accessible directly from the Home Dashboard hero header and Events List AppBar (`/scan-event`). Supports live camera scanning (`mobile_scanner`) with flash & camera toggle as well as gallery image scanning, validates Vyavahaar QR payloads, warns on duplicate events, and saves imported events with editable host info and `EventScope` selection.
