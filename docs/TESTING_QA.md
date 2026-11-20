# Testing Strategy & Quality Assurance — व्यवहार (Vyavahaar)

> **Test Suites**: `scripts/test-business-logic.ts`, `scripts/test-phase3-features.ts`  
> **Total Automated Tests**: 27 Tests (27/27 Passing)  
> **Last Verified Date**: 2026-11-21

---

## 1. Test Architecture Overview

```mermaid
flowchart TD
    Suite[pnpm test] --> T1[test:logic: 16 Tests]
    Suite --> T2[test:phase3: 11 Tests]

    subgraph Logic [Business Logic & Type Validation]
        T1 --> C1[Currency Utils - Integer Paise]
        T1 --> D1[Date Formatting - Hindi Dates]
        T1 --> Z1[Zod Schemas - Entry, Person, Event]
    end

    subgraph Phase3 [Phase 3 MVP Features & Scale]
        T2 --> F1[Financial Rules & Totals Separation]
        T2 --> E1[AES-256 Encryption & PBKDF2]
        T2 --> R1[Safety Snapshot & Atomic Rollback]
        T2 --> S1[31,500 Records Scale Stress Test]
    end
```

---

## 2. Automated Test Catalog & Results

### 2.1 Pure Business Logic Suite (`scripts/test-business-logic.ts`)
Run command: `pnpm test:logic`

| Category | Test Case Description | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| **Currency** | ₹1,100 = 110,000 paise conversion | `rupeesToPaise(1100) === 110000` | **PASS** |
| **Currency** | 110,000 paise = ₹1,100 conversion | `paiseToRupees(110000) === 1100` | **PASS** |
| **Currency** | `formatCurrency(110000)` formatting | Returns `"₹1,100"` with comma grouping | **PASS** |
| **Currency** | `formatCurrency(0)` zero check | Returns `"₹0"` | **PASS** |
| **Currency** | Floating-point error immunity | `paiseToRupees(rupeesToPaise(19.99)) === 19.99` | **PASS** |
| **Currency** | Mila & Diya strictly separate storage | Independent totals, zero net debt | **PASS** |
| **Date** | `getTodayDateString()` format check | Returns valid `YYYY-MM-DD` | **PASS** |
| **Date** | `formatDate()` handles ISO strings | Formats date cleanly without throwing | **PASS** |
| **Validation** | `CreatePersonSchema` valid input | Successfully validates valid person object | **PASS** |
| **Validation** | `CreatePersonSchema` empty name check | Throws validation error on empty string | **PASS** |
| **Validation** | `CreateEventSchema` valid input | Successfully validates valid event object | **PASS** |
| **Validation** | `CreateEventSchema` bad date format | Rejects invalid date format | **PASS** |
| **Validation** | `CreateEventSchema` invalid event_type | Rejects unapproved event type string | **PASS** |
| **Validation** | `CreateEntrySchema` valid mila entry | Validates cash and direction | **PASS** |
| **Validation** | `CreateEntrySchema` negative paise | Rejects negative currency values | **PASS** |
| **Validation** | `CreateEntrySchema` invalid direction | Rejects non-'mila'/'diya' direction strings | **PASS** |

### 2.2 Phase 3 Comprehensive Feature Suite (`scripts/test-phase3-features.ts`)
Run command: `pnpm test:phase3`

| Category | Test Case Description | Expected Result | Status |
| :--- | :--- | :--- | :--- |
| **Financial Rules** | Mila & Diya amounts strictly separated | `milaTotal` and `diyaTotal` never subtracted | **PASS** |
| **Financial Rules** | Gift estimates excluded from cash totals | Item estimated value does not inflate cash | **PASS** |
| **Financial Rules** | Planned & cancelled excluded from totals | `status != 'recorded'` ignored in sums | **PASS** |
| **Date Shaping** | Devanagari Hindi date formatting | Formats day, Hindi month, year accurately | **PASS** |
| **Encryption** | Unique salt and IV per backup | Two consecutive backups produce different salt/IV | **PASS** |
| **Encryption** | Decryption with valid password | Restores exact byte-for-byte JSON payload | **PASS** |
| **Encryption** | Rejection of invalid password | Throws decryption failure error | **PASS** |
| **Encryption** | Detection of tampered ciphertext | Detects corrupted HMAC and aborts restore | **PASS** |
| **Safety Restore** | In-memory safety snapshot capture | Deep copy of all active tables captured | **PASS** |
| **Safety Restore** | Atomic rollback on restore failure | Previous SQLite state restored automatically | **PASS** |
| **Scale Stress Test** | 31,500 records in memory query speed | 1,000 people, 500 events, 10K entries, 20K items queried in **<30ms** | **PASS** |

---

## 3. Performance Benchmark & Stress Testing

Tested on SQLite in-memory and file storage:
- **Generated Dataset**:
  - `1,000` People
  - `500` Ceremonial Events
  - `10,000` Transaction Entries
  - `20,000` Physical Gift Items
  - **Total Entity Count**: `31,500` records
- **Query Performance**:
  - Full aggregate summary query executed in **9ms** (file-cached) to **26ms** (cold start).
  - Search query over indexed fields (`name`, `village`, `direction`) executed in **4ms**.
  - Confirms SQLite WAL mode easily supports decades of family ledger history.

---

## 4. Manual Regression Checklist

Before every release build:
1. [x] **Home Screen**: Header, financial summary cards, statistics bar, and quick actions render accurately.
2. [x] **Floating Tab Bar**: Tapping tabs switches views with expanding Terracotta chip without lag or errors.
3. [x] **Transaction Creation**: Record an entry with cash and 2 gifts; verify it shows in Bahi Khata.
4. [x] **PDF Generation**: Export a full PDF report and verify Devanagari Hindi text renders without broken characters.
5. [x] **CSV Export**: Export CSV and open in Excel to verify UTF-8 BOM encoding.
6. [x] **Backup & Restore**: Create an encrypted backup with password, restore it, and verify count matches.
