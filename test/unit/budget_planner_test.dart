import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:vyavahaar/src/data/database/app_database.dart';
import 'package:vyavahaar/src/data/repositories/entries_repository.dart';
import 'package:vyavahaar/src/data/repositories/events_repository.dart';
import 'package:vyavahaar/src/data/repositories/people_repository.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';
import 'package:vyavahaar/src/domain/rules/financial_rules.dart';
import 'package:vyavahaar/src/features/budget/data/budget_repository.dart';
import 'package:vyavahaar/src/features/budget/domain/budget_models.dart';
import 'package:vyavahaar/src/features/settings/services/backup_service.dart';

void _configureLinuxSqlite() {
  open.overrideFor(OperatingSystem.linux, () {
    for (final path in [
      '/usr/lib/aarch64-linux-gnu/libsqlite3.so.0',
      '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
      'libsqlite3.so.0',
      'libsqlite3.so',
    ]) {
      try {
        return DynamicLibrary.open(path);
      } catch (_) {}
    }
    return DynamicLibrary.open('libsqlite3.so');
  });
}

void main() {
  setUpAll(_configureLinuxSqlite);

  group('Event Budget, Payees & Returnable Fund Planner Tests', () {
    test('tracks vendor deals, installments, legacy category carry-over & syncs category spend', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final eventsRepo = DriftEventsRepository(db);
      final budgetRepo = DriftBudgetRepository(db, eventsRepo);
      final now = DateTime.now();

      await eventsRepo.createEvent(
        Event(
          id: 'ev_b_1',
          title: 'शादी समारोह',
          eventType: EventType.shaadi,
          eventDate: '2026-12-20',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await eventsRepo.addBudgetCategory(
        EventBudgetCategory(
          id: 'cat_catering',
          eventId: 'ev_b_1',
          categoryName: 'खान-पान व हलवाई',
          estimatedAmountPaise: 10000000, // ₹1,00,000
          actualAmountPaise: 500000, // Legacy manual ₹5,000 already recorded
          createdAt: now,
        ),
      );

      // Save an ₹80,000 deal with ₹25,000 UPI advance
      await budgetRepo.saveExpense(
        expense: BudgetExpense(
          id: 'exp_1',
          eventId: 'ev_b_1',
          categoryId: 'cat_catering',
          categoryName: 'खान-पान व हलवाई',
          vendorName: 'रामू हलवाई',
          vendorPhone: '+919829012345',
          title: 'मिठाई व भोजन बुकिंग',
          agreedAmountPaise: 8000000, // ₹80,000
          paidAmountPaise: 2500000, // ₹25,000
          paymentMode: 'upi',
          upiApp: 'PhonePe',
          upiRef: 'UTR123456',
          expenseDate: '2026-11-28',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Add second installment ₹35,000
      await budgetRepo.addExpensePayment(
        payment: BudgetExpensePayment(
          id: 'pay_2',
          expenseId: 'exp_1',
          eventId: 'ev_b_1',
          amountPaise: 3500000, // ₹35,000
          paymentMode: 'cash',
          paymentDate: '2026-12-05',
          note: 'दूसरी किस्त',
          createdAt: now,
        ),
      );

      final snap = await budgetRepo.getDashboardSnapshot();
      final exp = snap.expenses.firstWhere((e) => e.id == 'exp_1');
      expect(exp.paidAmountPaise, 6000000); // ₹60,000 paid
      expect(exp.remainingPaise, 2000000); // ₹20,000 remaining
      expect(exp.payments.length, 2);

      // Legacy ₹5,000 + ₹60,000 = ₹65,000 synced cleanly into category.actualAmountPaise
      final cat = snap.categories.firstWhere((c) => c.id == 'cat_catering');
      expect(cat.actualAmountPaise, 6500000);
    });

    test('records returnable fund arrangements, auto reminders, partial returns, and isolates Shagun rules', () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());

      final eventsRepo = DriftEventsRepository(db);
      final peopleRepo = DriftPeopleRepository(db);
      final entriesRepo = DriftEntriesRepository(db);
      final budgetRepo = DriftBudgetRepository(db, eventsRepo);
      final now = DateTime.now();

      await eventsRepo.createEvent(
        Event(
          id: 'ev_b_2',
          title: 'गृह प्रवेश',
          eventType: EventType.grihaPravesh,
          eventDate: '2026-12-10',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await peopleRepo.createPerson(
        Person(
          id: 'p_lender',
          fullName: 'महेश शर्मा',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Also add a normal Shagun entry to verify complete financial isolation
      await entriesRepo.saveEntryWithItemsAtomic(
        entry: TransactionEntry(
          id: 'ent_shagun_1',
          personId: 'p_lender',
          eventId: 'ev_b_2',
          direction: TransactionDirection.received,
          transactionType: TransactionType.cash,
          status: TransactionStatus.recorded,
          amountPaise: 110000, // ₹1,100 Shagun
          transactionDate: '2026-12-10',
          createdAt: now,
          updatedAt: now,
        ),
        items: const [],
      );

      // Take ₹50,000 temporary arranged assistance with target return date & auto-reminder
      await budgetRepo.saveFundArrangement(
        arrangement: FundArrangement(
          id: 'arr_1',
          eventId: 'ev_b_2',
          lenderName: 'महेश शर्मा',
          lenderPhone: '9876543210',
          personId: 'p_lender',
          principalPaise: 5000000, // ₹50,000
          extraAgreedPaise: 0,
          paymentMode: 'upi',
          upiApp: 'GPay',
          takenDate: '2026-11-28',
          returnTargetDate: '2027-01-15',
          notes: 'टेंट पेमेंट हेतु अस्थायी मदद',
          createdAt: now,
          updatedAt: now,
        ),
        autoAddReminder: true,
      );

      final allReminders = await db.remindersDao.watchAllReminders().first;
      expect(allReminders.length, 1);
      expect(allReminders.first.reminderDate, '2027-01-15');

      // Return ₹20,000 first, then ₹30,000
      await budgetRepo.addFundRepayment(
        repayment: FundRepayment(
          id: 'rep_1',
          arrangementId: 'arr_1',
          amountPaise: 2000000,
          paymentMode: 'cash',
          repaymentDate: '2026-12-18',
          createdAt: now,
        ),
      );

      var snap = await budgetRepo.getDashboardSnapshot();
      var stats = BudgetCalculations.summarize(
        categories: snap.categories,
        expenses: snap.expenses,
        arrangements: snap.arrangements,
        eventId: 'ev_b_2',
      );
      expect(stats.totalBorrowedPaise, 5000000);
      expect(stats.totalReturnedPaise, 2000000);
      expect(stats.totalBorrowRemainingPaise, 3000000);
      expect(stats.activeArrangementsCount, 1);

      await budgetRepo.addFundRepayment(
        repayment: FundRepayment(
          id: 'rep_2',
          arrangementId: 'arr_1',
          amountPaise: 3000000,
          paymentMode: 'upi',
          upiApp: 'GPay',
          repaymentDate: '2027-01-10',
          createdAt: now,
        ),
      );

      snap = await budgetRepo.getDashboardSnapshot();
      stats = BudgetCalculations.summarize(
        categories: snap.categories,
        expenses: snap.expenses,
        arrangements: snap.arrangements,
        eventId: 'ev_b_2',
      );
      expect(stats.totalBorrowRemainingPaise, 0);
      expect(stats.activeArrangementsCount, 0);
      expect(snap.arrangements.first.effectiveIsSettled, isTrue);

      // Verify Shagun ledger figures remain 100% isolated from Budget & Borrowed Funds
      final allEntries = await entriesRepo.watchEntries().first;
      expect(FinancialRules.calculateTotalReceivedPaise(allEntries), 110000);
      expect(FinancialRules.calculateTotalGivenPaise(allEntries), 0);
    });

    test('ZIP backup and one-shot restore preserves budget expenses, receipts & fund arrangements', () async {
      final dbSource = AppDatabase.inMemory();
      addTearDown(() async => dbSource.close());

      final srcDir = Directory.systemTemp.createTempSync('vyavahaar_budget_src_');
      final dstDir = Directory.systemTemp.createTempSync('vyavahaar_budget_dst_');
      addTearDown(() {
        if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
        if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
      });

      final receiptsDir = Directory(p.join(srcDir.path, 'budget_receipts'))
        ..createSync(recursive: true);
      final billFile = File(p.join(receiptsDir.path, 'tent_bill.jpg'))
        ..writeAsBytesSync(Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]));

      final eventsRepo = DriftEventsRepository(dbSource);
      final budgetRepo = DriftBudgetRepository(dbSource, eventsRepo);
      final now = DateTime.now();

      await eventsRepo.createEvent(
        Event(
          id: 'ev_b_zip',
          title: 'मुंडन कार्यक्रम',
          eventType: EventType.mundan,
          eventDate: '2026-12-05',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await budgetRepo.saveExpense(
        expense: BudgetExpense(
          id: 'exp_zip_1',
          eventId: 'ev_b_zip',
          vendorName: 'राजू टेंट हाउस',
          title: 'टेंट व लाइट',
          agreedAmountPaise: 3000000,
          paidAmountPaise: 1500000,
          paymentMode: 'cash',
          expenseDate: '2026-12-01',
          billPhotoPath: billFile.path,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await budgetRepo.saveFundArrangement(
        arrangement: FundArrangement(
          id: 'arr_zip_1',
          eventId: 'ev_b_zip',
          lenderName: 'सुनील गुप्ता',
          principalPaise: 2500000,
          returnedPaise: 500000,
          takenDate: '2026-12-01',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final backupResult = await BackupService(dbSource).createZipBackup(
        overrideBaseDir: srcDir,
      );

      final dbRestored = AppDatabase.inMemory();
      addTearDown(() async => dbRestored.close());

      await BackupService(dbRestored).restoreBackup(
        backupResult.file,
        overrideBaseDir: dstDir,
      );

      final restoredSnap =
          await DriftBudgetRepository(dbRestored).getDashboardSnapshot();
      expect(restoredSnap.expenses.length, 1);
      expect(restoredSnap.expenses.first.vendorName, 'राजू टेंट हाउस');
      expect(restoredSnap.expenses.first.paidAmountPaise, 1500000);
      expect(
        File(restoredSnap.expenses.first.billPhotoPath!).existsSync(),
        isTrue,
      );
      expect(restoredSnap.arrangements.length, 1);
      expect(restoredSnap.arrangements.first.lenderName, 'सुनील गुप्ता');
      expect(restoredSnap.arrangements.first.principalPaise, 2500000);
    });
  });
}
