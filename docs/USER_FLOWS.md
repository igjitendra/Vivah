# User Flows & Journeys — व्यवहार (Vyavahaar)

> **Visual Language**: Mermaid Flowcharts & State Diagrams  
> **Last Updated**: 2026-11-21

---

## 1. Recording a New Transaction (नया व्यवहार दर्ज करना)

```mermaid
flowchart TD
    Start([User opens app]) --> Home[Home Dashboard]
    Home -->|Tap 'नया व्यवहार दर्ज करें'| EntryForm[Transaction Form: app/entry/new.tsx]
    EntryForm --> SelectDir{Select Direction}
    SelectDir -->|Received| Mila[Set Direction = 'mila']
    SelectDir -->|Given| Diya[Set Direction = 'diya']
    Mila --> SelectStatus{Select Status}
    Diya --> SelectStatus
    SelectStatus -->|Completed| StatusRec[Status = 'recorded']
    SelectStatus -->|Upcoming| StatusPlan[Status = 'planned']
    StatusRec --> EnterAmount[Enter Cash Amount in ₹]
    StatusPlan --> EnterAmount
    EnterAmount --> SelectPerson[Select or Add Counterparty / Person]
    SelectPerson --> SelectEvent[Select or Add Event / Karyakram]
    SelectEvent --> AddGiftPrompt{Add Physical Gift?}
    AddGiftPrompt -->|Yes| AddGift[Enter Item Name, Qty, Unit, Est. Value]
    AddGiftPrompt -->|No| Submit[Tap 'सहेजें / Save']
    AddGift --> Submit
    Submit --> Validate{Validate with Zod Schema}
    Validate -->|Valid| SaveDB[(Insert into SQLite withTransaction)]
    Validate -->|Invalid| ShowError[Display Inline Error]
    ShowError --> EntryForm
    SaveDB --> Success[Haptic Feedback & Navigate to Ledger]
    Success --> End([Finished])
```

---

## 2. Checking a Relative's Relationship History (रिश्तेदार का इतिहास देखना)

```mermaid
flowchart TD
    Start([User receives wedding invitation]) --> NavPeople[Navigate to 'लोग' Tab]
    NavPeople --> Search[Type Relative Name or Village in Search Bar]
    Search --> SelectPerson[Tap on Relative Card from Results]
    SelectPerson --> Profile[Person Profile: app/person/[id].tsx]
    Profile --> ViewSummary[View Separated Totals:\nकुल मिला: ₹X | कुल दिया: ₹Y]
    Profile --> ViewTimeline[Scroll Chronological Timeline of Past Functions]
    ViewTimeline --> Action{User Decision}
    Action -->|Call Relative| Dial[Tap Phone Number to open Android Dialer]
    Action -->|Export PDF| PDF[Generate Person-wise Hindi PDF Report]
    Action -->|Plan Return Gift| Plan[Tap 'नया व्यवहार' with Person pre-selected]
```

---

## 3. Encrypted Local Backup Workflow (सुरक्षित एन्क्रिप्टेड बैकअप)

```mermaid
flowchart TD
    Start([User navigates to Settings]) --> TapBackup[Tap 'एन्क्रिप्टेड बैकअप बनाएं']
    TapBackup --> Modal[Password Prompt Modal Appears]
    Modal --> EnterPass[User Enters Strong Backup Password]
    EnterPass --> DeriveKey[PBKDF2 derives 256-bit Key with Random Salt]
    DeriveKey --> QueryDB[(Extract all SQLite tables to JSON)]
    QueryDB --> Encrypt[Encrypt payload with AES-256 + Random IV]
    Encrypt --> HMAC[Compute HMAC Integrity Checksum]
    HMAC --> PackFile[Write .json backup envelope to local storage]
    PackFile --> NativeShare[Trigger Android Native Share Sheet]
    NativeShare --> UserSave[User saves to Google Drive, SD Card, or WhatsApp]
    UserSave --> Done([Backup Complete & Verified])
```

---

## 4. Safe Restore Workflow with Automatic Rollback (डेटा पुनर्स्थापना)

```mermaid
flowchart TD
    Start([User selects 'बैकअप रिस्टोर करें']) --> Warn[Display Confirmation Warning:\n'Current data will be replaced']
    Warn --> PickFile[User selects Backup File via Android File Picker]
    PickFile --> ReadEnvelope[Read & Parse Backup Envelope]
    ReadEnvelope --> CheckEnc{Is Backup Encrypted?}
    CheckEnc -->|Yes| PromptPass[Ask User for Backup Password]
    PromptPass --> Decrypt[Decrypt using PBKDF2 + AES-256]
    CheckEnc -->|No| ValidateData[Validate Schema & Checksum]
    Decrypt --> ValidateData
    ValidateData -->|Checksum Failed / Corrupt| Reject[Show Error: 'अमान्य पासवर्ड या दूषित बैकअप']
    ValidateData -->|Valid| Snapshot[Create Atomic In-Memory Safety Snapshot]
    Snapshot --> OpenTx[(Open SQLite withTransactionSync)]
    OpenTx --> ReplaceData[Clear existing tables & Insert backup rows]
    ReplaceData --> VerifyRestored{Verify Foreign Keys & Counts}
    VerifyRestored -->|Success| CommitTx[Commit SQLite Transaction]
    VerifyRestored -->|Failure / Exception| RollbackTx[Rollback Transaction to Safety Snapshot]
    RollbackTx --> RestoreFail[Show Error: 'पुनर्स्थापना विफल, पिछला डेटा सुरक्षित']
    CommitTx --> RefreshUI[Refresh All App Screens & Show Success Summary]
    RefreshUI --> End([Restore Complete])
```
