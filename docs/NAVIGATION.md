# Navigation Architecture & Routes — व्यवहार (Vyavahaar)

> **Routing Engine**: Expo Router 58 (File-Based Navigation with Typed Routes)  
> **Tab Component**: `src/components/FloatingTabBar.tsx` (`FloatingPillTabBar`)  
> **Last Updated**: 2026-11-21

---

## 1. Route Map & Hierarchy

```
app/
├── _layout.tsx                 # Root Stack Navigator & DB Initialization
├── +html.tsx                   # Web Root Document (Static export support)
├── +not-found.tsx              # 404 Route Handler
├── modal.tsx                   # Generic Modal Screen
├── (tabs)/                     # 5-Tab Navigator with Floating Pill Bar
│   ├── _layout.tsx             # Tab configuration & custom tabBar
│   ├── index.tsx               # Route: '/' or '/(tabs)' — Home / Dashboard
│   ├── bahi.tsx                # Route: '/(tabs)/bahi' — Bahi Khata / Ledger
│   ├── events.tsx              # Route: '/(tabs)/events' — Events Directory
│   ├── people.tsx              # Route: '/(tabs)/people' — People Directory
│   ├── settings.tsx            # Route: '/(tabs)/settings' — Backup & Settings
│   └── two.tsx                 # Hidden Route (href: null)
├── entry/
│   ├── new.tsx                 # Route: '/entry/new' — Record New Transaction
│   └── [id].tsx                # Route: '/entry/[id]' — Transaction Detail & Soft Delete
├── event/
│   ├── new.tsx                 # Route: '/event/new' — Create New Event
│   └── [id].tsx                # Route: '/event/[id]' — Event Detail & Function Ledger
├── person/
│   ├── new.tsx                 # Route: '/person/new' — Add New Person
│   └── [id].tsx                # Route: '/person/[id]' — Person Profile & Exchange History
├── reports/
│   └── index.tsx               # Route: '/reports' — Reports Hub (PDF & CSV Export)
├── gifts/
│   └── index.tsx               # Route: '/gifts' — Physical Gifts Inventory
└── reminders/
    └── index.tsx               # Route: '/reminders' — Upcoming Reminders Directory
```

---

## 2. Floating Pill Bottom Navigation (`FloatingPillTabBar`)

### 2.1 Design & Layout Specification
- **Component**: `src/components/FloatingTabBar.tsx`
- **Container**: Elevated floating white pill (`#FFFFFF`) with rounded corners (`borderRadius: 36`), soft shadow (`elevation: 10`, `shadowOpacity: 0.14`), and border (`rgba(226, 232, 240, 0.8)`).
- **Positioning**: Anchored above the Android system navigation bar using `react-native-safe-area-context` (`insets.bottom`).
- **Active Tab ("Expanding Chip")**: When active, the selected tab expands horizontally into a Terracotta (`#C05A2B`) capsule with a white icon and bold Hindi label (`fontSize: 13`, `fontWeight: '700'`).
- **Inactive Tabs**: Inactive destinations render as compact vector line icons (`#64748B`, `size: 22`).

### 2.2 Navigation Dispatch & Resilience
In Expo Router 58, custom tab bars do not receive a standard `navigation` object in props; instead, they receive `state`, `descriptors`, `emitter`, and `navigateToTab`. To ensure bulletproof touch navigation on Android:
1. `emitter?.emit` is executed safely inside a `try...catch` block.
2. Primary navigation dispatches via `navigateToTab(route.key)`.
3. If `navigateToTab` is unavailable, it falls back to `descriptors[route.key].navigation.navigate(route.name)`.
4. Ultimate fallback uses `expo-router`'s imperative `router.navigate(routePath)`.
5. All buttons include `hitSlop={{ top: 12, bottom: 12, left: 10, right: 10 }}` to guarantee instant finger tap responsiveness.

### 2.3 Screen Content Padding
To prevent the floating tab bar from obscuring list items, cards, or buttons at the bottom of the screen, all primary tab screens enforce bottom padding:
```typescript
contentContainerStyle={{
  paddingBottom: 110, // Generous spacing so content scrolls cleanly above the floating bar
}}
```

---

## 3. Dynamic Route Parameters

| Route | Parameter | Type | Description |
| :--- | :--- | :--- | :--- |
| `app/entry/[id].tsx` | `id` | `string` (UUID) | Primary key of the transaction record in `entries`. |
| `app/event/[id].tsx` | `id` | `string` (UUID) | Primary key of the event in `events`. |
| `app/person/[id].tsx` | `id` | `string` (UUID) | Primary key of the relative/contact in `people`. |
| `app/entry/new.tsx` | `personId` (optional) | `string` | Pre-selects a specific person when opened from their profile. |
| `app/entry/new.tsx` | `eventId` (optional) | `string` | Pre-selects a specific event when opened from event details. |
