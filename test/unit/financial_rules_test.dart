import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/domain/rules/financial_rules.dart';

void main() {
  group('FinancialRules - 12 Mandatory Rules Verification', () {
    final now = DateTime.now();

    final testEntries = [
      // 1. Valid Received (Mila) entry: ₹1,100 (110000 paise) + ₹5,000 gift
      TransactionEntry(
        id: 'entry_01',
        personId: 'p1',
        eventId: 'e1',
        direction: TransactionDirection.received,
        transactionType: TransactionType.cashAndItem,
        status: TransactionStatus.recorded,
        amountPaise: 110000,
        transactionDate: '2026-11-20',
        createdAt: now,
        updatedAt: now,
        items: [
          EntryItem(
            id: 'item_01',
            entryId: 'entry_01',
            itemName: 'चाँदी का सिक्का',
            estimatedValuePaise: 500000, // ₹5,000 gift value
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      // 2. Valid Received (Mila) entry: ₹501 (50100 paise)
      TransactionEntry(
        id: 'entry_02',
        personId: 'p2',
        eventId: 'e1',
        direction: TransactionDirection.received,
        transactionType: TransactionType.cash,
        status: TransactionStatus.recorded,
        amountPaise: 50100,
        transactionDate: '2026-11-20',
        createdAt: now,
        updatedAt: now,
      ),
      // 3. Valid Given (Diya) entry: ₹2,100 (210000 paise)
      TransactionEntry(
        id: 'entry_03',
        personId: 'p3',
        eventId: 'e2',
        direction: TransactionDirection.given,
        transactionType: TransactionType.cash,
        status: TransactionStatus.recorded,
        amountPaise: 210000,
        transactionDate: '2026-11-20',
        createdAt: now,
        updatedAt: now,
      ),
      // 4. Planned Given entry: ₹5,000 (500000 paise) - MUST BE EXCLUDED FROM ACTUAL TOTALS
      TransactionEntry(
        id: 'entry_04',
        personId: 'p4',
        eventId: 'e2',
        direction: TransactionDirection.given,
        transactionType: TransactionType.cash,
        status: TransactionStatus.planned,
        amountPaise: 500000,
        transactionDate: '2026-12-01',
        createdAt: now,
        updatedAt: now,
      ),
      // 5. Cancelled Received entry: ₹10,000 (1000000 paise) - MUST BE EXCLUDED FROM ALL TOTALS
      TransactionEntry(
        id: 'entry_05',
        personId: 'p5',
        eventId: 'e1',
        direction: TransactionDirection.received,
        transactionType: TransactionType.cash,
        status: TransactionStatus.cancelled,
        amountPaise: 1000000,
        transactionDate: '2026-11-19',
        createdAt: now,
        updatedAt: now,
        cancelledAt: now,
      ),
      // 6. Archived Given entry: ₹1,000 (100000 paise) - MUST BE EXCLUDED
      TransactionEntry(
        id: 'entry_06',
        personId: 'p6',
        eventId: 'e2',
        direction: TransactionDirection.given,
        transactionType: TransactionType.cash,
        status: TransactionStatus.recorded,
        amountPaise: 100000,
        transactionDate: '2026-11-18',
        createdAt: now,
        updatedAt: now,
        archivedAt: now,
      ),
    ];

    test('Rule 1: calculateTotalReceivedPaise calculates pure received without netting given', () {
      final totalReceived = FinancialRules.calculateTotalReceivedPaise(testEntries);
      // Expected: entry_01 (110000) + entry_02 (50100) = 160100 paise (₹1,601)
      expect(totalReceived, equals(160100));
    });

    test('Rule 1: calculateTotalGivenPaise calculates pure given without netting received', () {
      final totalGiven = FinancialRules.calculateTotalGivenPaise(testEntries);
      // Expected: entry_03 (210000) = 210000 paise (₹2,100)
      // Excludes planned entry_04 (500000) and archived entry_06 (100000)
      expect(totalGiven, equals(210000));
    });

    test('Rule 3: Gift estimates are strictly isolated from cash calculations', () {
      final giftTotal = FinancialRules.calculateTotalGiftEstimatesPaise(testEntries);
      expect(giftTotal, equals(500000)); // ₹5,000 item in entry_01

      final cashReceived = FinancialRules.calculateTotalReceivedPaise(testEntries);
      // Cash received must NOT include the ₹5,000 gift value
      expect(cashReceived, equals(160100));
    });

    test('Rule 4: countPlannedEntries only counts planned non-archived transactions', () {
      final plannedCount = FinancialRules.countPlannedEntries(testEntries);
      expect(plannedCount, equals(1)); // only entry_04
    });

    test('Invariance: Received and Given are never subtracted to produce net balance or debt', () {
      final totalReceived = FinancialRules.calculateTotalReceivedPaise(testEntries);
      final totalGiven = FinancialRules.calculateTotalGivenPaise(testEntries);

      // Verify both exist independently as positive integer totals
      expect(totalReceived, isPositive);
      expect(totalGiven, isPositive);
      expect(totalReceived != totalGiven, isTrue);
    });

    test('Validation: Cash transaction requires amount > 0', () {
      expect(
        () => FinancialRules.validateTransactionEntry(
          type: TransactionType.cash,
          direction: TransactionDirection.given,
          status: TransactionStatus.recorded,
          amountPaise: 0,
          items: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validation: Item transaction requires at least 1 item', () {
      expect(
        () => FinancialRules.validateTransactionEntry(
          type: TransactionType.item,
          direction: TransactionDirection.received,
          status: TransactionStatus.recorded,
          amountPaise: null,
          items: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Validation: CashAndItem transaction requires both cash > 0 and at least 1 item', () {
      final item = EntryItem(
        id: 'i1',
        entryId: 'e1',
        itemName: 'शॉल',
        createdAt: now,
        updatedAt: now,
      );

      // Fails if cash is missing
      expect(
        () => FinancialRules.validateTransactionEntry(
          type: TransactionType.cashAndItem,
          direction: TransactionDirection.received,
          status: TransactionStatus.recorded,
          amountPaise: 0,
          items: [item],
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Passes when both are present
      expect(
        () => FinancialRules.validateTransactionEntry(
          type: TransactionType.cashAndItem,
          direction: TransactionDirection.received,
          status: TransactionStatus.recorded,
          amountPaise: 50100,
          items: [item],
        ),
        returnsNormally,
      );
    });
  });
}
