# UI / UX Guidelines — व्यवहार (Vyavahaar)

> **Design Direction**: Premium, Modern & Professional Indian Personal Ledger  
> **Language**: Hindi-First (Devanagari script throughout) with 22-language architecture  
> **Framework**: Flutter + Material 3  
> **Last Updated**: 2026-11-21  

---

## 1. Core Visual Principles

1. **Hindi-First Authenticity**: The interface is designed natively in Hindi Devanagari. Labels must never read like robotic literal translations; they must use respectful, traditional familial terms (e.g., *व्यवहार*, *बही खाता*, *रिश्तों का हिसाब*, *प्राप्त राशि*, *दी गई राशि*).
2. **Minimal & Clean Hierarchy**: Avoid visual clutter, heavy dark gradients, or fragmented boxes. Use calm surfaces, generous whitespace, and purposeful card grouping.
3. **Zero Emoji Policy**: **Emojis are strictly prohibited** across all screens, cards, headers, buttons, and dialogs. Use pure vector iconography from Flutter Material Icons (`Icons.*`).
4. **Culturally Dignified Color Coding**:
   - Received money (*Mila*) uses soft green surfaces (`AppColors.milaGreen`) and forest green typography (`AppColors.forestGreen`).
   - Given money (*Diya*) uses soft red surfaces (`AppColors.diyaRed`) and terracotta typography (`AppColors.terracotta`).
   - Deep Navy (`AppColors.deepNavy`, `#1F3352`) anchors headers, primary text, and formal elements.
   - Terracotta (`AppColors.terracotta`, `#C05A2B`) highlights primary interactive actions and active navigation states.

---

## 2. Redesigned Home Screen Architecture

The Home Screen (`lib/src/features/dashboard/presentation/dashboard_screen.dart`) follows a 5-tier vertical hierarchy:

```
┌────────────────────────────────────────────────────────┐
│ A. COMPACT NAVY HEADER (#1F3352)                       │
│    व्यवहार                                   [⚙ Settings]│
│    रिश्तों का हिसाब, हमेशा याद।                          │
└────────────────────────────────────────────────────────┘
┌───────────────────────────┬────────────────────────────┐
│ B. FINANCIAL SUMMARY      │ B. FINANCIAL SUMMARY       │
│    ↓ कुल मिला             │    ↑ कुल दिया              │
│    ₹1,100                 │    ₹500                    │
│    प्राप्त राशि           │    दी गई राशि              │
└───────────────────────────┴────────────────────────────┘
┌────────────────────────────────────────────────────────┐
│ C. UNIFIED OVERVIEW STATISTICS BAR                     │
│    📅 कार्यक्रम: 4   │   👥 व्यक्ति: 12   │   📖 व्यवहार: 18 │
└────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────┐
│ D. CURRENT EVENT CARD (हाल का कार्यक्रम)              │
│    [📅] रमेश की शादी                           [›]     │
│         22 नवंबर 2026                                  │
└────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────┐
│ E. QUICK ACTIONS (त्वरित कार्य)                        │
│    [👛] नया व्यवहार दर्ज करें (Primary Terracotta) [→] │
│    [📅] नया कार्यक्रम बनाएं                           [›] │
│    [👤] नया व्यक्ति जोड़ें                            [›] │
└────────────────────────────────────────────────────────┘
```

---

## 3. Approved Floating Bottom Navigation

- **Component**: `lib/src/shared/navigation/floating_pill_tab_bar.dart`
- **Surface**: White `#FFFFFF` capsule, `borderRadius: 36`, soft shadow (`elevation: 10`, `shadowOpacity: 0.14`).
- **Active State**: The active tab expands sideways into a `#C05A2B` Terracotta chip showing the white vector icon and bold Hindi label (`होम`, `बही`, `कार्यक्रम`, `लोग`, `सेटिंग`).
- **Inactive State**: Inactive tabs render as compact slate icons (`#64748B`, `size: 22`).
- **Touch Ergonomics**: Adequate padding and touch targets ensure effortless one-handed tapping on mobile devices.
- **Rule**: Retain this floating pill navigation on mobile interfaces. On wide desktop screens, `ResponsiveLayout` adapts to desktop navigation rails.

---

## 4. Typography & Readability

- **Typography**: Uses Noto Sans Devanagari with explicit font weight fallbacks.
- **Hierarchy**:
  - Screen Titles: 22–24sp, Bold (`FontWeight.bold`).
  - Section Headings: 15–16sp, SemiBold (`FontWeight.w600`).
  - Card Amounts: 22–24sp, ExtraBold (`FontWeight.bold`).
  - Body & Labels: 13–14sp, Regular to Medium (`FontWeight.w500`).
  - Subtitles & Meta: 11–12sp, Muted (`AppColors.mutedText`).
- **Currency Rendering**: Always prepend the authentic Indian Rupee symbol `₹` without floating decimals (e.g. `₹1,100`, never `₹1100.00`).

---

## 5. Splash Screen & First-Launch Onboarding UX Guidelines

### 5.1 Animated Splash Screen Experience
- **First Impression**: The splash screen serves as the authoritative, calm gateway to the app. It must immediately reassure the user with cultural familiarity and digital data safety.
- **Visual Staging**:
  - Deep Navy canvas (`#1F3352`) evokes institutional permanence and trust.
  - Central elevated circular badge displaying the Open Bahi + Terracotta Checkmark `AppSymbol`.
  - Stately Devanagari wordmark "व्यवहार" with cultural tagline "रिश्तों का हिसाब, हमेशा याद।".
  - Floating bottom trust badge: "100% ऑफ़लाइन और सुरक्षित" with offline lock icon.
- **Timing Guideline**: 1.8 seconds minimum display time. Never snap abruptly; always use smooth fade transitions.

### 5.2 First-Launch Onboarding Walkthrough
- **Tone**: Respectful, warm, clear, and reassuring. Focuses on family trust rather than commercial utility.
- **Structure (3 Culturally Crafted Slides)**:
  1. *Slide 1 (Digital Bahi Khata)*: Introduces how traditional Indian social gifting (*shadi, mundan, griha pravesh*) is neatly digitized with Mila (Received) and Diya (Given) kept strictly separate.
  2. *Slide 2 (Cultural Dignity & Zero Debt)*: Clarifies that this ledger is about honoring mutual goodwill and relations, not debt collection or commercial accounting. Highlights pre-event budget planning.
  3. *Slide 3 (100% Offline & Private)*: Emphasizes that zero data ever leaves the user's phone. Features AES-256-GCM encryption, PDF/CSV reports, and includes an instant language switcher chip.
- **User Agency**: A prominent "छोड़ें" (Skip) pill is always available on early slides so returning or impatient users can immediately enter the app.
- **Revisiting**: Users can re-open the onboarding tour at any time from **Settings ➔ Display & Preferences ➔ ऐप परिचय (Onboarding)**.

---

## 6. InlitX/streak Tactile UX, Buttons & PC Desktop Dual-Pane Guidelines

### 6.1 Tactile Button Micro-Interactions (ExpressButton)
- Adopted directly from `InlitX/streak` button physics:
  - **Press Dynamics**: Tap scale down to `0.94` with custom bouncy spring curve (`ratio: 0.58, stiffness: 380`).
  - **Morphing Squircle**: Pill shape smoothly transitions into rounded squircle (`14dp`–`16dp`) during press, delivering a real-world rubber stamp or tactile switch sensation.
  - **Color-Coded Feedback**: Mila operations flash soft green; Diya operations flash terracotta red.

### 6.2 Desktop Split-View (Master-Detail Dual-Pane)
- **Wide Display Ergonomics (`width ≥ 900dp`)**:
  - Avoid stretching short data across full wide PC monitors.
  - Divide screen into **Master Pane** (`440dp` width) for quick browsing, filtering, and sorting, and **Detail Pane** (remaining width) for full read/edit/delete operations.
  - Retain master list scroll position when inspecting details.
  - Selected item in the master list receives an active `2.0dp` border and background tint, establishing clear spatial orientation.
  - When no item is selected, display `EmptyDetailPane` with brand mark and keyboard shortcut guidance.
