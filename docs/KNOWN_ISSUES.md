# Known Issues & Limitations — व्यवहार (Vyavahaar)

> **Tracking Policy**: An issue is removed only after an automated test or verified fix is committed.  
> **Last Updated**: 2026-11-21

---

## 1. Resolved Issues

| Issue ID | Description | Severity | Affected Module | Resolution Date | Resolution Details |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **ISSUE-01** | `Cannot read property 'emit' of undefined` on tab bar press | High | `FloatingTabBar.tsx` | 2026-11-21 | Handled `emitter?.emit` and `navigateToTab(route.key)` for Expo Router 58. |
| **ISSUE-02** | Tab bar touch clipping on older Android versions | Medium | `app/(tabs)/_layout.tsx` | 2026-11-21 | Added `tabBarStyle: { position: 'absolute', bottom: 0 }` and `hitSlop: 12`. |
| **ISSUE-03** | Unicode emojis in UI violating aesthetic standards | Low | All screens | 2026-11-21 | Replaced all emojis with `@expo/vector-icons` Ionicons. |
| **ISSUE-04** | Deprecated `SafeAreaView` warning in Expo SDK 58 | Low | Layouts | 2026-11-21 | Upgraded to `useSafeAreaInsets` from `react-native-safe-area-context`. |

---

## 2. Tracked Limitations & Future Considerations

### 2.1 PDF Export Online Font Loading Fallback
- **Description**: `PdfService.ts` loads `@import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Devanagari:wght@400;600;700;800&display=swap');` in its HTML template.
- **Limitation**: When a device is completely in Airplane mode (zero internet connection ever), the webview printing engine falls back to Android's built-in system Devanagari font.
- **Workaround**: Android's native system Devanagari font renders correctly; however, embedding local base64-encoded WOFF2 font files directly into the HTML string can be added in Phase 5 for 100% font consistency without network cache.
- **Severity**: Low.

### 2.2 Termux Node.js Bytecode Export Limitation
- **Description**: Running `npx expo export` in Termux Android environment can fail when Hermes bytecode compilation binary encounters glibc incompatibilities.
- **Workaround**: Run `npx expo export --no-bytecode` when bundling in Termux, or build via EAS Cloud.
- **Severity**: Low (development environment only; does not affect end-user APK/AAB).
