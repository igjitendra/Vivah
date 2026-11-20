# Product Requirements Document (PRD) — व्यवहार (Vyavahaar)

> **Document Version**: 2.1  
> **Status**: Approved & Verified for Phase 3 MVP  
> **Last Updated**: 2026-11-21

---

## 1. Product Goals

1. **Accuracy & Integrity**: Eliminate math errors and lost paper records for family events.
2. **Cultural Relevance**: Honor Indian traditions by keeping *Mila* (Received) and *Diya* (Given) strictly separate, with zero commercial debt language.
3. **Speed of Data Entry**: Allow quick transaction entry under 5 seconds during busy ceremonies.
4. **Offline Autonomy**: Function seamlessly in rural villages and banquet halls without cellular internet or Wi-Fi.
5. **Data Longevity**: Enable safe export to PDF, CSV, and encrypted local backups that survive device changes.

---

## 2. User Personas

### Persona 1: The Household Head / Elder (*श्री राधे श्याम, 56 वर्ष*)
- **Role**: Organizes weddings and family functions; tracks social obligations across extended clan.
- **Tech Comfort**: Moderate; uses WhatsApp and UPI; prefers clean Hindi interface with large readable numbers.
- **Key Need**: Needs to quickly check what a relative gave 5 or 10 years ago before deciding the gift amount for an upcoming wedding.

### Persona 2: The Modern Host (*विकास, 28 वर्ष*)
- **Role**: Tech-savvy son managing the registration desk at his sister's wedding reception.
- **Tech Comfort**: High; expects fast, modern mobile UI, instant search, and one-click PDF generation to share with family.
- **Key Need**: Fast transaction recording with optional physical gift descriptions (e.g., "चाँदी का सिक्का", "कपड़े का सेट").

---

## 3. MoSCoW Feature Categorization

### Must Have (P0 — Core MVP)
- [x] **Cross-Platform Target Architecture**: Architecture planned for Android, iOS, Linux, macOS, and Windows.
- [x] **Strict Offline SQLite Storage**: 100% operational without network connection across all platforms.
- [x] **Integer Currency Storage**: All monetary values stored in integer paise (`paise = rupees * 100`).
- [x] **Separate Mila & Diya**: Zero net debt calculation.
- [x] **Person & Family Directory**: Name, village/city, relationship, phone, notes.
- [x] **Events Management**: Event title, date, event type (*शादी, तिलक, मुंडन, etc.*), notes.
- [x] **Transaction Recording**: Cash amount, physical gifts with units/estimated values, notes, date.
- [x] **Past & Planned Records**: Track planned future gifts without polluting completed totals.
- [x] **Advanced Search & Multi-Filters**: Filter by person, village, event, direction, date range.
- [x] **Devanagari Hindi PDF Export**: 6 printable A4 reports generated entirely offline.
- [x] **Excel-Compatible CSV Export**: RFC-4180 CSV with UTF-8 BOM encoding.
- [x] **Encrypted Offline Backup & Safe Restore**: AES-256-GCM + PBKDF2 local backup with automatic rollback.
- [x] **Adaptive Platform UI**: Floating pill bottom navigation on mobile; responsive layout for desktop screens.

### Should Have (P1 — Production Polish)
- [x] **Soft-Delete Architecture**: Records preserve `deleted_at` timestamp rather than hard deletion.
- [x] **Pull-to-Refresh & Focus Auto-Refresh**: Auto-sync dashboard summary on tab focus.
- [x] **Vector Iconography (No Emojis)**: High-quality `@expo/vector-icons` throughout.
- [ ] **Android Home Screen Widget**: Quick glance at upcoming planned events (Deferred to Post-Launch).

### Could Have (P2 — Future Enhancements)
- [ ] **Bluetooth P2P Sharing**: Direct offline phone-to-phone ledger transfer via Wi-Fi Direct or Bluetooth.
- [ ] **Receipt Image Attachment**: Photo snapshot of physical envelope or item receipt stored locally.

### Strictly Deferred (P3 — Phase 4 Scope)
- ❌ **Cloud Database** (Supabase, Firebase, AWS RDS).
- ❌ **User Authentication & OTP Login**.
- ❌ **Online Family Sync & Multi-Device Sharing**.
- ❌ **Server-Side Transaction Storage**.

---

## 4. Acceptance Criteria Summary

| ID | Feature | Acceptance Criterion | Status |
| :--- | :--- | :--- | :--- |
| **AC-01** | Mila/Diya Separation | Under no circumstance shall `totalMila` and `totalDiya` be subtracted or netted. | **VERIFIED** |
| **AC-02** | Integer Currency | All database money values must be stored in paise; formatters must render ₹ accurately. | **VERIFIED** |
| **AC-03** | Gift Estimates Exclusion | Gift estimated values (`estimated_value_paise`) must not add to cash totals. | **VERIFIED** |
| **AC-04** | Planned Status Isolation | Entries with `status = 'planned'` or `'cancelled'` must be excluded from completed reports. | **VERIFIED** |
| **AC-05** | Offline PDF Export | Generate 6 complete A4 Hindi PDF reports with embedded Devanagari font without network. | **VERIFIED** |
| **AC-06** | Encrypted Backup | Backup file must require password, use unique salt/IV, and reject incorrect passwords. | **VERIFIED** |
| **AC-07** | Safe Restore & Rollback | If a restore fails or file is corrupted, the database must roll back to original state atomically. | **VERIFIED** |
| **AC-08** | Navigation Integrity | Floating bottom bar must navigate reliably across all 5 tabs without throwing runtime exceptions. | **VERIFIED** |
