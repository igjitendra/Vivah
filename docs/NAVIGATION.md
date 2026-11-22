# Navigation Architecture & Routes — व्यवहार (Vyavahaar)

> **Routing Engine**: GoRouter 14.6+ (Declarative Routing with ShellRoute)  
> **Route Configuration**: `lib/src/app/router/app_router.dart`  
> **Tab Component**: `lib/src/shared/navigation/floating_pill_tab_bar.dart` (`FloatingPillTabBar`)  
> **Sole Application Framework**: Flutter + Dart  
> **Last Updated**: 2026-11-21  

---

## 1. Declarative Route Map & Hierarchy

GoRouter manages navigation with `initialLocation: '/splash'`, a top-level `ShellRoute` for bottom tab navigation on mobile, plus standalone full-screen push routes:

```
appRouter (GoRouter) - initialLocation: '/splash'
├── Standalone Entry & Onboarding Routes:
│   ├── '/splash'       # SplashScreen (Animated brand launch, checks onboarding)
│   └── '/onboarding'   # OnboardingScreen (3-stage cultural walkthrough & tour)
│
├── ShellRoute (hosts FloatingPillTabBar on mobile)
│   ├── '/'             # Tab 1: DashboardScreen (Home Dashboard)
│   ├── '/bahi'         # Tab 2: LedgerScreen (Bahi-Khata Ledger)
│   ├── '/events'       # Tab 3: EventsListScreen (Events Directory)
│   ├── '/people'       # Tab 4: PeopleListScreen (People Directory)
│   └── '/settings'     # Tab 5: SettingsScreen (Settings, Backup & Reports)
│
├── Subroutes (Full-screen navigations outside shell)
│   ├── '/entry/new'    # AddEntryScreen (Record New Transaction)
│   ├── '/entry/:id'    # EntryDetailScreen (Transaction Detail & Actions)
│   ├── '/event/new'    # AddEventScreen (Create New Ceremony)
│   ├── '/event/:id'    # EventDetailScreen (Ceremony Summary & Guest Ledger)
│   ├── '/person/new'   # AddPersonScreen (Add New Contact / Relative)
│   ├── '/person/:id'   # PersonDetailScreen (Person Profile & Exchange History)
│   ├── '/reports'      # ReportsScreen (PDF & CSV Export Hub)
│   ├── '/language'     # LanguageSelectorScreen (22 Scheduled Languages Selector)
│   ├── '/theme'        # ThemeGalleryScreen (Light/Dark themes gallery)
│   └── '/reminders'    # RemindersScreen (Upcoming Ceremonies & Reminders)
```

---

## 2. Floating Pill Bottom Navigation (`FloatingPillTabBar`)

### 2.1 Design & Layout Specification
- **Component**: `lib/src/shared/navigation/floating_pill_tab_bar.dart`
- **Container**: Elevated floating white pill (`AppColors.white`) with rounded borders (`borderRadius: 36`), subtle shadow, and card border (`AppColors.cardBorder`).
- **Positioning**: Floating above bottom screen insets with `SafeArea` padding.
- **Active Tab ("Expanding Capsule")**: The active selected tab expands into a Terracotta (`#C05A2B`) capsule with a white vector icon and bold label.
- **Inactive Tabs**: Inactive destinations render as compact vector line icons (`#64748B`, `size: 22`).
- **Icons**: Vector iconography from Flutter Material Icons (`Icons.home`, `Icons.menu_book`, `Icons.calendar_today`, `Icons.people`, `Icons.settings`). Zero emojis.

### 2.2 Navigation Dispatch
- Tab selection dispatches declaratively via `context.go(appTabs[index].routePath)`.
- Full-screen subroutes use `context.push('/path')` to stack above the shell navigation.
- Deep linking parameters:
  - `/entry/new?eventId=xyz`: Preselects event in transaction form.
  - `/entry/new?personId=abc`: Preselects person in transaction form.
  - Path parameters: `/entry/:id`, `/event/:id`, `/person/:id`.

---

## 3. Desktop & Tablet Responsive Adaptation

- **`ResponsiveLayout`** (`lib/src/shared/layouts/responsive_layout.dart`):
  - **Mobile (< 600dp)**: Standard touch layout with bottom `FloatingPillTabBar`.
  - **Tablet (600dp - 1024dp)**: Adaptive split view with navigation rail.
  - **Desktop (≥ 1024dp)**: Multi-column responsive layout with persistent navigation drawer, wide transaction tables, and side-by-side transaction details.
