import 'dart:math' as math;
import '../../../domain/entities/entities.dart';

/// Represents a budgeted vendor agreement / event expense that supports multi-installment payments.
class BudgetExpense {
  final String id;
  final String eventId;
  final String? categoryId;
  final String categoryName;
  final String vendorName;
  final String? vendorPhone;
  final String? personId;
  final String title;
  final int agreedAmountPaise;
  final int paidAmountPaise;
  final String paymentMode; // 'cash' | 'upi' | 'bank'
  final String? upiApp;
  final String? upiRef;
  final String expenseDate;
  final String? targetPayDate;
  final String? billPhotoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BudgetExpensePayment> payments;

  const BudgetExpense({
    required this.id,
    required this.eventId,
    this.categoryId,
    this.categoryName = '',
    required this.vendorName,
    this.vendorPhone,
    this.personId,
    required this.title,
    this.agreedAmountPaise = 0,
    this.paidAmountPaise = 0,
    this.paymentMode = 'cash',
    this.upiApp,
    this.upiRef,
    required this.expenseDate,
    this.targetPayDate,
    this.billPhotoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.payments = const [],
  });

  /// Effective total commitment: agreed cost if set, else paid amount.
  int get effectiveTotalPaise =>
      agreedAmountPaise > 0 ? agreedAmountPaise : paidAmountPaise;

  /// Remaining balance owed to vendor/payee when an agreed deal exists.
  int get remainingPaise => agreedAmountPaise > paidAmountPaise
      ? agreedAmountPaise - paidAmountPaise
      : 0;

  bool get isSettled =>
      agreedAmountPaise <= 0 || paidAmountPaise >= agreedAmountPaise;

  BudgetExpense copyWith({
    String? id,
    String? eventId,
    String? categoryId,
    String? categoryName,
    String? vendorName,
    String? vendorPhone,
    String? personId,
    String? title,
    int? agreedAmountPaise,
    int? paidAmountPaise,
    String? paymentMode,
    String? upiApp,
    String? upiRef,
    String? expenseDate,
    String? targetPayDate,
    String? billPhotoPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BudgetExpensePayment>? payments,
  }) {
    return BudgetExpense(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      vendorName: vendorName ?? this.vendorName,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      personId: personId ?? this.personId,
      title: title ?? this.title,
      agreedAmountPaise: agreedAmountPaise ?? this.agreedAmountPaise,
      paidAmountPaise: paidAmountPaise ?? this.paidAmountPaise,
      paymentMode: paymentMode ?? this.paymentMode,
      upiApp: upiApp ?? this.upiApp,
      upiRef: upiRef ?? this.upiRef,
      expenseDate: expenseDate ?? this.expenseDate,
      targetPayDate: targetPayDate ?? this.targetPayDate,
      billPhotoPath: billPhotoPath ?? this.billPhotoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payments: payments ?? this.payments,
    );
  }
}

/// Represents a single payment installment towards a [BudgetExpense].
class BudgetExpensePayment {
  final String id;
  final String expenseId;
  final String eventId;
  final int amountPaise;
  final String paymentMode;
  final String? upiApp;
  final String? upiRef;
  final String paymentDate;
  final String? receiptPhotoPath;
  final String? note;
  final DateTime createdAt;

  const BudgetExpensePayment({
    required this.id,
    required this.expenseId,
    required this.eventId,
    required this.amountPaise,
    this.paymentMode = 'cash',
    this.upiApp,
    this.upiRef,
    required this.paymentDate,
    this.receiptPhotoPath,
    this.note,
    required this.createdAt,
  });
}

/// Represents temporary arranged / borrowed family assistance for an event,
/// completely isolated from the Shagun (Mila/Diya) ledger.
class FundArrangement {
  final String id;
  final String? eventId;
  final String lenderName;
  final String? lenderPhone;
  final String? personId;
  final int principalPaise;
  final int extraAgreedPaise;
  final int returnedPaise;
  final String paymentMode;
  final String? upiApp;
  final String? upiRef;
  final String takenDate;
  final String? returnTargetDate;
  final String? notes;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<FundRepayment> repayments;

  const FundArrangement({
    required this.id,
    this.eventId,
    required this.lenderName,
    this.lenderPhone,
    this.personId,
    required this.principalPaise,
    this.extraAgreedPaise = 0,
    this.returnedPaise = 0,
    this.paymentMode = 'cash',
    this.upiApp,
    this.upiRef,
    required this.takenDate,
    this.returnTargetDate,
    this.notes,
    this.isSettled = false,
    required this.createdAt,
    required this.updatedAt,
    this.repayments = const [],
  });

  int get totalReturnablePaise => principalPaise + extraAgreedPaise;

  int get remainingPaise => totalReturnablePaise > returnedPaise
      ? totalReturnablePaise - returnedPaise
      : 0;

  bool get effectiveIsSettled =>
      isSettled || (totalReturnablePaise > 0 && returnedPaise >= totalReturnablePaise);

  double get progressRatio => totalReturnablePaise > 0
      ? (returnedPaise / totalReturnablePaise).clamp(0.0, 1.0)
      : 1.0;

  FundArrangement copyWith({
    String? id,
    String? eventId,
    String? lenderName,
    String? lenderPhone,
    String? personId,
    int? principalPaise,
    int? extraAgreedPaise,
    int? returnedPaise,
    String? paymentMode,
    String? upiApp,
    String? upiRef,
    String? takenDate,
    String? returnTargetDate,
    String? notes,
    bool? isSettled,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FundRepayment>? repayments,
  }) {
    return FundArrangement(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      lenderName: lenderName ?? this.lenderName,
      lenderPhone: lenderPhone ?? this.lenderPhone,
      personId: personId ?? this.personId,
      principalPaise: principalPaise ?? this.principalPaise,
      extraAgreedPaise: extraAgreedPaise ?? this.extraAgreedPaise,
      returnedPaise: returnedPaise ?? this.returnedPaise,
      paymentMode: paymentMode ?? this.paymentMode,
      upiApp: upiApp ?? this.upiApp,
      upiRef: upiRef ?? this.upiRef,
      takenDate: takenDate ?? this.takenDate,
      returnTargetDate: returnTargetDate ?? this.returnTargetDate,
      notes: notes ?? this.notes,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      repayments: repayments ?? this.repayments,
    );
  }
}

/// Represents a partial or full return installment for a [FundArrangement].
class FundRepayment {
  final String id;
  final String arrangementId;
  final int amountPaise;
  final String paymentMode;
  final String? upiApp;
  final String? upiRef;
  final String repaymentDate;
  final String? note;
  final DateTime createdAt;

  const FundRepayment({
    required this.id,
    required this.arrangementId,
    required this.amountPaise,
    this.paymentMode = 'cash',
    this.upiApp,
    this.upiRef,
    required this.repaymentDate,
    this.note,
    required this.createdAt,
  });
}

/// Aggregated payee / vendor view showing how much was agreed, paid, and remaining.
class VendorBudgetSummary {
  final String vendorName;
  final String? vendorPhone;
  final String? personId;
  final int totalAgreedPaise;
  final int totalPaidPaise;
  final int totalPendingPaise;
  final String latestDate;
  final List<BudgetExpense> expenses;

  const VendorBudgetSummary({
    required this.vendorName,
    this.vendorPhone,
    this.personId,
    required this.totalAgreedPaise,
    required this.totalPaidPaise,
    required this.totalPendingPaise,
    required this.latestDate,
    required this.expenses,
  });

  bool get isSettled => totalPendingPaise <= 0;
}

/// Consolidated metrics for the Budget & Kharch Hub hero & overview tabs.
class BudgetOverviewStats {
  final int plannedBudgetPaise;
  final int totalCommittedCostPaise;
  final int totalPaidPaise;
  final int totalVendorPendingPaise;
  final int totalBorrowedPaise;
  final int totalReturnedPaise;
  final int totalBorrowRemainingPaise;
  final int activeArrangementsCount;
  final double utilizationRatio;
  final bool isOverBudget;
  final List<VendorBudgetSummary> vendorSummaries;

  const BudgetOverviewStats({
    this.plannedBudgetPaise = 0,
    this.totalCommittedCostPaise = 0,
    this.totalPaidPaise = 0,
    this.totalVendorPendingPaise = 0,
    this.totalBorrowedPaise = 0,
    this.totalReturnedPaise = 0,
    this.totalBorrowRemainingPaise = 0,
    this.activeArrangementsCount = 0,
    this.utilizationRatio = 0.0,
    this.isOverBudget = false,
    this.vendorSummaries = const [],
  });

  int get budgetRemainingPaise =>
      plannedBudgetPaise > totalPaidPaise ? plannedBudgetPaise - totalPaidPaise : 0;

  int get overBudgetPaise =>
      totalPaidPaise > plannedBudgetPaise ? totalPaidPaise - plannedBudgetPaise : 0;
}

/// Combined reactive state container for the Budget Hub.
class BudgetDashboardSnapshot {
  final List<Event> events;
  final List<EventBudgetCategory> categories;
  final List<BudgetExpense> expenses;
  final List<FundArrangement> arrangements;

  const BudgetDashboardSnapshot({
    this.events = const [],
    this.categories = const [],
    this.expenses = const [],
    this.arrangements = const [],
  });
}

/// Category quick-setup template definition.
class BudgetCategoryPreset {
  final String key;
  final String labelEn;
  final String labelHi;
  final String labelUr;

  const BudgetCategoryPreset({
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.labelUr,
  });

  String labelForLanguage(String langCode) {
    if (langCode == 'en') return labelEn;
    if (langCode == 'ur') return labelUr;
    return labelHi;
  }
}

/// Pure, testable aggregation rules for Event Budget & Returnable Fund tracking.
class BudgetCalculations {
  BudgetCalculations._();

  static const List<BudgetCategoryPreset> standardWeddingPresets = [
    BudgetCategoryPreset(
      key: 'catering',
      labelEn: 'Catering & Halwai',
      labelHi: 'खान-पान व हलवाई',
      labelUr: 'کھانا اور حلوائی',
    ),
    BudgetCategoryPreset(
      key: 'tent',
      labelEn: 'Tent, Mandap & Decor',
      labelHi: 'टेंट, मंडप व सजावट',
      labelUr: 'ٹینٹ اور سجاوٹ',
    ),
    BudgetCategoryPreset(
      key: 'jewelry_clothes',
      labelEn: 'Clothes & Jewelry',
      labelHi: 'कपड़े व आभूषण',
      labelUr: 'کپڑے اور زیورات',
    ),
    BudgetCategoryPreset(
      key: 'music',
      labelEn: 'Band, DJ & Sound',
      labelHi: 'बैंड, बाजा व डीजे',
      labelUr: 'بینڈ اور ڈی جے',
    ),
    BudgetCategoryPreset(
      key: 'photo',
      labelEn: 'Photography & Video',
      labelHi: 'फोटोग्राफी व वीडियो',
      labelUr: 'فوٹوگرافی اور ویڈیو',
    ),
    BudgetCategoryPreset(
      key: 'travel',
      labelEn: 'Vehicles & Travel',
      labelHi: 'वाहन व यात्रा',
      labelUr: 'گاڑیاں اور سفر',
    ),
    BudgetCategoryPreset(
      key: 'gifts_cards',
      labelEn: 'Cards & Return Gifts',
      labelHi: 'निमंत्रण कार्ड व विदाई भेंट',
      labelUr: 'دعوت نامے اور تحائف',
    ),
    BudgetCategoryPreset(
      key: 'ceremony',
      labelEn: 'Rituals & Priest',
      labelHi: 'पूजा सामग्री व पंडित',
      labelUr: 'رسومات اور پوجا',
    ),
  ];

  /// Computes filtered summary metrics for either a specific [eventId] or all events (`null`).
  static BudgetOverviewStats summarize({
    required List<EventBudgetCategory> categories,
    required List<BudgetExpense> expenses,
    required List<FundArrangement> arrangements,
    String? eventId,
  }) {
    final scopedCategories = eventId == null
        ? categories
        : categories.where((c) => c.eventId == eventId).toList();
    final scopedExpenses = eventId == null
        ? expenses
        : expenses.where((e) => e.eventId == eventId).toList();
    final scopedArrangements = eventId == null
        ? arrangements
        : arrangements.where((a) => a.eventId == eventId).toList();

    var planned = 0;
    for (final c in scopedCategories) {
      planned += c.estimatedAmountPaise;
    }

    // Group recorded detailed expenses per category so legacy manual `actualAmountPaise`
    // without detail rows is preserved without double counting.
    final expensesPaidByCategory = <String, int>{};
    var totalCommitted = 0;
    var totalPaid = 0;
    var totalVendorPending = 0;

    for (final exp in scopedExpenses) {
      totalCommitted += exp.effectiveTotalPaise;
      totalPaid += exp.paidAmountPaise;
      totalVendorPending += exp.remainingPaise;
      if (exp.categoryId != null && exp.categoryId!.isNotEmpty) {
        expensesPaidByCategory[exp.categoryId!] =
            (expensesPaidByCategory[exp.categoryId!] ?? 0) + exp.paidAmountPaise;
      }
    }

    for (final cat in scopedCategories) {
      final detailedForCat = expensesPaidByCategory[cat.id];
      if (detailedForCat == null && cat.actualAmountPaise > 0) {
        totalCommitted += cat.actualAmountPaise;
        totalPaid += cat.actualAmountPaise;
      }
    }

    // Vendor groupings sorted with highest pending balance first, then highest paid.
    final vendorBuckets = <String, List<BudgetExpense>>{};
    for (final exp in scopedExpenses) {
      final key = exp.vendorName.trim().toLowerCase();
      final bucketKey = key.isEmpty ? '__unnamed__' : key;
      vendorBuckets.putIfAbsent(bucketKey, () => <BudgetExpense>[]).add(exp);
    }

    final vendors = <VendorBudgetSummary>[];
    for (final bucket in vendorBuckets.values) {
      var agreed = 0;
      var paid = 0;
      var pending = 0;
      String? phone;
      String? personId;
      var latest = '';
      final displayName = bucket.first.vendorName.trim();

      for (final e in bucket) {
        agreed += e.effectiveTotalPaise;
        paid += e.paidAmountPaise;
        pending += e.remainingPaise;
        phone ??= (e.vendorPhone != null && e.vendorPhone!.trim().isNotEmpty)
            ? e.vendorPhone!.trim()
            : null;
        personId ??= e.personId;
        if (e.expenseDate.compareTo(latest) > 0) {
          latest = e.expenseDate;
        }
      }

      vendors.add(
        VendorBudgetSummary(
          vendorName: displayName,
          vendorPhone: phone,
          personId: personId,
          totalAgreedPaise: agreed,
          totalPaidPaise: paid,
          totalPendingPaise: pending,
          latestDate: latest,
          expenses: bucket,
        ),
      );
    }

    vendors.sort((a, b) {
      final pendingCmp = b.totalPendingPaise.compareTo(a.totalPendingPaise);
      if (pendingCmp != 0) return pendingCmp;
      return b.totalPaidPaise.compareTo(a.totalPaidPaise);
    });

    var borrowed = 0;
    var returned = 0;
    var borrowRemaining = 0;
    var activeArrangementsCount = 0;

    for (final arr in scopedArrangements) {
      borrowed += arr.totalReturnablePaise;
      returned += arr.returnedPaise;
      final rem = arr.remainingPaise;
      borrowRemaining += rem;
      if (!arr.effectiveIsSettled && rem > 0) {
        activeArrangementsCount++;
      }
    }

    final ratio = planned > 0
        ? math.min(1.0, math.max(0.0, totalPaid / planned))
        : (totalPaid > 0 ? 1.0 : 0.0);

    return BudgetOverviewStats(
      plannedBudgetPaise: planned,
      totalCommittedCostPaise: totalCommitted,
      totalPaidPaise: totalPaid,
      totalVendorPendingPaise: totalVendorPending,
      totalBorrowedPaise: borrowed,
      totalReturnedPaise: returned,
      totalBorrowRemainingPaise: borrowRemaining,
      activeArrangementsCount: activeArrangementsCount,
      utilizationRatio: ratio,
      isOverBudget: planned > 0 && totalPaid > planned,
      vendorSummaries: vendors,
    );
  }
}
