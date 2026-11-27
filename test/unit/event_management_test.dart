import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';

void main() {
  group('Advanced Event Management - Domain & Calculations Unit Tests', () {
    final now = DateTime.now();

    test('1. Event Budget and Utilization Calculations', () {
      final event = Event(
        id: 'ev-test-1',
        title: 'विवाह समारोह',
        eventType: EventType.shaadi,
        eventDate: '2026-12-10',
        endDate: '2026-12-12',
        budgetEstimatedPaise: 50000000, // ₹5,00,000 estimated
        budgetCategories: [
          EventBudgetCategory(
            id: 'bc-1',
            eventId: 'ev-test-1',
            categoryName: 'Catering',
            estimatedAmountPaise: 20000000,
            actualAmountPaise: 18000000, // ₹1,80,000
            createdAt: now,
          ),
          EventBudgetCategory(
            id: 'bc-2',
            eventId: 'ev-test-1',
            categoryName: 'Decoration',
            estimatedAmountPaise: 10000000,
            actualAmountPaise: 7000000, // ₹70,000
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // Actual expense = 18000000 + 7000000 = 25000000 paise (₹2,50,000)
      expect(event.actualExpensePaise, equals(25000000));

      // Remaining budget = 50000000 - 25000000 = 25000000 paise (₹2,50,000)
      expect(event.remainingBudgetPaise, equals(25000000));

      // Utilization = (25000000 / 50000000) * 100 = 50.0%
      expect(event.budgetUtilizationPercent, closeTo(50.0, 0.01));
    });

    test('2. Event Task Checklist Progress Metrics', () {
      final event = Event(
        id: 'ev-test-2',
        title: 'मुंडन संस्कार',
        eventType: EventType.mundan,
        eventDate: '2026-11-28',
        tasks: [
          EventTask(
            id: 'task-1',
            eventId: 'ev-test-2',
            title: 'स्थान का आरक्षण',
            status: TaskStatus.completed,
            createdAt: now,
          ),
          EventTask(
            id: 'task-2',
            eventId: 'ev-test-2',
            title: 'पंडित जी से संपर्क',
            status: TaskStatus.completed,
            createdAt: now,
          ),
          EventTask(
            id: 'task-3',
            eventId: 'ev-test-2',
            title: 'मिठाई का आर्डर',
            status: TaskStatus.inProgress,
            createdAt: now,
          ),
          EventTask(
            id: 'task-4',
            eventId: 'ev-test-2',
            title: 'निमंत्रण पत्र वितरण',
            status: TaskStatus.pending,
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(event.tasks.length, equals(4));
      expect(event.completedTasksCount, equals(2));
      // 2 / 4 = 50.0%
      expect(event.taskCompletionPercentage, closeTo(50.0, 0.01));
    });

    test('3. Guest RSVP and Attendance Calculations', () {
      final event = Event(
        id: 'ev-test-3',
        title: 'सगाई उत्सव',
        eventType: EventType.engagement,
        eventDate: '2026-12-01',
        guests: [
          EventGuest(
            id: 'gst-1',
            eventId: 'ev-test-3',
            name: 'वर्मा परिवार',
            invitationStatus: InvitationStatus.accepted,
            attendanceStatus: AttendanceStatus.attending,
            accompanyingCount: 3, // 1 + 3 = 4
            createdAt: now,
          ),
          EventGuest(
            id: 'gst-2',
            eventId: 'ev-test-3',
            name: 'सिंह साहब',
            invitationStatus: InvitationStatus.sent,
            attendanceStatus: AttendanceStatus.attending,
            accompanyingCount: 1, // 1 + 1 = 2
            createdAt: now,
          ),
          EventGuest(
            id: 'gst-3',
            eventId: 'ev-test-3',
            name: 'गुप्ता जी',
            invitationStatus: InvitationStatus.declined,
            attendanceStatus: AttendanceStatus.notAttending,
            accompanyingCount: 0, // 1 + 0 = 1
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      // Total guest head-count = (1+3) + (1+1) + (1+0) = 7
      expect(event.totalGuestCount, equals(7));

      // Confirmed attending head-count = (1+3) + (1+1) = 6
      expect(event.confirmedGuestCount, equals(6));
    });

    test('4. Event copyWith and Immutability', () {
      final original = Event(
        id: 'ev-copy-1',
        title: 'गृह प्रवेश',
        eventType: EventType.grihaPravesh,
        eventDate: '2026-12-15',
        status: EventStatus.planned,
        priority: EventPriority.normal,
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        status: EventStatus.confirmed,
        priority: EventPriority.urgent,
        venue: 'नई हवेली, बनारस',
      );

      expect(original.status, equals(EventStatus.planned));
      expect(original.priority, equals(EventPriority.normal));
      expect(original.venue, isNull);

      expect(updated.id, equals(original.id));
      expect(updated.title, equals(original.title));
      expect(updated.status, equals(EventStatus.confirmed));
      expect(updated.priority, equals(EventPriority.urgent));
      expect(updated.venue, equals('नई हवेली, बनारस'));
    });

    test('5. Multi-Function Ceremony Association', () {
      final event = Event(
        id: 'ev-wedding',
        title: 'विशाल एवं अंकिता विवाह',
        eventType: EventType.shaadi,
        eventDate: '2026-12-20',
        endDate: '2026-12-22',
        functions: [
          EventFunction(
            id: 'fn-1',
            eventId: 'ev-wedding',
            title: 'हल्दी रस्म',
            functionDate: '2026-12-20',
            startTime: '10:00',
            venue: 'निवास स्थान',
            createdAt: now,
            updatedAt: now,
          ),
          EventFunction(
            id: 'fn-2',
            eventId: 'ev-wedding',
            title: 'मेहंदी व संगीत',
            functionDate: '2026-12-20',
            startTime: '18:00',
            venue: 'होटल रीजेंसी',
            createdAt: now,
            updatedAt: now,
          ),
          EventFunction(
            id: 'fn-3',
            eventId: 'ev-wedding',
            title: 'शुभ विवाह लग्न',
            functionDate: '2026-12-21',
            startTime: '21:00',
            venue: 'रॉयल पैलेस',
            createdAt: now,
            updatedAt: now,
          ),
          EventFunction(
            id: 'fn-4',
            eventId: 'ev-wedding',
            title: 'आशीर्वाद व रिसेप्शन',
            functionDate: '2026-12-22',
            startTime: '19:00',
            venue: 'क्लब हॉल',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(event.functions.length, equals(4));
      expect(event.functions.first.title, equals('हल्दी रस्म'));
      expect(event.functions.last.title, equals('आशीर्वाद व रिसेप्शन'));
    });

    test('5. Event copyWith clear flags erase optional fields properly and enum localization works', () {
      final event = Event(
        id: 'ev-clear',
        title: 'विवाह',
        eventType: EventType.shaadi,
        eventDate: '2026-12-20',
        endDate: '2026-12-22',
        venue: 'शर्मा भवन',
        address: 'स्टेशन रोड',
        villageCity: 'जयपुर',
        landmark: 'मंदिर के पास',
        mapLink: 'https://maps.example.com',
        description: 'मुख्य विवरण',
        notes: 'अतिरिक्त नोट',
        budgetEstimatedPaise: 500000,
        createdAt: now,
        updatedAt: now,
      );

      final cleared = event.copyWith(
        clearEndDate: true,
        clearVenue: true,
        clearAddress: true,
        clearVillageCity: true,
        clearLandmark: true,
        clearMapLink: true,
        clearDescription: true,
        clearNotes: true,
        clearBudgetEstimatedPaise: true,
      );

      expect(cleared.endDate, isNull);
      expect(cleared.venue, isNull);
      expect(cleared.address, isNull);
      expect(cleared.villageCity, isNull);
      expect(cleared.landmark, isNull);
      expect(cleared.mapLink, isNull);
      expect(cleared.description, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.budgetEstimatedPaise, isNull);

      final cat = EventBudgetCategory(
        id: 'c1',
        eventId: 'ev-clear',
        categoryName: 'टेंट',
        notes: 'पुराना नोट',
        createdAt: now,
      ).copyWith(clearNotes: true);
      expect(cat.notes, isNull);

      expect(EventStatus.confirmed.labelForLocale('en'), equals('Confirmed'));
      expect(EventStatus.confirmed.labelForLocale('ur'), equals('طے شدہ'));
      expect(EventStatus.confirmed.labelForLocale('hi'), equals('पुष्ट'));
    });
  });
}
