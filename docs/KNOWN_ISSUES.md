# Known Issues & Limitations — व्यवहार (Vyavahaar)

> **Tracking Policy**: An issue is removed only after an automated test or verified fix is committed.  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 1. Resolved Issues

| Issue ID | Description | Severity | Affected Module | Resolution Date | Resolution Details |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **ISSUE-01** | Missing Noto Sans Devanagari font files declared in `pubspec.yaml` | High | `pubspec.yaml`, `assets/fonts/` | 2026-11-21 | Added Google Noto Sans Devanagari TTF files covering all declared weights into `assets/fonts/`. |
| **ISSUE-02** | Missing `assets/icons/` directory declared in `pubspec.yaml` | Medium | `pubspec.yaml`, `assets/` | 2026-11-21 | Created `assets/icons/` directory with `.gitkeep` to prevent packaging warnings. |
| **ISSUE-03** | Incomplete table repopulation in `BackupService.restoreBackup()` | High | `backup_service.dart` | 2026-11-21 | Implemented atomic insertion loop with backward-compatible key resolution for v3 and v4 envelopes. |
| **ISSUE-04** | Outdated Expo / React Native references across documentation | Medium | `docs/` | 2026-11-21 | Audited and updated all documentation to reflect Flutter-only architecture. |

---

## 2. Tracked Limitations & Environment Notes

### 2.1 Termux Local Execution Limitation
- **Description**: In Android Termux (`Linux aarch64`), local `flutter` and `dart` command-line binaries are not installed in the system PATH.
- **Impact**: Full compilation, `flutter build`, `flutter analyze`, and `flutter test` cannot run locally inside the Termux shell.
- **Mitigation / Architecture**: 
  - Complete architecture, database constraints, stress benchmarks (31,700 records), and 22-language localization are tested locally via standalone Python 3.12 test suites (`scripts/test-database-architecture.py`, `scripts/test-multilingual-architecture.py`).
  - Full Flutter static analysis, code generation, and unit tests run in GitHub Actions CI (`.github/workflows/ci.yml`) on Ubuntu runners with `flutter: stable` and `channel: stable`.
- **Severity**: Low (development environment constraint; does not affect application code).

### 2.2 External Platform SDK Requirements
- **Description**: Building native release binaries for iOS, macOS, and Windows requires their respective host operating systems (macOS for iOS/macOS; Windows for Windows MSIX).
- **Workaround**: Automated multi-platform matrix builds via GitHub Actions CI.
- **Severity**: Low (standard cross-platform development practice).
