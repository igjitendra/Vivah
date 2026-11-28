import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/migrations/schema_migrations.dart';
import '../../../data/repositories/events_repository.dart';
import '../../../domain/entities/entities.dart';
import '../domain/budget_models.dart';

/// Contract for offline persistence & reactive streaming of Event Budgets,
/// Vendor Payments, and Returnable Fund Arrangements.
abstract class BudgetRepository {
  Future<BudgetDashboardSnapshot> getDashboardSnapshot();
  Stream<BudgetDashboardSnapshot> watchDashboardSnapshot();

  Future<void> saveExpense({
    required BudgetExpense expense,
    bool autoAddReminder = false,
    String? reminderTitle,
  });

  Future<void> addExpensePayment({
    required BudgetExpensePayment payment,
  });

  Future<void> deleteExpense(String expenseId);

  Future<void> saveFundArrangement({
    required FundArrangement arrangement,
    bool autoAddReminder = false,
    String? reminderTitle,
  });

  Future<void> addFundRepayment({
    required FundRepayment repayment,
  });

  Future<void> deleteFundArrangement(String arrangementId);

  Future<int> createCategoriesFromPresets({
    required String eventId,
    required List<({String name, int estimatedPaise})> presets,
  });
}

class DriftBudgetRepository implements BudgetRepository {
  static const _uuid = Uuid();
  final AppDatabase _db;
  final EventsRepository _eventsRepo;
  bool _schemaReady = false;

  DriftBudgetRepository(this._db, [EventsRepository? eventsRepo])
      : _eventsRepo = eventsRepo ?? DriftEventsRepository(_db);

  Future<void> _ensureReady() async {
    if (_schemaReady) return;
    await SchemaMigrations.ensureAllTablesAndColumns(_db);
    _schemaReady = true;
  }

  Variable<String> _nullableText(String? val) {
    final trimmed = val?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const Variable<String>(null);
    }
    return Variable.withString(trimmed);
  }

  @override
  Future<BudgetDashboardSnapshot> getDashboardSnapshot() async {
    await _ensureReady();

    final events = await _eventsRepo.getAllActiveEvents();

    // Load all budget categories across active events
    final activeEventIds = events.map((e) => e.id).toSet();
    final catRows = await _safeSelect(
      'SELECT * FROM event_budget_categories ORDER BY category_name ASC',
    );
    final categories = catRows
        .map((d) => EventBudgetCategory(
              id: d['id'] as String,
              eventId: d['event_id'] as String,
              categoryName: (d['category_name'] as String?) ?? '',
              estimatedAmountPaise:
                  (d['estimated_amount_paise'] as num?)?.toInt() ?? 0,
              actualAmountPaise:
                  (d['actual_amount_paise'] as num?)?.toInt() ?? 0,
              notes: d['notes'] as String?,
              createdAt:
                  DateTime.tryParse(d['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            ))
        .where((c) => activeEventIds.isEmpty || activeEventIds.contains(c.eventId))
        .toList();

    // Load expense payments grouped by expense_id
    final payRows = await _safeSelect(
      'SELECT * FROM event_expense_payments ORDER BY payment_date DESC, created_at DESC',
    );
    final paymentsByExpense = <String, List<BudgetExpensePayment>>{};
    for (final d in payRows) {
      final p = BudgetExpensePayment(
        id: d['id'] as String,
        expenseId: d['expense_id'] as String,
        eventId: d['event_id'] as String,
        amountPaise: (d['amount_paise'] as num?)?.toInt() ?? 0,
        paymentMode: (d['payment_mode'] as String?) ?? 'cash',
        upiApp: d['upi_app'] as String?,
        upiRef: d['upi_ref'] as String?,
        paymentDate: (d['payment_date'] as String?) ?? '',
        receiptPhotoPath: d['receipt_photo_path'] as String?,
        note: d['note'] as String?,
        createdAt:
            DateTime.tryParse(d['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
      paymentsByExpense
          .putIfAbsent(p.expenseId, () => <BudgetExpensePayment>[])
          .add(p);
    }

    final expenseRows = await _safeSelect(
      'SELECT * FROM event_budget_expenses ORDER BY expense_date DESC, created_at DESC',
    );
    final expenses = expenseRows
        .map((d) {
          final id = d['id'] as String;
          return BudgetExpense(
            id: id,
            eventId: d['event_id'] as String,
            categoryId: d['category_id'] as String?,
            categoryName: (d['category_name'] as String?) ?? '',
            vendorName: (d['vendor_name'] as String?) ?? '',
            vendorPhone: d['vendor_phone'] as String?,
            personId: d['person_id'] as String?,
            title: (d['title'] as String?) ?? '',
            agreedAmountPaise: (d['agreed_amount_paise'] as num?)?.toInt() ?? 0,
            paidAmountPaise: (d['paid_amount_paise'] as num?)?.toInt() ?? 0,
            paymentMode: (d['payment_mode'] as String?) ?? 'cash',
            upiApp: d['upi_app'] as String?,
            upiRef: d['upi_ref'] as String?,
            expenseDate: (d['expense_date'] as String?) ?? '',
            targetPayDate: d['target_pay_date'] as String?,
            billPhotoPath: d['bill_photo_path'] as String?,
            notes: d['notes'] as String?,
            createdAt:
                DateTime.tryParse(d['created_at']?.toString() ?? '') ??
                    DateTime.now(),
            updatedAt:
                DateTime.tryParse(d['updated_at']?.toString() ?? '') ??
                    DateTime.now(),
            payments: paymentsByExpense[id] ?? const [],
          );
        })
        .where((e) => activeEventIds.isEmpty || activeEventIds.contains(e.eventId))
        .toList();

    // Load fund repayments grouped by arrangement_id
    final repayRows = await _safeSelect(
      'SELECT * FROM event_fund_repayments ORDER BY repayment_date DESC, created_at DESC',
    );
    final repaymentsByArrangement = <String, List<FundRepayment>>{};
    for (final d in repayRows) {
      final r = FundRepayment(
        id: d['id'] as String,
        arrangementId: d['arrangement_id'] as String,
        amountPaise: (d['amount_paise'] as num?)?.toInt() ?? 0,
        paymentMode: (d['payment_mode'] as String?) ?? 'cash',
        upiApp: d['upi_app'] as String?,
        upiRef: d['upi_ref'] as String?,
        repaymentDate: (d['repayment_date'] as String?) ?? '',
        note: d['note'] as String?,
        createdAt:
            DateTime.tryParse(d['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
      repaymentsByArrangement
          .putIfAbsent(r.arrangementId, () => <FundRepayment>[])
          .add(r);
    }

    final arrRows = await _safeSelect(
      'SELECT * FROM event_fund_arrangements ORDER BY is_settled ASC, taken_date DESC, created_at DESC',
    );
    final arrangements = arrRows.map((d) {
      final id = d['id'] as String;
      return FundArrangement(
        id: id,
        eventId: d['event_id'] as String?,
        lenderName: (d['lender_name'] as String?) ?? '',
        lenderPhone: d['lender_phone'] as String?,
        personId: d['person_id'] as String?,
        principalPaise: (d['principal_paise'] as num?)?.toInt() ?? 0,
        extraAgreedPaise: (d['extra_agreed_paise'] as num?)?.toInt() ?? 0,
        returnedPaise: (d['returned_paise'] as num?)?.toInt() ?? 0,
        paymentMode: (d['payment_mode'] as String?) ?? 'cash',
        upiApp: d['upi_app'] as String?,
        upiRef: d['upi_ref'] as String?,
        takenDate: (d['taken_date'] as String?) ?? '',
        returnTargetDate: d['return_target_date'] as String?,
        notes: d['notes'] as String?,
        isSettled: ((d['is_settled'] as num?)?.toInt() ?? 0) == 1,
        createdAt:
            DateTime.tryParse(d['created_at']?.toString() ?? '') ??
                DateTime.now(),
        updatedAt:
            DateTime.tryParse(d['updated_at']?.toString() ?? '') ??
                DateTime.now(),
        repayments: repaymentsByArrangement[id] ?? const [],
      );
    }).toList();

    return BudgetDashboardSnapshot(
      events: events,
      categories: categories,
      expenses: expenses,
      arrangements: arrangements,
    );
  }

  @override
  Stream<BudgetDashboardSnapshot> watchDashboardSnapshot() {
    // Reading from `{_db.events, _db.reminders}` keeps budget hub synced live with EventDetailScreen & Reminders.
    return _db
        .customSelect(
          'SELECT COUNT(*) FROM events',
          readsFrom: {_db.events, _db.reminders},
        )
        .watch()
        .asyncMap((_) => getDashboardSnapshot());
  }

  Future<List<Map<String, dynamic>>> _safeSelect(String sql) async {
    try {
      final rows = await _db.customSelect(sql).get();
      return rows.map((r) => r.data).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveExpense({
    required BudgetExpense expense,
    bool autoAddReminder = false,
    String? reminderTitle,
  }) async {
    await _ensureReady();
    await _db.transaction(() async {
      // Preserve any pre-existing manual category spend that had no itemized expenses yet.
      if (expense.categoryId != null && expense.categoryId!.isNotEmpty) {
        await _preserveLegacyCategorySpendIfNeeded(
          eventId: expense.eventId,
          categoryId: expense.categoryId!,
          categoryName: expense.categoryName,
        );
      }

      final existingRows = await _db.customSelect(
        'SELECT id FROM event_budget_expenses WHERE id = ?',
        variables: [Variable.withString(expense.id)],
      ).get();
      final isNew = existingRows.isEmpty;

      await _db.customInsert(
        '''
        INSERT OR REPLACE INTO event_budget_expenses (
          id, event_id, category_id, category_name, vendor_name, vendor_phone,
          person_id, title, agreed_amount_paise, paid_amount_paise, payment_mode,
          upi_app, upi_ref, expense_date, target_pay_date, bill_photo_path,
          notes, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(expense.id),
          Variable.withString(expense.eventId),
          _nullableText(expense.categoryId),
          Variable.withString(expense.categoryName),
          Variable.withString(expense.vendorName.trim()),
          _nullableText(expense.vendorPhone),
          _nullableText(expense.personId),
          Variable.withString(expense.title.trim()),
          Variable.withInt(expense.agreedAmountPaise),
          Variable.withInt(expense.paidAmountPaise),
          Variable.withString(expense.paymentMode),
          _nullableText(expense.upiApp),
          _nullableText(expense.upiRef),
          Variable.withString(expense.expenseDate),
          _nullableText(expense.targetPayDate),
          _nullableText(expense.billPhotoPath),
          _nullableText(expense.notes),
          Variable.withString(expense.createdAt.toIso8601String()),
          Variable.withString(expense.updatedAt.toIso8601String()),
        ],
        updates: {_db.events},
      );

      if (isNew && expense.paidAmountPaise > 0) {
        await _db.customInsert(
          '''
          INSERT INTO event_expense_payments (
            id, expense_id, event_id, amount_paise, payment_mode,
            upi_app, upi_ref, payment_date, receipt_photo_path, note, created_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          variables: [
            Variable.withString(_uuid.v4()),
            Variable.withString(expense.id),
            Variable.withString(expense.eventId),
            Variable.withInt(expense.paidAmountPaise),
            Variable.withString(expense.paymentMode),
            _nullableText(expense.upiApp),
            _nullableText(expense.upiRef),
            Variable.withString(expense.expenseDate),
            _nullableText(expense.billPhotoPath),
            _nullableText(expense.notes),
            Variable.withString(expense.createdAt.toIso8601String()),
          ],
          updates: {_db.events},
        );
      }

      if (expense.categoryId != null && expense.categoryId!.isNotEmpty) {
        await _recalculateCategoryActualSpent(expense.categoryId!);
      }

      if (autoAddReminder &&
          expense.targetPayDate != null &&
          expense.targetPayDate!.trim().isNotEmpty &&
          expense.remainingPaise > 0) {
        await _insertAutoReminder(
          reminderDate: expense.targetPayDate!.trim(),
          title: (reminderTitle != null && reminderTitle.trim().isNotEmpty)
              ? reminderTitle.trim()
              : '${expense.vendorName.trim()} — ${expense.title.trim()}',
          notes: expense.notes,
        );
      }
    });
  }

  @override
  Future<void> addExpensePayment({
    required BudgetExpensePayment payment,
  }) async {
    await _ensureReady();
    await _db.transaction(() async {
      await _db.customInsert(
        '''
        INSERT INTO event_expense_payments (
          id, expense_id, event_id, amount_paise, payment_mode,
          upi_app, upi_ref, payment_date, receipt_photo_path, note, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(payment.id),
          Variable.withString(payment.expenseId),
          Variable.withString(payment.eventId),
          Variable.withInt(payment.amountPaise),
          Variable.withString(payment.paymentMode),
          _nullableText(payment.upiApp),
          _nullableText(payment.upiRef),
          Variable.withString(payment.paymentDate),
          _nullableText(payment.receiptPhotoPath),
          _nullableText(payment.note),
          Variable.withString(payment.createdAt.toIso8601String()),
        ],
        updates: {_db.events},
      );

      final totalRows = await _db.customSelect(
        'SELECT COALESCE(SUM(amount_paise), 0) AS total_paid FROM event_expense_payments WHERE expense_id = ?',
        variables: [Variable.withString(payment.expenseId)],
      ).get();
      final totalPaid = (totalRows.first.data['total_paid'] as num?)?.toInt() ?? 0;

      await _db.customUpdate(
        'UPDATE event_budget_expenses SET paid_amount_paise = ?, payment_mode = ?, upi_app = ?, upi_ref = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(totalPaid),
          Variable.withString(payment.paymentMode),
          _nullableText(payment.upiApp),
          _nullableText(payment.upiRef),
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withString(payment.expenseId),
        ],
        updates: {_db.events},
      );

      final catRows = await _db.customSelect(
        'SELECT category_id FROM event_budget_expenses WHERE id = ?',
        variables: [Variable.withString(payment.expenseId)],
      ).get();
      final categoryId = catRows.isNotEmpty
          ? (catRows.first.data['category_id'] as String?)
          : null;
      if (categoryId != null && categoryId.isNotEmpty) {
        await _recalculateCategoryActualSpent(categoryId);
      }
    });
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _ensureReady();
    await _db.transaction(() async {
      final catRows = await _db.customSelect(
        'SELECT category_id FROM event_budget_expenses WHERE id = ?',
        variables: [Variable.withString(expenseId)],
      ).get();
      final categoryId = catRows.isNotEmpty
          ? (catRows.first.data['category_id'] as String?)
          : null;

      await _db.customUpdate(
        'DELETE FROM event_budget_expenses WHERE id = ?',
        variables: [Variable.withString(expenseId)],
        updates: {_db.events},
      );

      if (categoryId != null && categoryId.isNotEmpty) {
        await _recalculateCategoryActualSpent(categoryId);
      }
    });
  }

  @override
  Future<void> saveFundArrangement({
    required FundArrangement arrangement,
    bool autoAddReminder = false,
    String? reminderTitle,
  }) async {
    await _ensureReady();
    await _db.transaction(() async {
      await _db.customInsert(
        '''
        INSERT OR REPLACE INTO event_fund_arrangements (
          id, event_id, lender_name, lender_phone, person_id,
          principal_paise, extra_agreed_paise, returned_paise, payment_mode,
          upi_app, upi_ref, taken_date, return_target_date, notes,
          is_settled, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(arrangement.id),
          _nullableText(arrangement.eventId),
          Variable.withString(arrangement.lenderName.trim()),
          _nullableText(arrangement.lenderPhone),
          _nullableText(arrangement.personId),
          Variable.withInt(arrangement.principalPaise),
          Variable.withInt(arrangement.extraAgreedPaise),
          Variable.withInt(arrangement.returnedPaise),
          Variable.withString(arrangement.paymentMode),
          _nullableText(arrangement.upiApp),
          _nullableText(arrangement.upiRef),
          Variable.withString(arrangement.takenDate),
          _nullableText(arrangement.returnTargetDate),
          _nullableText(arrangement.notes),
          Variable.withInt(arrangement.effectiveIsSettled ? 1 : 0),
          Variable.withString(arrangement.createdAt.toIso8601String()),
          Variable.withString(arrangement.updatedAt.toIso8601String()),
        ],
        updates: {_db.events},
      );

      if (autoAddReminder &&
          arrangement.returnTargetDate != null &&
          arrangement.returnTargetDate!.trim().isNotEmpty &&
          !arrangement.effectiveIsSettled) {
        await _insertAutoReminder(
          reminderDate: arrangement.returnTargetDate!.trim(),
          title: (reminderTitle != null && reminderTitle.trim().isNotEmpty)
              ? reminderTitle.trim()
              : '${arrangement.lenderName.trim()} — वापसी अनुस्मारक',
          notes: arrangement.notes,
        );
      }
    });
  }

  @override
  Future<void> addFundRepayment({
    required FundRepayment repayment,
  }) async {
    await _ensureReady();
    await _db.transaction(() async {
      await _db.customInsert(
        '''
        INSERT INTO event_fund_repayments (
          id, arrangement_id, amount_paise, payment_mode,
          upi_app, upi_ref, repayment_date, note, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(repayment.id),
          Variable.withString(repayment.arrangementId),
          Variable.withInt(repayment.amountPaise),
          Variable.withString(repayment.paymentMode),
          _nullableText(repayment.upiApp),
          _nullableText(repayment.upiRef),
          Variable.withString(repayment.repaymentDate),
          _nullableText(repayment.note),
          Variable.withString(repayment.createdAt.toIso8601String()),
        ],
        updates: {_db.events},
      );

      final sumRows = await _db.customSelect(
        'SELECT COALESCE(SUM(amount_paise), 0) AS total_returned FROM event_fund_repayments WHERE arrangement_id = ?',
        variables: [Variable.withString(repayment.arrangementId)],
      ).get();
      final totalReturned =
          (sumRows.first.data['total_returned'] as num?)?.toInt() ?? 0;

      final arrRows = await _db.customSelect(
        'SELECT principal_paise, extra_agreed_paise FROM event_fund_arrangements WHERE id = ?',
        variables: [Variable.withString(repayment.arrangementId)],
      ).get();
      var totalReturnable = 0;
      if (arrRows.isNotEmpty) {
        final d = arrRows.first.data;
        totalReturnable = ((d['principal_paise'] as num?)?.toInt() ?? 0) +
            ((d['extra_agreed_paise'] as num?)?.toInt() ?? 0);
      }
      final settled = totalReturnable > 0 && totalReturned >= totalReturnable;

      await _db.customUpdate(
        'UPDATE event_fund_arrangements SET returned_paise = ?, is_settled = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable.withInt(totalReturned),
          Variable.withInt(settled ? 1 : 0),
          Variable.withString(DateTime.now().toIso8601String()),
          Variable.withString(repayment.arrangementId),
        ],
        updates: {_db.events},
      );
    });
  }

  @override
  Future<void> deleteFundArrangement(String arrangementId) async {
    await _ensureReady();
    await _db.customUpdate(
      'DELETE FROM event_fund_arrangements WHERE id = ?',
      variables: [Variable.withString(arrangementId)],
      updates: {_db.events},
    );
  }

  @override
  Future<int> createCategoriesFromPresets({
    required String eventId,
    required List<({String name, int estimatedPaise})> presets,
  }) async {
    await _ensureReady();
    final existing = await _db.eventsDao.getBudgetCategoriesForEvent(eventId);
    final existingNames =
        existing.map((c) => c.categoryName.trim().toLowerCase()).toSet();
    var added = 0;

    for (final p in presets) {
      final clean = p.name.trim();
      if (clean.isEmpty || existingNames.contains(clean.toLowerCase())) continue;
      existingNames.add(clean.toLowerCase());
      await _db.eventsDao.insertBudgetCategory(
        EventBudgetCategory(
          id: _uuid.v4(),
          eventId: eventId,
          categoryName: clean,
          estimatedAmountPaise: p.estimatedPaise,
          actualAmountPaise: 0,
          createdAt: DateTime.now(),
        ),
      );
      added++;
    }
    return added;
  }

  /// Ensures pre-existing manual spending entered directly on [EventBudgetCategory]
  /// is carried forward cleanly when detailed itemized tracking starts for that category.
  Future<void> _preserveLegacyCategorySpendIfNeeded({
    required String eventId,
    required String categoryId,
    required String categoryName,
  }) async {
    final existingExpCountRows = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM event_budget_expenses WHERE category_id = ?',
      variables: [Variable.withString(categoryId)],
    ).get();
    final cnt = (existingExpCountRows.first.data['cnt'] as num?)?.toInt() ?? 0;
    if (cnt > 0) return;

    final catRows = await _db.customSelect(
      'SELECT actual_amount_paise, category_name, notes, created_at FROM event_budget_categories WHERE id = ?',
      variables: [Variable.withString(categoryId)],
    ).get();
    if (catRows.isEmpty) return;

    final d = catRows.first.data;
    final legacyActual = (d['actual_amount_paise'] as num?)?.toInt() ?? 0;
    if (legacyActual <= 0) return;

    final legacyCatName =
        (d['category_name'] as String?) ?? categoryName;
    final legacyNotes = d['notes'] as String?;
    final legacyId = _uuid.v4();
    final todayIso = DateTime.now().toIso8601String().split('T').first;
    final nowIso = DateTime.now().toIso8601String();

    await _db.customInsert(
      '''
      INSERT INTO event_budget_expenses (
        id, event_id, category_id, category_name, vendor_name,
        title, agreed_amount_paise, paid_amount_paise, payment_mode,
        expense_date, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(legacyId),
        Variable.withString(eventId),
        Variable.withString(categoryId),
        Variable.withString(legacyCatName),
        Variable.withString(legacyCatName),
        Variable.withString(legacyCatName),
        Variable.withInt(legacyActual),
        Variable.withInt(legacyActual),
        Variable.withString('cash'),
        Variable.withString(todayIso),
        _nullableText(legacyNotes),
        Variable.withString(nowIso),
        Variable.withString(nowIso),
      ],
      updates: {_db.events},
    );

    await _db.customInsert(
      '''
      INSERT INTO event_expense_payments (
        id, expense_id, event_id, amount_paise, payment_mode,
        payment_date, note, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(_uuid.v4()),
        Variable.withString(legacyId),
        Variable.withString(eventId),
        Variable.withInt(legacyActual),
        Variable.withString('cash'),
        Variable.withString(todayIso),
        _nullableText(legacyNotes),
        Variable.withString(nowIso),
      ],
      updates: {_db.events},
    );
  }

  Future<void> _recalculateCategoryActualSpent(String categoryId) async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(SUM(paid_amount_paise), 0) AS sum_paid FROM event_budget_expenses WHERE category_id = ?',
      variables: [Variable.withString(categoryId)],
    ).get();
    final sumPaid = (rows.first.data['sum_paid'] as num?)?.toInt() ?? 0;

    await _db.customUpdate(
      'UPDATE event_budget_categories SET actual_amount_paise = ? WHERE id = ?',
      variables: [
        Variable.withInt(sumPaid),
        Variable.withString(categoryId),
      ],
      updates: {_db.events},
    );
  }

  Future<void> _insertAutoReminder({
    required String reminderDate,
    required String title,
    String? notes,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _db.remindersDao.insertReminder(
      RemindersCompanion.insert(
        id: _uuid.v4(),
        reminderDate: reminderDate,
        title: title,
        notes: Value(notes?.trim().isNotEmpty == true ? notes!.trim() : null),
        isCompleted: const Value(false),
        createdAt: Value(nowIso),
        updatedAt: Value(nowIso),
      ),
    );
  }
}
