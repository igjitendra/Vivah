# GitHub Copilot Instructions — व्यवहार (Vyavahaar)

This repository follows strict architectural and domain guidelines documented centrally in [`AGENTS.md`](../AGENTS.md).

**Core Directives:**
1. Refer to [`AGENTS.md`](../AGENTS.md) and [`docs/PROJECT_STATUS.md`](../docs/PROJECT_STATUS.md) for all project rules.
2. The sole application framework is **Flutter + Dart** (`lib/`).
3. Store all financial values in integer paise (e.g. `110000` paise = ₹1,100). Never use floats for currency.
4. Keep `mila` (received) and `diya` (given) totals strictly separated. Never compute a net debt or net commercial balance.
5. Exclude planned (`status = 'planned'`) and cancelled (`status = 'cancelled'`) transactions from completed financial calculations.
6. Do not implement cloud synchronization or remote accounts (Phase 4 is deferred).
7. Use vector icons (`Icons.*`) only; no emojis in UI.
