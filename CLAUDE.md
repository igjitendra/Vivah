# Claude Code Instructions — व्यवहार (Vyavahaar)

This project uses a centralized AI documentation and rules system.

**MANDATORY INSTRUCTIONS:**
1. Before performing any work or modifying code, read [`AGENTS.md`](./AGENTS.md), [`docs/README.md`](./docs/README.md), and [`docs/PROJECT_STATUS.md`](./docs/PROJECT_STATUS.md).
2. Adhere strictly to the domain rules in [`docs/DOMAIN_RULES.md`](./docs/DOMAIN_RULES.md) (Mila/Diya strictly separated, integer paise only, Phase 4 cloud features deferred).
3. The official and sole application framework is **Flutter + Dart** (`lib/`).
4. Always run automated architecture tests: `python3 scripts/test-database-architecture.py` and `python3 scripts/test-multilingual-architecture.py`. Run `flutter test` when Flutter toolchain is available.
5. Update affected documentation in `./docs/` during the same task.
