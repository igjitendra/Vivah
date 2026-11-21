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
