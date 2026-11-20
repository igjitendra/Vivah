# व्यवहार (Vyavahaar) — Permanent AI Coding Agent Working Instructions

> **CRITICAL MANDATORY INSTRUCTION:**  
> Before making ANY code modification, read this `AGENTS.md` file, [`docs/README.md`](docs/README.md), [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md), and the relevant subject-specific documentation.  
> After every meaningful code modification, update all affected documentation files in the same task. Never leave documentation outdated intentionally.

---

## 1. Project Identity & Purpose

- **App Name**: व्यवहार (Vyavahaar)
- **Tagline**: रिश्तों का हिसाब, हमेशा याद।
- **Platform**: Android Mobile Application (React Native + Expo SDK 58, TypeScript)
- **Nature**: 100% Offline-First Digital Family Ledger for Indian cultural gift & money exchanges (*shadi, baraat, tilak, mundan, griha pravesh*, etc.).
- **Data Storage**: Local SQLite database via `expo-sqlite` (Synchronous API with WAL mode).

---

## 2. Source of Truth Hierarchy

If documentation and code disagree, **do not silently assume either is correct**. Investigate the discrepancy, verify the intended behavior, and update the relevant documentation with an explanation.

1. **`AGENTS.md`** — Mandatory rules and constraints for all AI coding agents.
2. **`docs/PROJECT_STATUS.md`** — Current verified implementation status.
3. **`docs/DECISIONS.md`** — Approved architectural and product decision records (ADRs).
4. **Subject-specific documentation in `docs/`** — Detailed domain, architecture, schema, and UI rules.
5. **Source code and automated tests** — Evidence of actual implementation (`pnpm test:logic && pnpm test:phase3`).

---

## 3. Mandatory Non-Negotiable Domain & Business Rules

1. **मिला (Received) and दिया (Given) are ALWAYS strictly separated.**
   - Never combine them into a net balance, net debt, or net profit/loss figure.
   - The app does NOT function as a debt collection or lending application.
2. **Currency is stored in INTEGER PAISE.**
   - Never use floating-point numbers for money. ₹1,100 is stored as `110000` paise.
   - All database columns storing money must end with `_paise` (e.g. `cash_amount_paise`).
3. **Gift / Item estimated values are NEVER mixed into cash totals.**
   - A gift/item can exist without cash, cash can exist without gifts, or both together.
   - Estimated values (`estimated_value_paise`) must be displayed separately from cash totals.
4. **Planned entries (`status = 'planned'`) are NOT completed transactions.**
   - Planned transactions and cancelled transactions (`status = 'cancelled'`) must **NEVER** be included in completed financial totals or reports.
   - Never silently convert planned entries to recorded entries without explicit user confirmation.
5. **Offline-First & Local Data Privacy.**
   - All core features must work without an internet connection or account login.
   - SQLite is the sole source of truth.
6. **Phase 4 (Cloud & Family Sharing) is STRICTLY DEFERRED.**
   - **DO NOT** implement Supabase, Firebase, cloud sync, OTP login, user accounts, or remote servers.
7. **No Emojis anywhere in the UI.**
   - Use only vector icons (`@expo/vector-icons`, specifically `Ionicons`).
8. **Approved Floating Pill Bottom Navigation.**
   - Do NOT replace the floating pill-shaped bottom navigation bar with a traditional full-width bar without explicit approval.

---

## 4. AI Agent Workflow Checklist

### Phase 1: Before Coding
1. Read `AGENTS.md`, [`docs/README.md`](docs/README.md), and [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).
2. Read the specific documentation file relevant to your task (e.g. [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) for DB changes, [`docs/DOMAIN_RULES.md`](docs/DOMAIN_RULES.md) for transactions).
3. Inspect the actual codebase and existing tests (`git status`, file reads).
4. Identify risks to existing data, migrations, and navigation.

### Phase 2: While Coding
1. Make only the requested changes. Do not refactor unrelated working modules.
2. Follow package manager rules: **Use `pnpm` exclusively**.
3. Never install new system or npm dependencies without prior user approval.
4. Preserve existing functionality and 100% offline-first behavior.
5. Maintain strict TypeScript types (no unchecked `any`).
6. Never fabricate implementation status, test results, or package versions.

### Phase 3: After Coding
1. Run TypeScript check: `pnpm typecheck` (`tsc --noEmit`).
2. Run automated test suites: `pnpm test` (both `scripts/test-business-logic.ts` and `scripts/test-phase3-features.ts`).
3. If UI changed, verify rendering and touch interactions.
4. Update affected documentation in the same task:
   - [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)
   - [`docs/CHANGELOG.md`](docs/CHANGELOG.md)
   - [`docs/FEATURES.md`](docs/FEATURES.md) (if feature scope changed)
   - [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) (if a bug was fixed or discovered)
5. Review internal links and ensure zero contradictions across documentation.

---

## 5. Development & Testing Commands

```bash
# Package Manager
pnpm install                 # Install dependencies

# Quality Assurance & Verification
pnpm typecheck               # Run tsc --noEmit
pnpm test                    # Run all business logic & phase 3 tests
pnpm test:logic              # Run pure business logic test suite (16 tests)
pnpm test:phase3             # Run phase 3 features test suite (11 tests)

# Development Server
pnpm start                   # Start Expo dev server (Metro bundler)
```

---

## 6. Forbidden Actions

- ❌ Never net-subtract Mila and Diya amounts.
- ❌ Never calculate automatic debt obligations between families.
- ❌ Never store floating-point rupees in database columns.
- ❌ Never add cloud dependencies (Supabase, Firebase, AWS Amplify, etc.).
- ❌ Never introduce internet permissions or server analytics.
- ❌ Never wipe existing user data during database upgrades — always use safe versioned migrations.
- ❌ Never mark a feature as "VERIFIED" without executing actual tests or verification.
