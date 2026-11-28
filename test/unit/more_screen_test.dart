import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/app/app_providers.dart';
import 'package:vyavahaar/src/app/theme/app_theme.dart';
import 'package:vyavahaar/src/core/localization/app_localizations.dart';
import 'package:vyavahaar/src/core/theme/ui_preferences_notifier.dart';
import 'package:vyavahaar/src/data/repositories/settings_repository.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/entities/family_profile.dart';
import 'package:vyavahaar/src/features/budget/domain/budget_models.dart';
import 'package:vyavahaar/src/features/budget/presentation/budget_providers.dart';
import 'package:vyavahaar/src/features/more/presentation/more_screen.dart';

class _InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> _values = {};

  @override
  Future<void> addCustomEventType(String newType) async {}

  @override
  Future<Map<String, String>> getAllSettings() async => Map.of(_values);

  @override
  Future<List<String>> getCustomEventTypes() async => const [];

  @override
  Future<String?> getSetting(String key) async => _values[key];

  @override
  Future<void> removeCustomEventType(String typeToDelete) async {}

  @override
  Future<void> setSetting(String key, String value) async {
    _values[key] = value;
  }

  @override
  Stream<List<String>> watchCustomEventTypes() => Stream.value(const []);

  @override
  Stream<String?> watchSetting(String key) => Stream.value(_values[key]);
}

void main() {
  Widget wrapMoreScreen({
    FamilyProfile profile = const FamilyProfile(
      familyName: 'Jitendra Pal',
      headOfFamily: 'Jitendra Pal',
    ),
    int pendingReminders = 1,
    BudgetDashboardSnapshot budgetSnapshot = const BudgetDashboardSnapshot(),
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenReports,
    VoidCallback? onOpenReminders,
    ValueChanged<bool>? onOpenFamilyProfile,
    VoidCallback? onOpenBudgetPlanner,
  }) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_InMemorySettingsRepository()),
        pendingRemindersCountProvider.overrideWith(
          (_) => Stream.value(pendingReminders),
        ),
        familyProfileProvider.overrideWith((_) => Stream.value(profile)),
        budgetDashboardProvider.overrideWith(
          (_) => Stream.value(budgetSnapshot),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('hi'),
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('hi'), Locale('en'), Locale('ur')],
        home: MoreScreen(
          onOpenSettings: onOpenSettings ?? () {},
          onOpenReports: onOpenReports ?? () {},
          onOpenReminders: onOpenReminders ?? () {},
          onOpenFamilyProfile: onOpenFamilyProfile ?? (_) {},
          onOpenBudgetPlanner: onOpenBudgetPlanner,
        ),
      ),
    );
  }

  group('Clean MoreScreen Hub Tests', () {
    testWidgets(
      'renders only core More tools and hides duplicate Settings items',
      (tester) async {
        var settingsTapped = 0;
        var budgetTapped = 0;
        var reportsTapped = 0;
        var remindersTapped = 0;
        var familyTapped = 0;

        await tester.pumpWidget(
          wrapMoreScreen(
            onOpenSettings: () => settingsTapped++,
            onOpenBudgetPlanner: () => budgetTapped++,
            onOpenReports: () => reportsTapped++,
            onOpenReminders: () => remindersTapped++,
            onOpenFamilyProfile: (_) => familyTapped++,
          ),
        );
        await tester.pumpAndSettle();

        // Core More Hub sections are visible
        expect(find.text('अधिक विकल्प'), findsOneWidget);
        expect(find.text('Jitendra Pal'), findsOneWidget);
        expect(find.text('बजट व खर्च प्लानर'), findsOneWidget);
        expect(find.text('रिपोर्ट व एक्सपोर्ट'), findsOneWidget);
        expect(find.text('अनुस्मारक'), findsOneWidget);
        expect(find.text('1 लंबित'), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

        // Duplicate Settings / clutter sections are strictly removed
        expect(find.text('थीम व रंग'), findsNothing);
        expect(find.text('भाषा चुनें'), findsNothing);
        expect(find.text('ऐप परिचय (ऑनबोर्डिंग)'), findsNothing);
        expect(find.text('त्वरित शॉर्टकट'), findsNothing);
        expect(find.text('100% ऑफ़लाइन व सुरक्षित'), findsNothing);

        // Interactions work cleanly
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump();
        expect(settingsTapped, 1);

        await tester.tap(find.text('बजट व खर्च प्लानर'));
        await tester.pump();
        expect(budgetTapped, 1);

        await tester.tap(find.text('रिपोर्ट व एक्सपोर्ट'));
        await tester.pump();
        expect(reportsTapped, 1);

        await tester.tap(find.text('अनुस्मारक'));
        await tester.pump();
        expect(remindersTapped, 1);

        await tester.tap(find.text('Jitendra Pal'));
        await tester.pump();
        expect(familyTapped, 1);
      },
    );

    testWidgets(
      'shows compact Budget stats strip only when financial metrics exist and supports Classic mode',
      (tester) async {
        final now = DateTime.utc(2026, 11, 28);
        final snapshot = BudgetDashboardSnapshot(
          categories: [
            EventBudgetCategory(
              id: 'cat-1',
              eventId: 'ev-1',
              categoryName: 'Catering',
              estimatedAmountPaise: 5000000, // ₹50,000
              actualAmountPaise: 0,
              createdAt: now,
            ),
          ],
          expenses: [
            BudgetExpense(
              id: 'exp-1',
              eventId: 'ev-1',
              categoryId: 'cat-1',
              vendorName: 'Sharma Halwai',
              title: 'Advance',
              agreedAmountPaise: 2000000,
              paidAmountPaise: 1000000, // ₹10,000
              expenseDate: '2026-11-28',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          arrangements: [
            FundArrangement(
              id: 'arr-1',
              lenderName: 'Mama Ji',
              principalPaise: 1500000, // ₹15,000
              returnedPaise: 500000, // ₹10,000 remaining
              takenDate: '2026-11-28',
              createdAt: now,
              updatedAt: now,
            ),
          ],
        );

        await tester.pumpWidget(
          wrapMoreScreen(pendingReminders: 0, budgetSnapshot: snapshot),
        );
        await tester.pumpAndSettle();

        expect(find.text('₹50,000'), findsOneWidget);
        expect(find.text('₹10,000'), findsNWidgets(2)); // paid + return remaining

        // Switch to Classic visual style dynamically and verify clean render
        final element = tester.element(find.byType(MoreScreen));
        final container = ProviderScope.containerOf(element);
        await container
            .read(uiPreferencesProvider.notifier)
            .setStyle(SettingsVisualStyle.classic);
        await tester.pumpAndSettle();

        expect(find.text('अधिक विकल्प'), findsOneWidget);
        expect(find.text('बजट व खर्च प्लानर'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
