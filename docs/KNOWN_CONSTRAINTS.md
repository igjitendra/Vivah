# Non-Negotiable Project Constraints — व्यवहार (Vyavahaar)

> **Mandatory Rule**: These constraints represent immutable project boundaries established by the product owner. An AI agent or developer MUST NOT violate or silently bypass these rules under any circumstance.

---

## 1. Product & Domain Boundaries

1. **Phase 4 (Cloud & Sync) is Strictly Forbidden at Present**:
   - Do NOT add Supabase, Firebase, AWS Amplify, GraphQL, or REST API sync backends.
   - Do NOT add user accounts, Google OAuth, phone OTP logins, or session tokens.
   - The app must remain 100% offline-first and private.
2. **Never Net-Combine Mila (Received) and Diya (Given)**:
   - Never subtract `diya` from `mila` to compute a single "net balance" or "net debt".
   - The app does NOT function as a debt collection or commercial ledger tool.
3. **Never Mix Physical Gift Estimates with Cash**:
   - The estimated value of a gift item (`estimated_value_paise`) must never be added into cash totals.
4. **Planned Entries Must Never Pollute Completed Totals**:
   - Transactions with `status = 'planned'` or `'cancelled'` must be excluded from completed financial calculations, dashboard metric cards, and completed PDF reports.
5. **No Silent Data Deletions**:
   - Deletion of transactions must use soft deletion (`deleted_at`). Hard deletions of people with existing transactions are blocked via `ON DELETE RESTRICT`.

---

## 2. Technical & Architectural Boundaries

6. **Integer Currency Only**:
   - Never store or calculate monetary amounts as floating-point numbers. Use integer paise exclusively (`1 Rupee = 100 Paise`).
7. **SQLite as Single Source of Truth**:
   - No secondary key-value databases or external server synchronization.
8. **Package Manager Rule**:
   - Use `pnpm` exclusively. Never run `npm install` or `yarn install`.
   - Never install new system packages (`pkg`, `apt`) or npm dependencies without prior user approval.
9. **Never Fabricate Verification**:
   - Never write "all tests passed" or "feature 100% complete" unless the test scripts were actually executed and passed.
10. **Zero Emojis in User Interface**:
    - Emojis are strictly banned in UI code. Use vector icons (`Ionicons`) exclusively.
11. **Preserve Floating Pill Bottom Navigation**:
    - The floating pill-shaped bottom tab bar is an approved design decision (ADR 011). Do not revert to a standard full-width bar without explicit product-owner approval.
