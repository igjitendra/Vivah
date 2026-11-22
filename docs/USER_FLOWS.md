# User Flows & Journeys — व्यवहार (Vyavahaar)

> **Visual Language**: Mermaid Flowcharts & State Diagrams  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 0. Application Launch & First-Time Onboarding Journey (ऐप लॉन्च और ऑनबोर्डिंग)

```mermaid
flowchart TD
    Launch([User launches Vyavahaar]) --> Splash[SplashScreen: /splash]
    Splash --> Animate[Play 1200ms Brand Logo Fade & Scale Animation]
    Animate --> CheckSetting{Query SQLite SettingsDao:\n'onboarding_completed' == 'true'?}
    
    CheckSetting -->|No / First Launch| Onboarding[OnboardingScreen: /onboarding]
    CheckSetting -->|Yes / Returning User| Dashboard[Home Dashboard: /]
    
    subgraph OnboardingFlow [Onboarding Walkthrough]
        Onboarding --> Slide1["Slide 1: पारंपरिक बही-खाता\n(Mila & Diya Separation, Cash vs Gifts)"]
        Slide1 -->|Tap Next / Swipe| Slide2["Slide 2: रिश्तों का सम्मान\n(Zero Debt Mindset, Pre-event Planning)"]
        Slide2 -->|Tap Next / Swipe| Slide3["Slide 3: पूर्णतः ऑफ़लाइन व निजी\n(AES-256 Encryption, Language Selector)"]
        Slide1 -->|Tap 'छोड़ें' (Skip)| CompleteTour[Save 'onboarding_completed' = 'true' in DB]
        Slide2 -->|Tap 'छोड़ें' (Skip)| CompleteTour
        Slide3 -->|Tap 'शुरू करें' (Get Started)| CompleteTour
    end
    
    CompleteTour --> Dashboard
    
    subgraph RevisitTour [Revisiting Onboarding Anytime]
        SettingsTab[Settings Screen] -->|Tap 'ऐप परिचय (ऑनबोर्डिंग)'| OnboardingTour[OnboardingScreen: /onboarding?fromSettings=true]
        OnboardingTour -->|Tap Finish / Pop| SettingsTab
    end
```

---

## 1. Recording a New Transaction (नया व्यवहार दर्ज करना)

```mermaid
flowchart TD
    Start([User opens app]) --> Home[Home Dashboard]
    Home -->|Tap 'नया व्यवहार दर्ज करें'| EntryForm[AddEntryScreen: /entry/new]
    EntryForm --> SelectDir{Select Direction}
    SelectDir -->|Received| Mila[Set Direction = 'received']
    SelectDir -->|Given| Diya[Set Direction = 'given']
    SelectDir --> SelectStatus{Select Status}
    Mila --> SelectStatus
    Diya --> SelectStatus
    SelectStatus -->|Completed| StatusRec[Status = 'recorded']
    SelectStatus -->|Upcoming| StatusPlan[Status = 'planned']
    StatusRec --> EnterAmount[Enter Cash Amount in ₹]
    StatusPlan --> EnterAmount
    EnterAmount --> SelectPerson[Select Counterparty from Dropdown]
    SelectPerson --> SelectEvent[Select Event from Dropdown]
    SelectEvent --> AddGiftPrompt{Add Physical Gift?}
    AddGiftPrompt -->|Yes| AddGift[Enter Item Name, Qty, Unit, Est. Value]
    AddGiftPrompt -->|No| Submit[Tap 'व्यवहार सुरक्षित करें']
    AddGift --> Submit
    Submit --> Validate{Form Validation & Integer Paise Conversion}
    Validate -->|Valid| SaveDB[(Insert into Drift DB with db.transaction)]
    Validate -->|Invalid| ShowError[Display SnackBar / Form Error]
    ShowError --> EntryForm
    SaveDB --> Success[Return to previous screen with SnackBar]
    Success --> End([Finished])
```

---

## 2. Checking a Relative's Relationship History (रिश्तेदार का इतिहास देखना)

```mermaid
flowchart TD
    Start([User receives ceremony invitation]) --> NavPeople[Navigate to 'लोग' Tab]
    NavPeople --> Search[Type Relative Name or Village in Search Bar]
    Search --> SelectPerson[Tap on Relative Card from Results]
    SelectPerson --> Profile[PersonDetailScreen: /person/:id]
    Profile --> ViewSummary[View Separated Totals:\nकुल मिला: ₹X | कुल दिया: ₹Y]
    Profile --> ViewTimeline[Scroll Chronological Timeline of Past Functions]
    ViewTimeline --> Action{User Decision}
    Action -->|Call Relative| Dial[Tap Phone Number]
    Action -->|Export PDF| PDF[Generate Person-wise Hindi PDF Report]
    Action -->|Plan Return Gift| Plan[Tap 'व्यवहार दर्ज करें' with Person pre-selected]
```

---

## 3. Encrypted Local Backup Workflow (सुरक्षित एन्क्रिप्टेड बैकअप)

```mermaid
flowchart TD
    Start([User navigates to Settings]) --> TapBackup[Tap 'एन्क्रिप्टेड बैकअप बनाएं']
    TapBackup --> Modal[Password Prompt Dialog Appears]
    Modal --> EnterPass[User Enters Strong Backup Password]
    EnterPass --> DeriveKey[PBKDF2 derives 256-bit Key with 600,000 Iterations & CSPRNG Salt]
    DeriveKey --> QueryDB[(Extract all Drift SQLite tables to JSON)]
    QueryDB --> Encrypt[Encrypt payload with AES-256-GCM + CSPRNG Nonce]
    Encrypt --> PackFile[Write .enc.json backup envelope v4 to local storage]
    PackFile --> NativeShare[Trigger System Share Sheet via share_plus]
    NativeShare --> UserSave[User saves to Google Drive, SD Card, or WhatsApp]
    UserSave --> Done([Backup Complete & Verified])
```

---

## 4. Safe Restore Workflow with Automatic Rollback (डेटा पुनर्स्थापना)

```mermaid
flowchart TD
    Start([User selects 'बैकअप से डेटा पुनर्स्थापित करें']) --> Warn[Display Confirmation Warning:\n'Current data will be replaced']
    Warn --> PickFile[User selects Backup File via file_picker]
    PickFile --> ReadEnvelope[Read & Parse Backup Envelope]
    ReadEnvelope --> CheckEnc{Is Backup Encrypted?}
    CheckEnc -->|Yes| PromptPass[Ask User for Backup Password]
    PromptPass --> Decrypt[Decrypt using PBKDF2 600,000 iter + AES-256-GCM]
    CheckEnc -->|No| ValidateData[Validate Schema & Metadata]
    Decrypt --> ValidateData
    ValidateData -->|Authentication Tag Failed / Corrupt| Reject[Show Error: 'गलत पासवर्ड या दूषित बैकअप']
    ValidateData -->|Valid| OpenTx[(Open db.transaction in Drift)]
    OpenTx --> ReplaceData[Clear existing tables & Insert backup rows from v3/v4 payload]
    ReplaceData --> VerifyRestored{Verify PRAGMA foreign_key_check}
    VerifyRestored -->|Success| CommitTx[Commit SQLite Transaction]
    VerifyRestored -->|Failure / Exception| RollbackTx[Rollback Transaction Atomically]
    RollbackTx --> RestoreFail[Show Error: 'पुनर्स्थापना विफल, पिछला डेटा सुरक्षित']
    CommitTx --> RefreshUI[Refresh All App Screens & Show Success SnackBar]
    RefreshUI --> End([Restore Complete])
```
