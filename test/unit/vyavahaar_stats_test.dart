import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/features/reports/data/vyavahaar_stats.dart';

void main() {
  final now = DateTime(2026, 11, 28);

  final events = [
    Event(
      id: 'ev-shaadi',
      title: 'Sharma Wedding',
      eventType: EventType.shaadi,
      eventDate: '2026-11-15',
      createdAt: now,
      updatedAt: now,
    ),
    Event(
      id: 'ev-mundan',
      title: 'Aarav Mundan',
      eventType: EventType.mundan,
      eventDate: '2025-05-10',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final entries = [
    TransactionEntry(
      id: 't1',
      personId: 'p1',
      personName: 'Mama Ji',
      eventId: 'ev-shaadi',
      eventTitle: 'Sharma Wedding',
      direction: TransactionDirection.received,
      transactionType: TransactionType.cash,
      status: TransactionStatus.recorded,
      amountPaise: 510000,
      transactionDate: '2026-11-15',
      createdAt: now,
      updatedAt: now,
    ),
    TransactionEntry(
      id: 't2',
      personId: 'p2',
      personName: 'Chacha Ji',
      eventId: 'ev-shaadi',
      eventTitle: 'Sharma Wedding',
      direction: TransactionDirection.given,
      transactionType: TransactionType.cashAndItem,
      status: TransactionStatus.recorded,
      amountPaise: 210000,
      transactionDate: '2026-11-20',
      createdAt: now,
      updatedAt: now,
      items: [
        EntryItem(
          id: 'i1',
          entryId: 't2',
          itemName: 'Saree',
          estimatedValuePaise: 150000,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    ),
    // Planned entry must not pollute recorded Mila/Diya totals
    TransactionEntry(
      id: 't3',
      personId: 'p3',
      personName: 'Bua Ji',
      eventId: 'ev-shaadi',
      direction: TransactionDirection.given,
      transactionType: TransactionType.cash,
      status: TransactionStatus.planned,
      amountPaise: 110000,
      transactionDate: '2026-11-29',
      createdAt: now,
      updatedAt: now,
    ),
    // Archived entry must be ignored completely
    TransactionEntry(
      id: 't4',
      personId: 'p1',
      personName: 'Mama Ji',
      direction: TransactionDirection.received,
      transactionType: TransactionType.cash,
      status: TransactionStatus.recorded,
      amountPaise: 999900,
      transactionDate: '2026-11-01',
      createdAt: now,
      updatedAt: now,
      archivedAt: now,
    ),
    // Prior year entry (2025)
    TransactionEntry(
      id: 't5',
      personId: 'p4',
      personName: 'Mausa Ji',
      eventId: 'ev-mundan',
      eventTitle: 'Aarav Mundan',
      direction: TransactionDirection.received,
      transactionType: TransactionType.item,
      status: TransactionStatus.recorded,
      transactionDate: '2025-05-10',
      createdAt: DateTime(2025, 5, 10),
      updatedAt: DateTime(2025, 5, 10),
      items: [
        EntryItem(
          id: 'i2',
          entryId: 't5',
          itemName: 'Silver Coin',
          estimatedValuePaise: 200000,
          createdAt: DateTime(2025, 5, 10),
          updatedAt: DateTime(2025, 5, 10),
        ),
      ],
    ),
  ];

  group('VyavahaarStats Analytics Engine', () {
    test('computes isolated Mila/Diya, excludes archived & planned from recorded totals', () {
      final stats = VyavahaarStats.compute(
        allEntries: entries,
        events: events,
        selectedYear: 2026,
        referenceNow: now,
      );

      expect(stats.totalReceivedPaise, 510000);
      expect(stats.totalGivenPaise, 210000);
      expect(stats.receivedCount, 1);
      expect(stats.givenCount, 1);
      expect(stats.cashTotalPaise, 720000);
      expect(stats.estimatedGiftPaise, 150000);
      expect(stats.giftItemCount, 1);
      expect(stats.pendingCount, 1);
      expect(stats.pendingPaise, 110000);
      expect(stats.activeDays, 2);
      expect(stats.bestMonthIndex, 10); // November (0-indexed)
      expect(stats.monthlyReceivedPaise[10], 510000);
      expect(stats.monthlyGivenPaise[10], 210000);
      expect(stats.dailyCounts['2026-11-15'], 1);
      expect(stats.dailyCounts['2026-11-20'], 1);
      expect(stats.topPeopleReceived.first.name, 'Mama Ji');
      expect(stats.topPeopleGiven.first.name, 'Chacha Ji');
      expect(stats.topEvents.first.title, 'Sharma Wedding');
      expect(stats.eventTypeSlices.first.eventType, EventType.shaadi);
    });

    test('supports All-Years, Scope filters, Event filters, and Hero Ratio', () {
      final allYears = VyavahaarStats.compute(
        allEntries: entries,
        events: events,
        selectedYear: null,
        heroPeriod: ReportHeroPeriod.allTime,
        referenceNow: now,
      );

      expect(allYears.totalCount, 3);
      expect(allYears.estimatedGiftPaise, 350000);
      expect(allYears.availableYears, containsAll([2026, 2025]));
      // Mila share: 510000 / (510000 + 210000) = 71%
      expect(allYears.heroMetrics.milaSharePercent, 71);

      final giftsOnly = VyavahaarStats.compute(
        allEntries: entries,
        events: events,
        scope: ReportScopeFilter.giftsOnly,
        selectedYear: null,
        referenceNow: now,
      );
      expect(giftsOnly.totalCount, 2);
      expect(giftsOnly.giftItemCount, 2);

      final mundanOnly = VyavahaarStats.compute(
        allEntries: entries,
        events: events,
        selectedYear: null,
        selectedEventId: 'ev-mundan',
        referenceNow: now,
      );
      expect(mundanOnly.totalCount, 1);
      expect(mundanOnly.topPeopleReceived.first.name, 'Mausa Ji');
    });
  });
}
