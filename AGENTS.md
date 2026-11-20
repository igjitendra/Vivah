# व्यवहार (Vyavahaar) — Permanent AI Coding Agent Working Instructions

> **CRITICAL MANDATORY INSTRUCTION:**  
> Before making ANY code modification, read this `AGENTS.md` file, [`docs/README.md`](docs/README.md), [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md), [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md), and the relevant subject-specific documentation.  
> After every meaningful code modification, update all affected documentation files in the same task. Never leave documentation outdated intentionally.

---

## 1. Project Identity & Purpose

- **App Name**: व्यवहार (Vyavahaar)
- **Tagline**: रिश्तों का हिसाब, हमेशा याद।
- **Scope**: **Cross-Platform Application for Five Target Platforms**:
  1. **Android** (Mobile — Verified in Phase 3/5)
  2. **iOS** (Mobile — Architecture Ready)
  3. **Linux Desktop** (Desktop — Planned)
  4. **macOS Desktop** (Desktop — Planned)
  5. **Windows Desktop** (Desktop — Planned)
- **Nature**: 100% Offline-First Digital Family Ledger for Indian cultural gift & money exchanges (*shadi, baraat, tilak, mundan, griha pravesh*, etc.).
- **Storage**: Autonomous local SQLite database engine on every supported platform.

---

## 2. Mandatory Multi-Platform Rules for AI Agents

1. **Never describe Vyavahaar as an Android-only application.** Always acknowledge the five-platform product vision (Android, iOS, Linux, macOS, Windows).
2. **Always consider all five target platforms when making architectural or technology decisions.** Keep shared domain models, currency math, validation, and encryption cleanly separated from platform-specific UI adapters.
3. **Do not assume a feature or API working on Android will work identically on iOS or desktop platforms.**
4. **Identify platform-specific limitations before modifying shared code.** (e.g. mobile haptics vs. desktop keyboard shortcuts).
5. **Maintain the Platform Support Matrix in [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).** Clearly distinguish what is `VERIFIED` on hardware from what is `ARCHITECTURE READY` or `PLANNED`.
6. **Update [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md) and [`docs/PLATFORM_RELEASE.md`](docs/PLATFORM_RELEASE.md)** whenever architectural or distribution decisions change.
7. **Test platform-specific behavior independently.** Never claim desktop support based solely on mobile compilation.
8. **Do NOT begin a framework rewrite or migration without explicit product-owner approval.**
9. **Multi-Platform Support ≠ Cloud Sync.** Multi-platform means the software runs locally on five OS families; it does NOT authorize cloud synchronization. Phase 4 remains **DEFERRED**.

---

## 3. Mandatory Non-Negotiable Domain & Business Rules

1. **मिला (Received) and दिया (Given) are ALWAYS strictly separated.**
   - Never combine them into a net balance, net debt, or net profit/loss figure.
   - The app does NOT function as a commercial debt collection or lending application.
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
   - All core features must work without an internet connection or account login on every platform.
   - SQLite is the sole source of truth.
6. **Phase 4 (Cloud & Family Sharing) is STRICTLY DEFERRED.**
   - **DO NOT** implement Supabase, Firebase, cloud sync, OTP login, user accounts, or remote servers.
7. **No Emojis anywhere in the UI.**
   - Use only vector icons (`@expo/vector-icons`, specifically `Ionicons`).
8. **Approved Floating Pill Bottom Navigation for Mobile.**
   - Retain the floating pill-shaped bottom navigation bar on mobile interfaces. On desktop, adapt to desktop-appropriate sidebars or top bars without forcing mobile layouts onto wide screens.
9. **Permanent Multilingual & Localization Mandate (Step 2.5).**
   - All new user-facing features must be localization-ready before implementation is considered complete.
   - Never hardcode UI strings in widgets or business logic.
   - Every new translation key must be added to the source localization file and all required target translation resources.
   - Do not mark a language production-ready without native review and script rendering verification.
   - All translations, font assets, and language switching must work 100% offline.
   - Do not assume all Indian languages use left-to-right scripts (e.g. Urdu, Kashmiri, Sindhi require RTL).
   - Never store translated UI strings in database columns; store canonical machine-readable tokens (`given`, `received`, etc.).

---

## 4. AI Agent Workflow Checklist

### Phase 1: Before Coding
1. Read `AGENTS.md`, [`docs/README.md`](docs/README.md), [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md), and [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md).
2. Read the specific documentation file relevant to your task (e.g. [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) for DB changes, [`docs/DOMAIN_RULES.md`](docs/DOMAIN_RULES.md) for transactions).
3. Inspect the actual codebase and existing tests (`git status`, file reads).
4. Identify risks to existing data, migrations, and cross-platform compatibility.

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
3. If UI changed, verify rendering and touch/click interactions.
4. Update affected documentation in the same task:
   - [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)
   - [`docs/CHANGELOG.md`](docs/CHANGELOG.md)
   - [`docs/PLATFORM_STRATEGY.md`](docs/PLATFORM_STRATEGY.md) (if platform scope changed)
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

- ❌ Never describe Vyavahaar as an Android-only application.
- ❌ Never net-subtract Mila and Diya amounts.
- ❌ Never calculate automatic debt obligations between families.
- ❌ Never store floating-point rupees in database columns.
- ❌ Never add cloud dependencies (Supabase, Firebase, AWS Amplify, etc.).
- ❌ Never introduce internet permissions or server analytics.
- ❌ Never wipe existing user data during database upgrades — always use safe versioned migrations.
- ❌ Never mark a feature or platform as "VERIFIED" without executing actual tests or verification.
