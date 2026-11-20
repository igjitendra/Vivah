# व्यवहार (Vyavahaar) — Documentation Index & Knowledge Base

> **Official App Name**: व्यवहार (Vyavahaar)  
> **Tagline**: रिश्तों का हिसाब, हमेशा याद।  
> **Repository**: [https://github.com/igjitendra/Vivah.git](https://github.com/igjitendra/Vivah.git)  
> **Last Verified Date**: 2026-11-21

Welcome to the comprehensive, authoritative technical and product documentation system for **व्यवहार (Vyavahaar)**. This documentation acts as the single source of truth for human engineers, product designers, and autonomous AI coding agents.

---

## 🧭 Documentation Directory

### 1. Product & Domain
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**: Product identity, Indian cultural context, real-world social use cases, and product philosophy.
- **[PRODUCT_REQUIREMENTS.md](PRODUCT_REQUIREMENTS.md)**: Goals, user personas, MoSCoW feature breakdown, and acceptance criteria.
- **[DOMAIN_RULES.md](DOMAIN_RULES.md)**: The 12 mandatory financial, transaction, and relationship ledger rules.
- **[FEATURES.md](FEATURES.md)**: Comprehensive catalogue of all implemented, partial, and planned application features.
- **[USER_FLOWS.md](USER_FLOWS.md)**: Mermaid sequence and state diagrams of end-to-end user journeys.

### 2. Architecture & Technical Foundations
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: High-level architectural patterns, module layering, and offline data flow.
- **[TECH_STACK.md](TECH_STACK.md)**: Exact installed packages, verified SDK versions, and dependency rationale.
- **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)**: SQLite schema v3, tables, indexes, integer paise conventions, and migration system.
- **[NAVIGATION.md](NAVIGATION.md)**: Expo Router file-based routing structure, tab layout, parameters, and touch handling.

### 3. UI, UX & Design System
- **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)**: Hindi-first design principles, Home screen layout, floating pill bottom bar, and responsiveness.
- **[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md)**: Official color tokens, typography hierarchy, spacing scale, and component specifications.

### 4. Data Safety, Security & Exports
- **[PRIVACY_SECURITY.md](PRIVACY_SECURITY.md)**: 100% offline-first threat model, local data ownership, and permissions audit.
- **[BACKUP_RESTORE.md](BACKUP_RESTORE.md)**: AES-256-GCM + PBKDF2 encrypted offline backup, HMAC verification, safety snapshot, and atomic rollback.
- **[REPORTS_AND_EXPORTS.md](REPORTS_AND_EXPORTS.md)**: 6 Devanagari Hindi PDF reports, RFC-4180 CSV export with UTF-8 BOM, and financial totals separation.

### 5. Quality, Governance & Project Tracking
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)**: Real-time verified implementation status, test evidence, and remaining tasks.
- **[ROADMAP.md](ROADMAP.md)**: Phases 1 through 5, with Phase 4 (Cloud & Sharing) strictly marked as DEFERRED.
- **[TESTING_QA.md](TESTING_QA.md)**: Automated test suite (27/27 tests), stress testing benchmarks, and manual testing checklists.
- **[ANDROID_BUILD_RELEASE.md](ANDROID_BUILD_RELEASE.md)**: Android configuration, package identifier, SDK targets, and Google Play Store launch guide.
- **[DECISIONS.md](DECISIONS.md)**: Architecture and Product Decision Records (ADR 001 to ADR 012).
- **[CHANGELOG.md](CHANGELOG.md)**: Chronological log of all meaningful code, database, and UI changes.
- **[KNOWN_ISSUES.md](KNOWN_ISSUES.md)**: Tracked limitations, severity ratings, workarounds, and resolution status.
- **[KNOWN_CONSTRAINTS.md](KNOWN_CONSTRAINTS.md)**: Absolute, non-negotiable project boundaries.
- **[AI_WORKFLOW.md](AI_WORKFLOW.md)**: Step-by-step operating manual for AI coding agents before, during, and after tasks.

---

## 🔍 Task-Based Documentation Reading Guide

When undertaking specific tasks, AI agents and developers must consult the following documents before touching code:

| Task Type | Primary Documents to Read First |
| :--- | :--- |
| **New Feature Implementation** | [`AGENTS.md`](../AGENTS.md), [`PROJECT_STATUS.md`](PROJECT_STATUS.md), [`PRODUCT_REQUIREMENTS.md`](PRODUCT_REQUIREMENTS.md), [`DOMAIN_RULES.md`](DOMAIN_RULES.md) |
| **Database Schema / Migration** | [`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md), [`DOMAIN_RULES.md`](DOMAIN_RULES.md), [`TESTING_QA.md`](TESTING_QA.md) |
| **UI / Styling / Screen Redesign** | [`UI_UX_GUIDELINES.md`](UI_UX_GUIDELINES.md), [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md), [`NAVIGATION.md`](NAVIGATION.md) |
| **Financial / Ledger Calculations** | [`DOMAIN_RULES.md`](DOMAIN_RULES.md), [`REPORTS_AND_EXPORTS.md`](REPORTS_AND_EXPORTS.md) |
| **Backup, Encryption, or Security** | [`BACKUP_RESTORE.md`](BACKUP_RESTORE.md), [`PRIVACY_SECURITY.md`](PRIVACY_SECURITY.md) |
| **Android Release / Store Build** | [`ANDROID_BUILD_RELEASE.md`](ANDROID_BUILD_RELEASE.md), [`ROADMAP.md`](ROADMAP.md) |

---

## 📝 Mandatory Documentation Update Rules

1. **Documentation Changes With Code**: Any code change affecting schema, routes, domain logic, or dependencies requires updating the corresponding documentation in the same commit.
2. **Zero Assumptions on Status**: Features can only be marked `VERIFIED` when automated test scripts or physical verification logs exist.
3. **Prevent Drift**: Review [`PROJECT_STATUS.md`](PROJECT_STATUS.md) and [`CHANGELOG.md`](CHANGELOG.md) after every meaningful task.
