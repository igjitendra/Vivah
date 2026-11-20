# Architecture & Product Decision Records (ADRs) — व्यवहार (Vyavahaar)

> **Document Status**: Immutable Record of Approved Architectural & Product Decisions  
> **Rule**: An approved decision cannot be silently altered or reversed without explicit product-owner approval.

---

## ADR 001: Application Name & Brand Identity
- **Date**: 2026-11-20
- **Decision**: The official application name is **व्यवहार** (English: **Vyavahaar**). The official tagline is **"रिश्तों का हिसाब, हमेशा याद।"**.
- **Context**: The app represents Indian cultural gift-giving (*vyavahaar / shagun*), not commercial lending.
- **Consequences**: All branding, headers, strings, and exports must consistently use this naming.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 002: Hindi-First User Experience
- **Date**: 2026-11-20
- **Decision**: The interface is designed primarily in authentic Hindi Devanagari script.
- **Context**: The primary users are Indian household elders, family heads, and event hosts who maintain traditional family records.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 003: 100% Offline-First Architecture
- **Date**: 2026-11-20
- **Decision**: All application features (CRUD, search, filters, PDF generation, backup) must operate entirely without internet access.
- **Context**: Family events often occur in banquet halls or rural settings with poor connectivity. Family finances are also deeply personal.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 004: SQLite with WAL Mode as Single Source of Truth
- **Date**: 2026-11-20
- **Decision**: Use `expo-sqlite` with `PRAGMA journal_mode = WAL;` and foreign keys enabled as the sole primary storage engine.
- **Context**: SQLite provides ACID compliance, fast indexing, scale up to tens of thousands of records, and zero external database overhead.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 005: Monetary Storage in Integer Paise
- **Date**: 2026-11-20
- **Decision**: All financial amounts are stored as integer paise (`cash_amount_paise = rupees * 100`).
- **Context**: Prevents IEEE 754 floating-point rounding errors.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 006: Strict Separation of Mila and Diya (Never Net Debt)
- **Date**: 2026-11-20
- **Decision**: *Mila* (Received) and *Diya* (Given) are reported strictly independently. Under no circumstances shall a net balance or debt obligation be computed.
- **Context**: Framing social reciprocal gifts as commercial debts is culturally unacceptable in Indian society.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 007: Gift Estimates Excluded from Cash Totals
- **Date**: 2026-11-20
- **Decision**: Physical gift valuations are tracked for cultural reference but never mixed into cash amounts.
- **Context**: A gift of a silver coin cannot be spent as cash liquidity. Mixing them produces inaccurate cash ledger balances.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 008: Isolation of Planned Transactions
- **Date**: 2026-11-21
- **Decision**: Entries with `status = 'planned'` or `status = 'cancelled'` must be excluded from completed financial totals and dashboard metrics.
- **Context**: Planning a future gift is an intention, not an accomplished financial event.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 009: Strict Deferral of Phase 4 (Cloud & Online Sync)
- **Date**: 2026-11-20
- **Decision**: Phase 4 (Supabase, cloud database, user accounts, OTP login, multi-device sync) is intentionally frozen and deferred.
- **Context**: Maintains absolute data privacy, eliminates server costs, and guarantees complete offline independence for the MVP release.
- **Status**: **APPROVED & FROZEN**

---

## ADR 010: Zero Emojis in User Interface
- **Date**: 2026-11-21
- **Decision**: Emojis are strictly banned across the entire application UI. Vector icons (`Ionicons`) must be used exclusively.
- **Context**: Professional, dignified, and cultural aesthetic required for an Indian family ledger.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 011: Floating Pill-Shaped Bottom Navigation
- **Date**: 2026-11-21
- **Decision**: Retain and harden the floating pill-shaped bottom tab bar with expanding active chip design.
- **Context**: Modern, premium fintech aesthetic preferred over outdated full-width rectangular bars.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 012: Production-Grade Hindi PDF & AES-256 Offline Backup
- **Date**: 2026-11-21
- **Decision**: Implement offline Devanagari PDF export using `expo-print` and encrypted backup using AES-256-GCM + PBKDF2 with atomic rollback safety.
- **Context**: Concludes Phase 3 MVP deliverables with verified automated test coverage.
- **Status**: **APPROVED & VERIFIED**

---

## ADR 013: Five-Platform Cross-Platform Target
- **Date**: 2026-11-21
- **Decision**: व्यवहार is formally approved as a cross-platform product targeting five operating system families: **Android, iOS, Linux Desktop, macOS Desktop, and Windows Desktop**.
- **Context**: Users manage family ledgers on mobile phones during events and on desktop PCs/Macs for long-term review and printing.
- **Consequences**: Architecture, testing, and file persistence must support all 5 operating systems without forcing mobile-only conventions onto desktop or vice versa.
- **Status**: **APPROVED & PERMANENT**

---

## ADR 014: Flutter / Dart as Master 5-Platform Architecture Candidate
- **Date**: 2026-11-21
- **Decision**: Evaluate Flutter (Dart) + Riverpod + Drift ORM as the unified single-codebase technology stack for the five platforms. Retain existing verified React Native codebase until explicit migration approval gate.
- **Context**: Flutter provides official, first-class native compilation for Linux GTK, macOS Cocoa, Windows Win32, Android, and iOS from a single `lib/` directory.
- **Status**: **ARCHITECTURE PROPOSAL DOCUMENTED (`docs/FLUTTER_MIGRATION_ARCHITECTURE.md`) — AWAITING OWNER APPROVAL GATE**
