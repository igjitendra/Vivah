# Gemini Instructions — व्यवहार (Vyavahaar)

This project uses a centralized AI documentation and rules system.

---

## 🚨 MANDATORY CORE RULE: DOCUMENTATION SYNCHRONIZATION (अनिवार्य दस्तावेजीकरण नियम)

**जब भी Design, Working, Backend, या Features में कोई भी बदलाव हो, तो संबंधित `.md` फ़ाइल में उसी task के दौरान लिखना/अपडेट करना अनिवार्य है।**  
Any modification to Design, Working (business logic/flow), Backend (database/schema), or Features **MUST** be reflected in the corresponding markdown documentation files in `./docs/` within the same turn/commit. No task is complete until documentation is updated.

---

## 📌 Change-to-Documentation Mapping Matrix (बदलाव और संबंधित Doc फ़ाइलें)

| श्रेणी (Category) | बदलाव का प्रकार (Type of Change) | अद्यतन की जाने वाली संबंधित .md फ़ाइलें (Files to Update) |
| :--- | :--- | :--- |
| 🎨 **Design (डिज़ाइन)** | UI/UX, Themes, Colors (Navy/Terracotta/Cream), Typography, Widgets, Screens, Layouts, Floating Pill Bar, Responsive Desktop/Mobile | • [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)<br>• [`docs/UI_UX_GUIDELINES.md`](docs/UI_UX_GUIDELINES.md)<br>• [`docs/NAVIGATION.md`](docs/NAVIGATION.md) |
| ⚙️ **Working (कार्यप्रणाली / लॉजिक)** | Business logic, Domain rules, Mila/Diya rules, paise conversion, offline data flow, State management (Riverpod), Validations, User flows | • [`docs/DOMAIN_RULES.md`](docs/DOMAIN_RULES.md)<br>• [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)<br>• [`docs/USER_FLOWS.md`](docs/USER_FLOWS.md)<br>• [`docs/CHANGELOG.md`](docs/CHANGELOG.md) |
| 🗄️ **Backend (बैकएंड / डेटाबेस)** | SQLite / Drift ORM schema, Tables, Columns, DAOs, Queries, Repositories, Migrations, Indexing, Backup/Restore | • [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md)<br>• [`docs/FLUTTER_MIGRATION_ARCHITECTURE.md`](docs/FLUTTER_MIGRATION_ARCHITECTURE.md)<br>• [`docs/BACKUP_RESTORE.md`](docs/BACKUP_RESTORE.md)<br>• [`docs/CHANGELOG.md`](docs/CHANGELOG.md) |
| 🚀 **Features (फ़ीचर्स)** | New feature additions, Feature modifications, Acceptance criteria, Implementation status changes, Roadmap phases | • [`docs/FEATURES.md`](docs/FEATURES.md)<br>• [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md)<br>• [`docs/PRODUCT_REQUIREMENTS.md`](docs/PRODUCT_REQUIREMENTS.md)<br>• [`docs/ROADMAP.md`](docs/ROADMAP.md)<br>• [`docs/CHANGELOG.md`](docs/CHANGELOG.md) |

---

## 📋 Standard Mandatory Instructions

1. **Pre-Task Inspection**: Before performing any work or modifying code, read [`AGENTS.md`](./AGENTS.md), [`docs/README.md`](./docs/README.md), and [`docs/PROJECT_STATUS.md`](./docs/PROJECT_STATUS.md).
2. **Domain Rules**: Adhere strictly to the domain rules in [`docs/DOMAIN_RULES.md`](./docs/DOMAIN_RULES.md):
   - Mila (Received) and Diya (Given) are **ALWAYS strictly separated** (never net-combined or calculated as debt).
   - All currency stored as **INTEGER PAISE** (e.g. ₹1,100 = 110000). Never use floats.
   - 100% Offline-First; Phase 4 (cloud sync, remote auth) is **STRICTLY DEFERRED**.
   - Vector icons (`Icons.*`) only; zero emojis in UI.
3. **Sole Framework**: The official and sole application framework is **Flutter + Dart** (`lib/`).
4. **Automated Testing**: Always run automated architecture tests:
   - `python3 scripts/test-database-architecture.py` (14/14 tests)
   - `python3 scripts/test-multilingual-architecture.py` (22/22 tests)
   - Run `flutter test` when Flutter toolchain is available.
5. **Post-Task Sync**: Verify that the corresponding `.md` doc files from the matrix above have been updated before concluding the task.
