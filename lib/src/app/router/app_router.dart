import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/entities.dart';
import '../../shared/navigation/floating_pill_tab_bar.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ledger/presentation/ledger_screen.dart';
import '../../features/events/presentation/events_list_screen.dart';
import '../../features/events/presentation/add_event_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/people/presentation/people_list_screen.dart';
import '../../features/people/presentation/add_person_screen.dart';
import '../../features/people/presentation/person_detail_screen.dart';
import '../../features/entries/presentation/add_entry_screen.dart';
import '../../features/entries/presentation/entry_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../core/localization/presentation/language_selector_screen.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/settings/presentation/theme_gallery_screen.dart';
import '../../core/utils/responsive.dart';
import '../../core/shortcuts/shortcuts_sheet.dart';
import '../../shared/navigation/express_nav_rail.dart';
import '../app_providers.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// The 5 core navigation tab destinations
const List<TabItemData> appTabs = [
  TabItemData(
    label: AppStrings.tabHome,
    activeIcon: Icons.home,
    inactiveIcon: Icons.home_outlined,
    routePath: '/',
  ),
  TabItemData(
    label: AppStrings.tabBahi,
    activeIcon: Icons.menu_book,
    inactiveIcon: Icons.menu_book_outlined,
    routePath: '/bahi',
  ),
  TabItemData(
    label: AppStrings.tabEvents,
    activeIcon: Icons.calendar_today,
    inactiveIcon: Icons.calendar_today_outlined,
    routePath: '/events',
  ),
  TabItemData(
    label: AppStrings.tabPeople,
    activeIcon: Icons.people,
    inactiveIcon: Icons.people_outline,
    routePath: '/people',
  ),
  TabItemData(
    label: AppStrings.tabSettings,
    activeIcon: Icons.settings,
    inactiveIcon: Icons.settings_outlined,
    routePath: '/settings',
  ),
];

/// Declarative GoRouter configuration
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ShellRoute hosting the FloatingPillTabBar on mobile
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final int index = _calculateSelectedIndex(state.uri.path);
        final l10n = context.l10n;
        final dynamicTabs = [
          TabItemData(
            label: l10n.tabHome,
            activeIcon: Icons.home,
            inactiveIcon: Icons.home_outlined,
            routePath: '/',
          ),
          TabItemData(
            label: l10n.tabBahi,
            activeIcon: Icons.menu_book,
            inactiveIcon: Icons.menu_book_outlined,
            routePath: '/bahi',
          ),
          TabItemData(
            label: l10n.tabEvents,
            activeIcon: Icons.calendar_today,
            inactiveIcon: Icons.calendar_today_outlined,
            routePath: '/events',
          ),
          TabItemData(
            label: l10n.tabPeople,
            activeIcon: Icons.people,
            inactiveIcon: Icons.people_outline,
            routePath: '/people',
          ),
          TabItemData(
            label: l10n.tabSettings,
            activeIcon: Icons.settings,
            inactiveIcon: Icons.settings_outlined,
            routePath: '/settings',
          ),
        ];

        final bool useRail = hasSideRail(context);

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                ExpressNavRail(
                  currentIndex: index,
                  items: dynamicTabs,
                  onSelect: (idx) {
                    context.go(dynamicTabs[idx].routePath);
                  },
                  onOpenShortcuts: () => ShortcutsSheet.show(context),
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              child,
              FloatingPillTabBar(
                currentIndex: index,
                items: dynamicTabs,
                onTabSelected: (idx) {
                  context.go(dynamicTabs[idx].routePath);
                },
              ),
            ],
          ),
        );
      },
      routes: [
        // Tab 1: Home Dashboard
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            child: Consumer(
              builder: (context, ref, _) {
                final summaryAsync = ref.watch(dashboardSummaryProvider);
                final summary = summaryAsync.asData?.value ?? DashboardSummary.empty();

                return DashboardScreen(
                  summary: summary,
                  onNewEntry: () => context.push('/entry/new'),
                  onNewEvent: () => context.push('/event/new'),
                  onNewPerson: () => context.push('/person/new'),
                  onOpenSettings: () => context.go('/settings'),
                  onOpenEventDetails: (id) => context.push('/event/$id'),
                );
              },
            ),
          ),
        ),
        // Tab 2: Bahi Khata (Ledger)
        GoRoute(
          path: '/bahi',
          pageBuilder: (context, state) => NoTransitionPage(
            child: LedgerScreen(
              onNewEntry: () => context.push('/entry/new'),
              onOpenEntryDetail: (id) => context.push('/entry/$id'),
            ),
          ),
        ),
        // Tab 3: Events (कार्यक्रम)
        GoRoute(
          path: '/events',
          pageBuilder: (context, state) => NoTransitionPage(
            child: EventsListScreen(
              onNewEvent: () => context.push('/event/new'),
              onOpenEventDetail: (id) => context.push('/event/$id'),
            ),
          ),
        ),
        // Tab 4: People (लोग)
        GoRoute(
          path: '/people',
          pageBuilder: (context, state) => NoTransitionPage(
            child: PeopleListScreen(
              onNewPerson: () => context.push('/person/new'),
              onOpenPersonDetail: (id) => context.push('/person/$id'),
            ),
          ),
        ),
        // Tab 5: Settings (सेटिंग्स)
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            child: SettingsScreen(
              onOpenLanguageSelector: () => context.push('/language'),
              onOpenReports: () => context.push('/reports'),
              onOpenReminders: () => context.push('/reminders'),
            ),
          ),
        ),
      ],
    ),
    // Fullscreen Subroutes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/entry/new',
      builder: (context, state) => AddEntryScreen(
        initialEventId: state.uri.queryParameters['eventId'],
        initialPersonId: state.uri.queryParameters['personId'],
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/entry/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EntryDetailScreen(entryId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/event/new',
      builder: (context, state) => const AddEventScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/event/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EventDetailScreen(eventId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/person/new',
      builder: (context, state) => const AddPersonScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/person/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PersonDetailScreen(personId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/language',
      builder: (context, state) => const LanguageSelectorScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/theme',
      builder: (context, state) => const ThemeGalleryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/reminders',
      builder: (context, state) => const RemindersScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/onboarding',
      builder: (context, state) {
        final isFromSettings = state.uri.queryParameters['fromSettings'] == 'true';
        return OnboardingScreen(isFromSettings: isFromSettings);
      },
    ),
  ],
);

int _calculateSelectedIndex(String path) {
  if (path.startsWith('/bahi')) return 1;
  if (path.startsWith('/events')) return 2;
  if (path.startsWith('/people')) return 3;
  if (path.startsWith('/settings')) return 4;
  return 0;
}
