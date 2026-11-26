# व्यवहार (Vyavahaar) — Advanced Contacts Import & People Management System

## 1. Executive Summary & Purpose

The Advanced Contacts Import & People Management System upgrades the existing People and Relatives directory in व्यवहार into a complete, privacy-respecting, production-grade contact management ecosystem.

It allows users to import contacts directly from their phone address book or universal vCard (.vcf) files, manage rich profiles (multiple phone numbers, WhatsApp, emails, ancestral village, family relations, professional details), resolve duplicate contacts with a side-by-side field chooser, trigger direct communications (Call, SMS, WhatsApp, Email), and perform bulk operations—all while maintaining an absolute 100% offline guarantee and zero-data-loss protection for historical financial ledgers.

---

## 2. Core Relational Schema (Version 6 Migration)

The system introduces SQLite Schema v6 with backward-compatible `ALTER TABLE` upgrades and normalized child tables for secondary phone numbers and email addresses.

### A. Extended `people` Table
| Column | Type | Default | Description |
|---|---|---|---|
| `first_name` | `TEXT` | `NULL` | Given name |
| `middle_name` | `TEXT` | `NULL` | Middle name |
| `last_name` | `TEXT` | `NULL` | Family / surname |
| `nickname` | `TEXT` | `NULL` | Informal / pet name (e.g. बबुआ, चिंटू) |
| `gender` | `TEXT` | `NULL` | Optional gender tag |
| `date_of_birth` | `TEXT` | `NULL` | ISO 8601 Date (`YYYY-MM-DD`) |
| `photo_path` | `TEXT` | `NULL` | Local path to cached profile picture |
| `whatsapp_number` | `TEXT` | `NULL` | Explicit WhatsApp number if different from primary |
| `village` | `TEXT` | `NULL` | Ancestral village or neighborhood |
| `city` | `TEXT` | `NULL` | City / town |
| `district` | `TEXT` | `NULL` | Administrative district |
| `state` | `TEXT` | `NULL` | State or province |
| `pin_code` | `TEXT` | `NULL` | Postal PIN code |
| `relationship_notes` | `TEXT` | `NULL` | Detailed notes on family relation |
| `occupation` | `TEXT` | `NULL` | Profession or job title |
| `company` | `TEXT` | `NULL` | Employer or business name |
| `tags` | `TEXT` | `NULL` | Comma-separated categorization tags |
| `contact_source` | `TEXT` | `'manual'` | Source: `'manual'` or `'phone_import'` |
| `external_contact_id` | `TEXT` | `NULL` | Original phone contact book identifier |
| `imported_at` | `TEXT` | `NULL` | ISO timestamp of original import |
| `is_app_edited_after_import` | `INTEGER` | `0` | Boolean flag indicating post-import edits |

### B. Normalized Child Tables
1. **`person_phones`**:
   - `id TEXT PRIMARY KEY`, `person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE`
   - `phone_number TEXT NOT NULL`, `label TEXT`, `is_primary INTEGER DEFAULT 0`
2. **`person_emails`**:
   - `id TEXT PRIMARY KEY`, `person_id TEXT NOT NULL REFERENCES people(id) ON DELETE CASCADE`
   - `email TEXT NOT NULL`, `label TEXT`, `is_primary INTEGER DEFAULT 0`

### C. Performance Indexes
- `idx_people_phone`: Fast lookup on primary phone
- `idx_people_ext_id`: Fast lookup on native contact ID
- `idx_person_phones_person` & `idx_person_phones_num`: Fast secondary phone searches
- `idx_person_emails_person`: Fast email matching

---

## 3. Contact Import Architecture & Flow

### A. Dual Entry Options
On the **Add Person** screen and the **People Directory**, users are presented with clear entry pathways:
1. **Add Manually (मैन्युअल जोड़ें)**: Traditional guided form.
2. **Import from Phone Contacts (फ़ोन संपर्क से आयात करें)**: Native address book integration.
3. **Import from vCard (.vcf) File (vCard फ़ाइल से आयात करें)**: Universal file-based import across all platforms.

### B. Multi-Contact Review & Selection
When importing:
- Displays a dedicated review sheet with search and checkboxes.
- Users can review, select, or deselect contacts before persisting.
- Allows assigning a common Family or Relationship tag to the imported batch.
- Batch inserts contacts efficiently in a single atomic database transaction.

### C. Universal vCard (.vcf) Engine
- Custom-built parser compliant with vCard 2.1, 3.0, and 4.0 specifications.
- Extracts `FN`, `N`, `NICKNAME`, `TEL`, `EMAIL`, `ADR`, `ORG`, `TITLE`, `BDAY`, and `NOTE`.
- Enables seamless migration of contacts from Google Contacts, iCloud, Outlook, or Android/iOS contact exports without internet access.

---

## 4. Duplicate Detection & Merge Engine

To prevent cluttering the directory with duplicate relatives:

### A. Matching Signals
1. **Normalized Phone Number Matching**:
   - Strips country code (`+91`), spaces, hyphens, parentheses, and leading zeros (`+91 98765-43210` -> `9876543210`).
   - Checks against both primary phone and all secondary phone numbers.
2. **Normalized Email Matching**: Case-insensitive trimmed match.
3. **External Contact ID**: Matches native device contact IDs.
4. **Secondary Name Match**: Exact full-name match as a secondary advisory signal.

### B. Resolution Dialog (`DuplicateReviewDialog`)
When a duplicate is detected, the user can choose:
1. **Skip (छोड़ें)**: Omit incoming contact from import.
2. **Import as Separate Person (अलग व्यक्ति के रूप में जोड़ें)**: Create a new distinct person record.
3. **Merge with Existing Person (मौजूदा व्यक्ति में विलय करें)**:
   - Interactive side-by-side field chooser.
   - User picks which fields to update (Name, Primary Phone, Address, Job, Company).
   - **Non-Destructive Invariant**: Secondary phones and emails are combined without dropping existing records.
   - **Ledger Invariant**: All existing financial transactions (`entries`) remain linked to the person's existing ID. Zero historical ledger data is ever duplicated or lost.

---

## 5. Communications & External Actions

One-tap direct intent triggers integrated via `url_launcher`:
- **Phone Call**: `tel:<cleanNumber>`
- **SMS**: `sms:<cleanNumber>`
- **WhatsApp**: Direct chat trigger via `whatsapp://send?phone=+91<number>` with graceful fallback to `https://wa.me/`
- **Email**: `mailto:<email>`
- **Share Contact Card**: Formatted Devanagari text summary shared via system share sheet
- **vCard Export**: Generates `.vcf` file and shares via `share_plus`
- **CSV Export**: Generates `.csv` spreadsheet with all fields and shares via `share_plus`

### 5.1 Pro-Level Relative Ledger Snapshot & Direct Actions
- **Live Ledger Snapshot Badge**: Every person card in `PeopleListScreen` calculates and displays their total received (`मिला: ₹...`, Emerald Green) and given (`दिया: ₹...`, Diya Red) with total transactions badge.
- **Smart Multi-Sorting**: Relatives can be sorted by Name (`A-Z`), Most Transactions (`सर्वाधिक लेन-देन`), Highest Received (`सर्वाधिक मिला`), Highest Given (`सर्वाधिक दिया`), and Recently Added (`हाल ही में जोड़े गए`).
- **Activity & Source Filters**: Filter chips include All (`सारे`), Active Ledger (`सक्रिय लेन-देन`), Zero Transactions (`बिना लेन-देन`), Phone Contacts (`फ़ोन से आयातित`), and Manual Entries (`मैन्युअल प्रविष्टि`).
- **One-Tap Quick Entry**: Each relative card provides a direct `+ व्यवहार जोड़ें` menu with pre-selected relative parameters for instant Mila/Diya logging. Profile page provides dual prominent tactile action buttons (`+ मिला दर्ज करें` and `+ दिया दर्ज करें`).

---

## 6. Financial Ledger Invariants & Safe Deletion

1. **Separation of Concerns**: Contact management and financial ledger transactions remain strictly decoupled. Editing or importing contacts never generates automated transactions.
2. **Safe Deletion Policy**:
   - The database enforces `FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT`.
   - `canDeletePerson(id)` inspects active entries.
   - If a person has transactions, the app prevents hard deletion and offers **Soft Archival** (`archived_at`).
   - Financial entries (`entries`), Mila/Diya totals, and item details are 100% preserved.

---

## 7. Platform Compatibility Matrix

| Feature | Android | iOS | Windows | macOS | Linux |
|---|---|---|---|---|---|
| Native Contact Picker | ✅ Full | ✅ Full | ❌ Unsupported | ✅ Full | ❌ Unsupported |
| Batch Contact Read | ✅ Full | ✅ Full | ❌ Unsupported | ✅ Full | ❌ Unsupported |
| vCard (.vcf) File Import | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| vCard & CSV Export | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Dial & SMS Intent | ✅ Full | ✅ Full | ❌ Unsupported | ❌ Unsupported | ❌ Unsupported |
| WhatsApp & Email Trigger | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Local SQLite Persistence | ✅ Full | ✅ Full | ✅ Full | ✅ Full | ✅ Full |

---

## 8. Verification & Test Suite

1. **Architecture & Schema Test (`test-contacts-and-people-architecture.py`)**: 10/10 tests passed (100% success).
2. **Multilingual Localization Parity (`test-multilingual-architecture.py`)**: 22/22 tests passed (English, Hindi, Urdu parity).
3. **Database Architecture Test (`test-database-architecture.py`)**: 14/14 tests passed (31,700-row scale test).
4. **Advanced Event Architecture Test (`test-advanced-event-architecture.py`)**: 10/10 tests passed.
5. **Domain Unit Tests (`test/unit/contacts_and_people_test.dart`)**: 5/5 unit test groups passed.
6. **Schema Migration & UPSERT Integrity (`test/unit/people_migration_test.dart`)**: Verifies Schema v8 self-healing extended columns (`first_name`, `whatsapp_number`, `contact_source`, `person_phones`, `person_emails`) and `ON CONFLICT(id) DO UPDATE` safe in-place updates preserving foreign-key-referenced transactions.
