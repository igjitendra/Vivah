# Permanent AI Coding Agent Workflow Guide — व्यवहार (Vyavahaar)

> **Mandatory Standard**: Every AI agent (Claude, Gemini, Copilot, Cursor, etc.) working on this repository must follow this workflow without exception.

---

## 1. Operating Principles

1. **Investigate Before Editing**: Never assume you know the repository state from training data or previous chat snippets. Always inspect the actual files first.
2. **Never Break Working Features**: Never replace working architectures, delete user data, or modify working business logic unless explicitly requested.
3. **Continuous Documentation Maintenance**: Every code change must update its corresponding documentation in the same task.
4. **Honesty Over Optimism**: Never mark a task as "VERIFIED" without running actual tests or inspecting code evidence.
5. **Flutter + Dart is the Sole Framework**: No React Native, Expo, or TypeScript application code.

---

## 2. The 3-Stage AI Agent Workflow

```mermaid
flowchart TD
    subgraph Stage1 [Stage 1: Pre-Coding Inspection]
        S1A[1. Read AGENTS.md & docs/README.md]
        S1B[2. Read docs/PROJECT_STATUS.md & relevant docs]
        S1C[3. Inspect git status & affected source files]
        S1A --> S1B --> S1C
    end

    subgraph Stage2 [Stage 2: Implementation & Safeguards]
        S2A[4. Apply minimal, precise changes in Flutter/Dart]
        S2B[5. Preserve domain rules: Mila/Diya separate, integer paise]
        S2C[6. Use standard dependencies & Icons.* only]
        S2A --> S2B --> S2C
    end

    subgraph Stage3 [Stage 3: Verification & Doc Update]
        S3A[7. Run architecture test scripts & Flutter tests]
        S3B[8. Update docs/PROJECT_STATUS.md & docs/CHANGELOG.md]
        S3C[9. Verify internal links & deliver structured report]
        S3A --> S3B --> S3C
    end

    Stage1 --> Stage2 --> Stage3
```

---

## 3. Pre-Coding Inspection Checklist

Before modifying any file, the AI agent must:
- [ ] Read `AGENTS.md`.
- [ ] Read `docs/README.md` and `docs/PROJECT_STATUS.md`.
- [ ] Check `docs/KNOWN_CONSTRAINTS.md` to ensure the requested task does not violate non-negotiable boundaries.
- [ ] Check `docs/DOMAIN_RULES.md` if touching financial, ledger, or transaction code.
- [ ] Check `docs/DATABASE_SCHEMA.md` if touching database queries, DAOs, or Drift models.
- [ ] Check `docs/UI_UX_GUIDELINES.md` if modifying or adding UI components.
- [ ] Run `git status` to check existing uncommitted modifications.

---

## 4. Implementation Safeguards Checklist

While writing code, the AI agent must:
- [ ] Make only the requested changes; do not refactor unrelated working files.
- [ ] Maintain 100% offline-first behavior (zero cloud/server calls).
- [ ] Store currency in **integer paise** exclusively.
- [ ] Keep **Mila** and **Diya** strictly separated (never compute a net debt).
- [ ] Use **vector icons (`Icons.*`) only**; zero emojis in UI.
- [ ] Use dependencies declared in `pubspec.yaml`. Never add unnecessary dependencies without permission.
- [ ] Retain the approved floating pill bottom navigation bar on mobile and responsive layout on desktop.

---

## 5. Post-Coding Verification & Documentation Checklist

After writing code, the AI agent must:
- [ ] Run database architecture stress tests: `python3 scripts/test-database-architecture.py` (ensure 14/14 pass).
- [ ] Run multilingual localization tests: `python3 scripts/test-multilingual-architecture.py` (ensure 22/22 pass).
- [ ] Run `flutter test` when local Flutter toolchain is present.

### Mandatory Documentation Sync Matrix (Design, Working, Backend, Features):
Whenever changes occur, the corresponding documentation must be updated in the same task:
- [ ] **Design (डिज़ाइन)**: Update [`docs/DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md), [`docs/UI_UX_GUIDELINES.md`](UI_UX_GUIDELINES.md), and [`docs/NAVIGATION.md`](NAVIGATION.md) if UI, colors, typography, layout, or navigation changed.
- [ ] **Working (कार्यप्रणाली / लॉजिक)**: Update [`docs/DOMAIN_RULES.md`](DOMAIN_RULES.md), [`docs/ARCHITECTURE.md`](ARCHITECTURE.md), and [`docs/USER_FLOWS.md`](USER_FLOWS.md) if business logic, calculations, domain rules, or user flows changed.
- [ ] **Backend (बैकएंड / डेटाबेस)**: Update [`docs/DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md), [`docs/FLUTTER_MIGRATION_ARCHITECTURE.md`](FLUTTER_MIGRATION_ARCHITECTURE.md), and [`docs/BACKUP_RESTORE.md`](BACKUP_RESTORE.md) if Drift/SQLite schemas, DAOs, migrations, or tables changed.
- [ ] **Features (फ़ीचर्स)**: Update [`docs/FEATURES.md`](FEATURES.md), [`docs/PROJECT_STATUS.md`](PROJECT_STATUS.md), [`docs/PRODUCT_REQUIREMENTS.md`](PRODUCT_REQUIREMENTS.md), and [`docs/ROADMAP.md`](ROADMAP.md) if features or their statuses changed.
- [ ] **Changelog & Issues**: Always append modifications to [`docs/CHANGELOG.md`](CHANGELOG.md), and [`docs/KNOWN_ISSUES.md`](KNOWN_ISSUES.md) if bugs are resolved or identified.
- [ ] Verify that all internal relative markdown links are valid.

---

## 6. Failure & Discrepancy Reporting Protocol

If an AI agent is unable to complete a task, encounters a test failure, or discovers a mismatch between documentation and code, it must report:
1. **What was inspected**: Exact file paths and line ranges.
2. **What succeeded**: Changes that compiled and verified.
3. **What failed or remains**: Exact error logs, failed test assertions, or unresolved requirements.
4. **Discrepancy Explanation**: Why the contradiction exists and what the intended behavior should be.
5. **Recommended Next Steps**: Explicit options for the user or next agent to proceed safely.
