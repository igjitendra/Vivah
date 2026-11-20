import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/entities.dart';
import '../../shared/navigation/floating_pill_tab_bar.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

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
  initialLocation: '/',
  routes: [
    // ShellRoute hosting the FloatingPillTabBar on mobile
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final int index = _calculateSelectedIndex(state.uri.path);
        return Scaffold(
          body: Stack(
            children: [
              child,
              FloatingPillTabBar(
                currentIndex: index,
                items: appTabs,
                onTabSelected: (idx) {
                  context.go(appTabs[idx].routePath);
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
            child: DashboardScreen(
              summary: DashboardSummary.empty(),
              onNewEntry: () => context.push('/entry/new'),
              onNewEvent: () => context.push('/event/new'),
              onNewPerson: () => context.push('/person/new'),
              onOpenSettings: () => context.go('/settings'),
            ),
          ),
        ),
        // Tab 2: Bahi Khata (Ledger)
        GoRoute(
          path: '/bahi',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(
              body: Center(child: Text(AppStrings.tabBahi, style: TextStyle(fontSize: 18))),
            ),
          ),
        ),
        // Tab 3: Events (कार्यक्रम)
        GoRoute(
          path: '/events',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(
              body: Center(child: Text(AppStrings.tabEvents, style: TextStyle(fontSize: 18))),
            ),
          ),
        ),
        // Tab 4: People (लोग)
        GoRoute(
          path: '/people',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(
              body: Center(child: Text(AppStrings.tabPeople, style: TextStyle(fontSize: 18))),
            ),
          ),
        ),
        // Tab 5: Settings (सेटिंग्स)
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Scaffold(
              body: Center(child: Text(AppStrings.tabSettings, style: TextStyle(fontSize: 18))),
            ),
          ),
        ),
      ],
    ),
    // Fullscreen Subroutes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/entry/new',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('नया व्यवहार दर्ज करें फॉर्म')),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/event/new',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('नया कार्यक्रम बनाएं फॉर्म')),
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/person/new',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('नया व्यक्ति जोड़ें फॉर्म')),
      ),
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
