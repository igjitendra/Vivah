# Privacy Policy — व्यवहार (Vyavahaar)

> **Effective Date**: November 22, 2026  
> **Last Updated**: November 22, 2026  
> **Application**: व्यवहार (Vyavahaar) — Digital Family Ledger  
> **Package Identifier**: `com.vyavahaar.app`  
> **Hosting & Source**: 100% Offline-First Open-Source Application  

---

## 1. Introduction

व्यवहार (Vyavahaar) is designed from the ground up with a strict **Privacy-First, 100% Offline** philosophy. We firmly believe that your family's personal ledger, ceremonial gift transactions (*शगुन* / *व्यवहार*), and relatives' contacts are sacred, personal, and should remain solely in your custody.

**We do not collect, transmit, store, sell, or analyze your personal data on any remote server.** Everything you enter into Vyavahaar stays 100% on your physical device.

---

## 2. Google Play Store Data Safety Declaration

In compliance with Google Play Store's Data Safety requirements:

| Data Category | Data Type | Collected? | Shared with Third Parties? | Handled Ephemerally? |
| :--- | :--- | :--- | :--- | :--- |
| **Personal Info** | Name, Phone number, Address, Family details | **NO** (0% collected) | **NO** (0% shared) | Stored solely in local SQLite database on your device |
| **Financial Info** | Gift amounts, cash transactions, ceremonial items | **NO** (0% collected) | **NO** (0% shared) | Stored solely in local SQLite database on your device |
| **Location** | Precise or Approximate Location | **NO** | **NO** | Not requested / Not accessible |
| **Identifiers** | Device ID, Advertising ID, Android ID | **NO** | **NO** | Zero tracking IDs generated or collected |
| **Analytics & Telemetry** | Usage logs, crash reports, user interaction | **NO** | **NO** | No third-party SDKs (No Firebase, No Google Analytics) |
| **Contacts** | Phone contacts list | **NO** | **NO** | No contacts permission requested |

### Summary Points:
- **Data Collection**: **Zero Data Collected**.
- **Data Sharing**: **Zero Data Shared**.
- **Security Practices**:
  - All data is encrypted in transit and at rest if using the offline encrypted backup feature (AES-256-GCM + PBKDF2 600,000 iterations).
  - Users can delete all data at any time by clearing application data or uninstalling the app.

---

## 3. Device Permissions Audit

Vyavahaar operates on the **Principle of Least Privilege**:

- **Internet Access (`android.permission.INTERNET`)**: **NOT REQUESTED / NOT USED**. The application cannot connect to the internet, cloud APIs, or external servers.
- **Network State (`android.permission.ACCESS_NETWORK_STATE`)**: **NOT REQUESTED / NOT USED**.
- **Contacts (`android.permission.READ_CONTACTS`)**: **NOT REQUESTED**. You manually enter only what you wish to record.
- **Camera / Microphone**: **NOT REQUESTED / NOT USED**.
- **Storage / Files**: The app utilizes Android Scoped Storage to let you save generated PDF/CSV reports and encrypted backups to your chosen local directory or share them via the standard Android system share sheet.

---

## 4. Local Data Storage & Security

1. **Local SQLite Database**:
   - All relative records, ceremony details, and financial transactions are stored in a sandboxed SQLite database (`vyavahaar.db`) within your device's private application sandbox (`/data/data/com.vyavahaar.app/`).
   - Other apps cannot access or read your data without root permissions.

2. **User-Initiated Encrypted Backups**:
   - When you export a backup, the app compresses and encrypts your entire database locally using **AES-256-GCM** authenticated encryption with a user-supplied password.
   - Key derivation utilizes **PBKDF2-HMAC-SHA256** with **600,000 iterations** and a unique cryptographically secure 128-bit salt and 96-bit nonce.
   - The encryption password is never stored or transmitted anywhere.

---

## 5. Children's Privacy (COPPA & DPDP Act Compliance)

Vyavahaar does not target or collect data from children under the age of 13 (or under 18 pursuant to India's Digital Personal Data Protection Act, 2023). Because our application collects zero personal information from any user, it is fully compliant with COPPA and the DPDP Act 2023.

---

## 6. User Rights & Data Deletion

Because all your data resides entirely on your device:
- **Access & Portability**: You can export all your data at any time in open formats:
  - Human-readable **PDF reports**
  - Microsoft Excel-compatible **CSV files** (UTF-8 with BOM)
  - Full authenticated **Encrypted JSON backups**
- **Rectification & Deletion**: You can edit or delete individual transactions, relatives, and events at any time directly in the app.
- **Complete Eradication**: To delete all data permanently, simply clear the app's data in Android Settings or uninstall the application.

---

## 7. Changes to this Privacy Policy

Because Vyavahaar has no network connectivity and does not collect data, this policy will rarely change. Any updates to reflect new local offline features or regulatory changes will be published in the application repository changelog and release notes.

---

## 8. Contact Information

For questions regarding this Privacy Policy or Vyavahaar's offline security architecture:
- **Project Maintainers**: Vyavahaar Open Source Team
- **Issue Tracker**: GitHub Issues on the project repository
- **Application ID**: `com.vyavahaar.app`
