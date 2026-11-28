import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/express_type.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../shared/widgets/express_settings_kit.dart';
import '../../../shared/widgets/express_shapes.dart';
import '../../../shared/widgets/express_squish.dart';
import '../domain/budget_models.dart';
import '../services/budget_pdf_service.dart';
import 'budget_providers.dart';
import 'budget_sheets.dart';

/// Unified Event Budget, Vendor Payments, and Returnable Fund Hub
/// accessible under More -> Budget & Kharch Planner and Event Details.
class BudgetHubScreen extends ConsumerStatefulWidget {
  final String? initialEventId;
  final int initialTab;

  const BudgetHubScreen({
    super.key,
    this.initialEventId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<BudgetHubScreen> createState() => _BudgetHubScreenState();
}

class _BudgetHubScreenState extends ConsumerState<BudgetHubScreen> {
  static const _uuid = Uuid();
  String? _selectedEventId;
  late int _activeTab;
  int _payeeFilter = 0; // 0: All, 1: Pending, 2: Settled
  int _borrowFilter = 0; // 0: All, 1: Pending, 2: Settled
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    _activeTab = widget.initialTab.clamp(0, 3);
  }

  Future<void> _exportPdf(
    BudgetDashboardSnapshot snapshot,
    BudgetOverviewStats stats,
    List<BudgetExpense> scopedExpenses,
    List<FundArrangement> scopedArrangements,
  ) async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    final l10n = context.l10n;
    try {
      final matchedEvent = _selectedEventId == null
          ? null
          : snapshot.events.where((e) => e.id == _selectedEventId).firstOrNull;
      final eventTitle = matchedEvent?.title ?? l10n.budgetAllEventsFilter;
      final file = await BudgetPdfService.generateBudgetPdf(
        eventTitle: eventTitle,
        stats: stats,
        expenses: scopedExpenses,
        arrangements: scopedArrangements,
        l10n: l10n,
      );
      await BudgetPdfService.printOrSharePdf(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _showEditCategoryBudgetDialog(
    EventBudgetCategory cat,
  ) async {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final nameCtrl = TextEditingController(text: cat.categoryName);
    final budgetCtrl = TextEditingController(
      text: cat.estimatedAmountPaise > 0
          ? (cat.estimatedAmountPaise / 100).round().toString()
          : '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: semantic.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          l10n.editBudgetCategoryLabel,
          style: ExpressType.titleMedium(color: semantic.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.budgetTabCategories),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.plannedBudgetLabel,
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final cleanName = nameCtrl.text.trim();
              if (cleanName.isEmpty) return;
              final est =
                  CurrencyUtils.parseInputToPaise(budgetCtrl.text.trim()) ?? 0;
              await ref.read(eventsRepositoryProvider).updateBudgetCategory(
                    cat.copyWith(
                      categoryName: cleanName,
                      estimatedAmountPaise: est,
                    ),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: semantic.primary,
              foregroundColor: semantic.onVibrant,
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    budgetCtrl.dispose();
  }

  Future<void> _showCreateSingleCategoryDialog(List<Event> events) async {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.createEventBeforeExpenseHint)),
      );
      return;
    }

    var eventId = _selectedEventId ?? events.first.id;
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) => AlertDialog(
          backgroundColor: semantic.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            l10n.addNewCategoryBtn,
            style: ExpressType.titleMedium(color: semantic.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: eventId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.tabEvents),
                items: events
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => eventId = v);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.budgetTabCategories),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.plannedBudgetLabel,
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final cleanName = nameCtrl.text.trim();
                if (cleanName.isEmpty) return;
                final est =
                    CurrencyUtils.parseInputToPaise(budgetCtrl.text.trim()) ?? 0;
                await ref.read(eventsRepositoryProvider).addBudgetCategory(
                      EventBudgetCategory(
                        id: _uuid.v4(),
                        eventId: eventId,
                        categoryName: cleanName,
                        estimatedAmountPaise: est,
                        actualAmountPaise: 0,
                        createdAt: DateTime.now(),
                      ),
                    );
                if (dlgCtx.mounted) Navigator.pop(dlgCtx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.onVibrant,
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    budgetCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final snapAsync = ref.watch(budgetDashboardProvider);

    return snapAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.budgetPlannerTitle)),
        body: Center(child: CircularProgressIndicator(color: semantic.primary)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: Text(l10n.budgetPlannerTitle)),
        body: Center(child: Text('${l10n.errorGeneric}: $err')),
      ),
      data: (snapshot) {
        if (_selectedEventId != null &&
            !snapshot.events.any((e) => e.id == _selectedEventId)) {
          _selectedEventId = null;
        }

        final scopedCategories = _selectedEventId == null
            ? snapshot.categories
            : snapshot.categories
                .where((c) => c.eventId == _selectedEventId)
                .toList();
        final scopedExpenses = _selectedEventId == null
            ? snapshot.expenses
            : snapshot.expenses
                .where((e) => e.eventId == _selectedEventId)
                .toList();
        final scopedArrangements = _selectedEventId == null
            ? snapshot.arrangements
            : snapshot.arrangements
                .where((a) => a.eventId == _selectedEventId)
                .toList();

        final stats = BudgetCalculations.summarize(
          categories: snapshot.categories,
          expenses: snapshot.expenses,
          arrangements: snapshot.arrangements,
          eventId: _selectedEventId,
        );

        final eventNamesById = {
          for (final e in snapshot.events) e.id: e.title,
        };

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 58,
            leadingWidth: 66,
            shape: const Border(),
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: ExpressIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: _exportingPdf
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: semantic.primary,
                          ),
                        )
                      : ExpressIconButton(
                          icon: Icons.picture_as_pdf_outlined,
                          tooltip: 'PDF',
                          onPressed: () => _exportPdf(
                            snapshot,
                            stats,
                            scopedExpenses,
                            scopedArrangements,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      2,
                      18,
                      AppSpacing.floatingTabBottomPadding + 36,
                    ),
                    children: [
                      ExpressHeadline(
                        title: l10n.budgetPlannerTitle,
                        subtitle: l10n.budgetPlannerSubtitle,
                      ),
                      const SizedBox(height: 14),

                      // Event Filter Pills
                      _EventFilterStrip(
                        events: snapshot.events,
                        selectedEventId: _selectedEventId,
                        onSelected: (id) => setState(() => _selectedEventId = id),
                      ),
                      const SizedBox(height: 14),

                      // Hero Summary Card
                      _BudgetHeroSummaryCard(stats: stats),
                      const SizedBox(height: 16),

                      // 4-Tab Pill Switcher
                      _BudgetTabBar(
                        activeTab: _activeTab,
                        onTabChanged: (t) => setState(() => _activeTab = t),
                      ),
                      const SizedBox(height: 16),

                      if (_activeTab == 0)
                        _OverviewTab(
                          stats: stats,
                          categories: scopedCategories,
                          expenses: scopedExpenses,
                          events: snapshot.events,
                          selectedEventId: _selectedEventId,
                          onSwitchTab: (t) => setState(() => _activeTab = t),
                          onAddPresets: () => showAddCategoryPresetsSheet(
                            context: context,
                            ref: ref,
                            events: snapshot.events,
                            preselectedEventId: _selectedEventId,
                          ),
                          onAddBorrow: () => showAddFundArrangementSheet(
                            context: context,
                            ref: ref,
                            events: snapshot.events,
                            preselectedEventId: _selectedEventId,
                          ),
                        )
                      else if (_activeTab == 1)
                        _CategoriesTab(
                          categories: scopedCategories,
                          expenses: scopedExpenses,
                          events: snapshot.events,
                          eventNamesById: eventNamesById,
                          selectedEventId: _selectedEventId,
                          onAddPresets: () => showAddCategoryPresetsSheet(
                            context: context,
                            ref: ref,
                            events: snapshot.events,
                            preselectedEventId: _selectedEventId,
                          ),
                          onAddCustomCategory: () =>
                              _showCreateSingleCategoryDialog(snapshot.events),
                          onEditCategory: _showEditCategoryBudgetDialog,
                          onAddExpenseForCategory: (cat) =>
                              showAddBudgetExpenseSheet(
                            context: context,
                            ref: ref,
                            events: snapshot.events,
                            allCategories: snapshot.categories,
                            preselectedEventId: cat.eventId,
                            preselectedCategoryId: cat.id,
                          ),
                          onTapExpense: (exp) => showExpenseDetailSheet(
                            context: context,
                            ref: ref,
                            expense: exp,
                          ),
                        )
                      else if (_activeTab == 2)
                        _PayeesTab(
                          vendorSummaries: stats.vendorSummaries,
                          filterMode: _payeeFilter,
                          onFilterChanged: (f) => setState(() => _payeeFilter = f),
                          onAddInstallment: (exp) => showAddInstallmentSheet(
                            context: context,
                            ref: ref,
                            expense: exp,
                          ),
                          onTapExpense: (exp) => showExpenseDetailSheet(
                            context: context,
                            ref: ref,
                            expense: exp,
                          ),
                          onAddNewForVendor: (v) => showAddBudgetExpenseSheet(
                            context: context,
                            ref: ref,
                            events: snapshot.events,
                            allCategories: snapshot.categories,
                            preselectedEventId: _selectedEventId,
                            prefillVendorName: v.vendorName,
                            prefillVendorPhone: v.vendorPhone,
                          ),
                        )
                      else
                        _BorrowedFundsTab(
                          stats: stats,
                          arrangements: scopedArrangements,
                          eventNamesById: eventNamesById,
                          filterMode: _borrowFilter,
                          onFilterChanged: (f) => setState(() => _borrowFilter = f),
                          onRecordReturn: (arr) => showRecordRepaymentSheet(
                            context: context,
                            ref: ref,
                            arrangement: arr,
                          ),
                          onTapArrangement: (arr) => showArrangementDetailSheet(
                            context: context,
                            ref: ref,
                            arrangement: arr,
                            eventName: arr.eventId != null
                                ? eventNamesById[arr.eventId!]
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Floating Split Pill Quick-Entry Bar
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: phoneWidth),
                      child: Row(
                        children: [
                          Expanded(
                            child: ExpressButton(
                              label: l10n.addExpenseBtn,
                              icon: Icons.receipt_long_rounded,
                              compact: true,
                              expand: true,
                              onPressed: () => showAddBudgetExpenseSheet(
                                context: context,
                                ref: ref,
                                events: snapshot.events,
                                allCategories: snapshot.categories,
                                preselectedEventId: _selectedEventId,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ExpressButton(
                              label: l10n.addBorrowBtn,
                              icon: Icons.handshake_outlined,
                              tint: semantic.warning,
                              compact: true,
                              expand: true,
                              onPressed: () => showAddFundArrangementSheet(
                                context: context,
                                ref: ref,
                                events: snapshot.events,
                                preselectedEventId: _selectedEventId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventFilterStrip extends StatelessWidget {
  final List<Event> events;
  final String? selectedEventId;
  final ValueChanged<String?> onSelected;

  const _EventFilterStrip({
    required this.events,
    required this.selectedEventId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);

    Widget buildChip({required String? id, required String label}) {
      final active = selectedEventId == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ExpressSquish(
          onTap: () => onSelected(id),
          child: AnimatedContainer(
            duration: Express.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? semantic.primary : semantic.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? semantic.primary : semantic.cardBorder,
              ),
            ),
            child: Text(
              label,
              style: ExpressType.labelMedium(
                color: active ? semantic.onVibrant : semantic.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          buildChip(id: null, label: l10n.budgetAllEventsFilter),
          for (final e in events) buildChip(id: e.id, label: e.title),
        ],
      ),
    );
  }
}

class _BudgetHeroSummaryCard extends StatelessWidget {
  final BudgetOverviewStats stats;

  const _BudgetHeroSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final pct = (stats.utilizationRatio * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [semantic.heroStart, semantic.heroEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.plannedBudgetLabel,
                      style: ExpressType.labelMedium(
                        color: semantic.onHeroMuted,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyUtils.formatPaise(stats.plannedBudgetPaise),
                        style: ExpressType.headlineMedium(
                          color: semantic.onHero,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: stats.isOverBudget
                      ? semantic.badgeAlertBg
                      : semantic.heroHighlight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  stats.plannedBudgetPaise > 0
                      ? '$pct%'
                      : CurrencyUtils.formatPaise(stats.totalPaidPaise),
                  style: ExpressType.labelLarge(
                    color: stats.isOverBudget
                        ? semantic.onBadgeAlert
                        : semantic.heroHighlight,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.utilizationRatio,
              minHeight: 7,
              backgroundColor: semantic.onHero.withValues(alpha: 0.16),
              color: stats.isOverBudget
                  ? semantic.badgeAlertBg
                  : semantic.heroHighlight,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStatCell(
                label: l10n.totalPaidOutLabel,
                value: CurrencyUtils.formatPaise(stats.totalPaidPaise),
                valueColor: semantic.onHero,
                labelColor: semantic.onHeroMuted,
              ),
              _HeroStatCell(
                label: l10n.vendorPendingLabel,
                value: CurrencyUtils.formatPaise(stats.totalVendorPendingPaise),
                valueColor: stats.totalVendorPendingPaise > 0
                    ? semantic.heroHighlight
                    : semantic.onHero,
                labelColor: semantic.onHeroMuted,
              ),
              _HeroStatCell(
                label: l10n.returnRemainingLabel,
                value: CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                valueColor: stats.totalBorrowRemainingPaise > 0
                    ? semantic.heroHighlight
                    : semantic.onHero,
                labelColor: semantic.onHeroMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: semantic.onHero.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: semantic.heroHighlight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.budgetIsolatedNote,
                    style: ExpressType.labelSmall(
                      color: semantic.onHeroMuted,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;

  const _HeroStatCell({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExpressType.labelSmall(color: labelColor),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: ExpressType.titleSmall(
                color: valueColor,
                weight: FontWeight.w800,
              ).copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTabBar extends StatelessWidget {
  final int activeTab;
  final ValueChanged<int> onTabChanged;

  const _BudgetTabBar({
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final labels = [
      l10n.budgetTabOverview,
      l10n.budgetTabCategories,
      l10n.budgetTabPayees,
      l10n.budgetTabBorrowed,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              ExpressSquish(
                onTap: () => onTabChanged(i),
                child: AnimatedContainer(
                  duration: Express.fast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: activeTab == i
                        ? semantic.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    style: ExpressType.labelMedium(
                      color: activeTab == i
                          ? semantic.onVibrant
                          : semantic.textSecondary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final BudgetOverviewStats stats;
  final List<EventBudgetCategory> categories;
  final List<BudgetExpense> expenses;
  final List<Event> events;
  final String? selectedEventId;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onAddPresets;
  final VoidCallback onAddBorrow;

  const _OverviewTab({
    required this.stats,
    required this.categories,
    required this.expenses,
    required this.events,
    required this.selectedEventId,
    required this.onSwitchTab,
    required this.onAddPresets,
    required this.onAddBorrow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Alert Cards if pending payees or pending returns exist
        if (stats.totalVendorPendingPaise > 0 ||
            stats.totalBorrowRemainingPaise > 0) ...[
          ExpressGroup(
            children: [
              if (stats.totalVendorPendingPaise > 0)
                ExpressTile(
                  icon: Icons.storefront_outlined,
                  tint: semantic.warning,
                  title: l10n.vendorPendingLabel,
                  value: CurrencyUtils.formatPaise(stats.totalVendorPendingPaise),
                  onTap: () => onSwitchTab(2),
                ),
              if (stats.totalBorrowRemainingPaise > 0)
                ExpressTile(
                  icon: Icons.handshake_outlined,
                  tint: semantic.diya,
                  title: l10n.returnRemainingLabel,
                  subtitle: '${stats.activeArrangementsCount} ${l10n.filterActiveOnly}',
                  value: CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                  onTap: () => onSwitchTab(3),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Borrowed Funds Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExpressBlob(
                    size: 38,
                    color: semantic.warningContainer,
                    shape: ExpressShape.cookie,
                    child: Icon(
                      Icons.handshake_outlined,
                      size: 19,
                      color: semantic.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.budgetTabBorrowed,
                      style: ExpressType.titleMedium(color: semantic.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSwitchTab(3),
                    child: Text(l10n.all),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    label: l10n.takenAmountLabel,
                    value: CurrencyUtils.formatPaise(stats.totalBorrowedPaise),
                    color: semantic.textPrimary,
                  ),
                  _MiniStat(
                    label: l10n.returnedAmountLabel,
                    value: CurrencyUtils.formatPaise(stats.totalReturnedPaise),
                    color: semantic.mila,
                  ),
                  _MiniStat(
                    label: l10n.returnRemainingLabel,
                    value:
                        CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                    color: stats.totalBorrowRemainingPaise > 0
                        ? semantic.diya
                        : semantic.mila,
                  ),
                ],
              ),
              if (stats.totalBorrowedPaise == 0) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: Icon(Icons.add, size: 16, color: semantic.primary),
                    label: Text(l10n.addBorrowBtn),
                    onPressed: onAddBorrow,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Category Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.budgetTabCategories,
                      style: ExpressType.titleMedium(color: semantic.textPrimary),
                    ),
                  ),
                  if (events.isNotEmpty)
                    TextButton.icon(
                      onPressed: onAddPresets,
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                      label: Text(l10n.addCategoryPresetsBtn),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.noExpensesYet,
                    style: ExpressType.bodySmall(color: semantic.textSecondary),
                  ),
                )
              else
                ...categories.take(8).map((cat) {
                  final spent = cat.actualAmountPaise;
                  final est = cat.estimatedAmountPaise;
                  final ratio = est > 0 ? (spent / est).clamp(0.0, 1.0) : 0.0;
                  final over = est > 0 && spent > est;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                cat.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ExpressType.labelLarge(
                                  color: semantic.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              est > 0
                                  ? '${CurrencyUtils.formatPaise(spent)} / ${CurrencyUtils.formatPaise(est)}'
                                  : CurrencyUtils.formatPaise(spent),
                              style: ExpressType.labelMedium(
                                color: over ? semantic.diya : semantic.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: semantic.cardSubtleBg,
                            color: over ? semantic.diya : semantic.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final List<EventBudgetCategory> categories;
  final List<BudgetExpense> expenses;
  final List<Event> events;
  final Map<String, String> eventNamesById;
  final String? selectedEventId;
  final VoidCallback onAddPresets;
  final VoidCallback onAddCustomCategory;
  final ValueChanged<EventBudgetCategory> onEditCategory;
  final ValueChanged<EventBudgetCategory> onAddExpenseForCategory;
  final ValueChanged<BudgetExpense> onTapExpense;

  const _CategoriesTab({
    required this.categories,
    required this.expenses,
    required this.events,
    required this.eventNamesById,
    required this.selectedEventId,
    required this.onAddPresets,
    required this.onAddCustomCategory,
    required this.onEditCategory,
    required this.onAddExpenseForCategory,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final categoryIds = categories.map((c) => c.id).toSet();
    final uncategorized = expenses
        .where((e) => e.categoryId == null || !categoryIds.contains(e.categoryId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: Icon(Icons.auto_fix_high_outlined,
                  size: 16, color: semantic.primary),
              label: Text(l10n.addCategoryPresetsBtn),
              onPressed: onAddPresets,
            ),
            ActionChip(
              avatar: Icon(Icons.add_rounded, size: 17, color: semantic.mila),
              label: Text(l10n.addNewCategoryBtn),
              onPressed: onAddCustomCategory,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty && uncategorized.isEmpty)
          _EmptyStateBox(
            icon: Icons.category_outlined,
            message: l10n.noExpensesYet,
          )
        else ...[
          for (final cat in categories) ...[
            _CategoryCard(
              category: cat,
              eventLabel: selectedEventId == null ? eventNamesById[cat.eventId] : null,
              expenses:
                  expenses.where((e) => e.categoryId == cat.id).toList(),
              onEdit: () => onEditCategory(cat),
              onAddExpense: () => onAddExpenseForCategory(cat),
              onTapExpense: onTapExpense,
            ),
            const SizedBox(height: 12),
          ],
          if (uncategorized.isNotEmpty) ...[
            ExpressSectionLabel(l10n.unlinkedGeneralLabel),
            ExpressGroup(
              children: [
                for (final exp in uncategorized)
                  _ExpenseListTile(
                    expense: exp,
                    onTap: () => onTapExpense(exp),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final EventBudgetCategory category;
  final String? eventLabel;
  final List<BudgetExpense> expenses;
  final VoidCallback onEdit;
  final VoidCallback onAddExpense;
  final ValueChanged<BudgetExpense> onTapExpense;

  const _CategoryCard({
    required this.category,
    required this.eventLabel,
    required this.expenses,
    required this.onEdit,
    required this.onAddExpense,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final est = category.estimatedAmountPaise;
    final spent = category.actualAmountPaise;
    final over = est > 0 && spent > est;
    final ratio = est > 0 ? (spent / est).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: over ? semantic.diyaBorder : semantic.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExpressBlob(
                size: 36,
                color: (over ? semantic.diya : semantic.primary)
                    .withValues(alpha: 0.14),
                shape: ExpressShape.cookie,
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: over ? semantic.diya : semantic.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.categoryName,
                      style: ExpressType.titleMedium(color: semantic.textPrimary),
                    ),
                    if (eventLabel != null)
                      Text(
                        eventLabel!,
                        style: ExpressType.labelSmall(
                          color: semantic.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: semantic.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onAddExpense,
                icon: Icon(Icons.add_circle_outline_rounded,
                    size: 20, color: semantic.primary),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (est > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: semantic.cardSubtleBg,
                color: over ? semantic.diya : semantic.mila,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '${l10n.plannedBudgetLabel}: ${CurrencyUtils.formatPaise(est)}',
                style: ExpressType.labelSmall(color: semantic.textSecondary),
              ),
              Text(
                '${l10n.totalPaidOutLabel}: ${CurrencyUtils.formatPaise(spent)}',
                style: ExpressType.labelSmall(
                  color: over ? semantic.diya : semantic.mila,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (expenses.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpressGroup(
              children: [
                for (final exp in expenses)
                  _ExpenseListTile(
                    expense: exp,
                    onTap: () => onTapExpense(exp),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  final BudgetExpense expense;
  final VoidCallback onTap;

  const _ExpenseListTile({
    required this.expense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final pending = expense.remainingPaise;

    return ExpressTile(
      dense: true,
      icon: expense.paymentMode == 'upi'
          ? Icons.qr_code_2_rounded
          : Icons.payments_outlined,
      tint: pending > 0 ? semantic.warning : semantic.mila,
      title: '${expense.vendorName} • ${expense.title}',
      subtitle: [
        AppDateUtils.formatLocalizedDate(
          expense.expenseDate,
          l10n.locale.languageCode,
        ),
        if (expense.upiApp != null) expense.upiApp!,
        if (expense.billPhotoPath?.isNotEmpty ?? false) l10n.billAttachedBadge,
      ].join(' • '),
      value: pending > 0
          ? '${CurrencyUtils.formatPaise(expense.paidAmountPaise)} (${CurrencyUtils.formatPaise(pending)})'
          : CurrencyUtils.formatPaise(expense.paidAmountPaise),
      onTap: onTap,
    );
  }
}

class _PayeesTab extends StatelessWidget {
  final List<VendorBudgetSummary> vendorSummaries;
  final int filterMode;
  final ValueChanged<int> onFilterChanged;
  final ValueChanged<BudgetExpense> onAddInstallment;
  final ValueChanged<BudgetExpense> onTapExpense;
  final ValueChanged<VendorBudgetSummary> onAddNewForVendor;

  const _PayeesTab({
    required this.vendorSummaries,
    required this.filterMode,
    required this.onFilterChanged,
    required this.onAddInstallment,
    required this.onTapExpense,
    required this.onAddNewForVendor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final filtered = switch (filterMode) {
      1 => vendorSummaries.where((v) => !v.isSettled).toList(),
      2 => vendorSummaries.where((v) => v.isSettled).toList(),
      _ => vendorSummaries,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TriFilterRow(
          selected: filterMode,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyStateBox(
            icon: Icons.storefront_outlined,
            message: l10n.noExpensesYet,
          )
        else
          for (final vendor in filtered) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: semantic.cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: vendor.isSettled
                      ? semantic.cardBorder
                      : semantic.warning.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExpressBlob(
                        size: 40,
                        color: (vendor.isSettled ? semantic.mila : semantic.warning)
                            .withValues(alpha: 0.14),
                        shape: ExpressShape.cookie,
                        child: Text(
                          vendor.vendorName.isNotEmpty
                              ? vendor.vendorName.characters.first.toUpperCase()
                              : '?',
                          style: ExpressType.titleMedium(
                            color: vendor.isSettled
                                ? semantic.mila
                                : semantic.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.vendorName,
                              style: ExpressType.titleMedium(
                                color: semantic.textPrimary,
                              ),
                            ),
                            Text(
                              vendor.isSettled
                                  ? l10n.settledBadgeLabel
                                  : '${l10n.balanceRemainingLabel}: ${CurrencyUtils.formatPaise(vendor.totalPendingPaise)}',
                              style: ExpressType.labelSmall(
                                color: vendor.isSettled
                                    ? semantic.mila
                                    : semantic.diya,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (vendor.vendorPhone != null &&
                          vendor.vendorPhone!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.call_outlined,
                              size: 18, color: semantic.primary),
                          onPressed: () =>
                              launchPhoneCall(context, vendor.vendorPhone!),
                        ),
                      TextButton.icon(
                        onPressed: () => vendor.expenses.isNotEmpty
                            ? onAddInstallment(vendor.expenses.firstWhere(
                                (e) => !e.isSettled,
                                orElse: () => vendor.expenses.first,
                              ))
                            : onAddNewForVendor(vendor),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(l10n.addInstallmentLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStat(
                        label: l10n.agreedDealLabel,
                        value: CurrencyUtils.formatPaise(vendor.totalAgreedPaise),
                        color: semantic.textPrimary,
                      ),
                      _MiniStat(
                        label: l10n.totalPaidOutLabel,
                        value: CurrencyUtils.formatPaise(vendor.totalPaidPaise),
                        color: semantic.mila,
                      ),
                      _MiniStat(
                        label: l10n.balanceRemainingLabel,
                        value:
                            CurrencyUtils.formatPaise(vendor.totalPendingPaise),
                        color: vendor.totalPendingPaise > 0
                            ? semantic.diya
                            : semantic.mila,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExpressGroup(
                    children: [
                      for (final exp in vendor.expenses)
                        _ExpenseListTile(
                          expense: exp,
                          onTap: () => onTapExpense(exp),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _BorrowedFundsTab extends StatelessWidget {
  final BudgetOverviewStats stats;
  final List<FundArrangement> arrangements;
  final Map<String, String> eventNamesById;
  final int filterMode;
  final ValueChanged<int> onFilterChanged;
  final ValueChanged<FundArrangement> onRecordReturn;
  final ValueChanged<FundArrangement> onTapArrangement;

  const _BorrowedFundsTab({
    required this.stats,
    required this.arrangements,
    required this.eventNamesById,
    required this.filterMode,
    required this.onFilterChanged,
    required this.onRecordReturn,
    required this.onTapArrangement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final filtered = switch (filterMode) {
      1 => arrangements.where((a) => !a.effectiveIsSettled).toList(),
      2 => arrangements.where((a) => a.effectiveIsSettled).toList(),
      _ => arrangements,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Row(
            children: [
              _MiniStat(
                label: l10n.takenAmountLabel,
                value: CurrencyUtils.formatPaise(stats.totalBorrowedPaise),
                color: semantic.textPrimary,
              ),
              _MiniStat(
                label: l10n.returnedAmountLabel,
                value: CurrencyUtils.formatPaise(stats.totalReturnedPaise),
                color: semantic.mila,
              ),
              _MiniStat(
                label: l10n.returnRemainingLabel,
                value: CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                color: stats.totalBorrowRemainingPaise > 0
                    ? semantic.diya
                    : semantic.mila,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TriFilterRow(selected: filterMode, onChanged: onFilterChanged),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _EmptyStateBox(
            icon: Icons.handshake_outlined,
            message: l10n.noArrangementsYet,
          )
        else
          for (final arr in filtered) ...[
            ExpressSquish(
              onTap: () => onTapArrangement(arr),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: arr.effectiveIsSettled
                        ? semantic.cardBorder
                        : semantic.diyaBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ExpressBlob(
                          size: 40,
                          color: (arr.effectiveIsSettled
                                  ? semantic.mila
                                  : semantic.diya)
                              .withValues(alpha: 0.14),
                          shape: ExpressShape.cookie,
                          child: Text(
                            arr.lenderName.isNotEmpty
                                ? arr.lenderName.characters.first.toUpperCase()
                                : '?',
                            style: ExpressType.titleMedium(
                              color: arr.effectiveIsSettled
                                  ? semantic.mila
                                  : semantic.diya,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                arr.lenderName,
                                style: ExpressType.titleMedium(
                                  color: semantic.textPrimary,
                                ),
                              ),
                              Text(
                                [
                                  if (arr.eventId != null &&
                                      eventNamesById.containsKey(arr.eventId))
                                    eventNamesById[arr.eventId!]!,
                                  AppDateUtils.formatLocalizedDate(
                                    arr.takenDate,
                                    l10n.locale.languageCode,
                                  ),
                                ].join(' • '),
                                style: ExpressType.bodySmall(
                                  color: semantic.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (arr.lenderPhone?.isNotEmpty ?? false)
                          IconButton(
                            icon: Icon(Icons.call_outlined,
                                size: 18, color: semantic.primary),
                            onPressed: () =>
                                launchPhoneCall(context, arr.lenderPhone!),
                          ),
                        if (!arr.effectiveIsSettled)
                          FilledButton.tonalIcon(
                            onPressed: () => onRecordReturn(arr),
                            icon: const Icon(Icons.reply_rounded, size: 16),
                            label: Text(l10n.recordReturnBtn),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: semantic.milaContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.settledBadgeLabel,
                              style: ExpressType.labelSmall(color: semantic.mila),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: arr.progressRatio,
                        minHeight: 5,
                        backgroundColor: semantic.cardSubtleBg,
                        color: arr.effectiveIsSettled
                            ? semantic.mila
                            : semantic.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${l10n.takenAmountLabel}: ${CurrencyUtils.formatPaise(arr.totalReturnablePaise)}',
                          style: ExpressType.labelSmall(
                            color: semantic.textSecondary,
                          ),
                        ),
                        Text(
                          '${l10n.returnedAmountLabel}: ${CurrencyUtils.formatPaise(arr.returnedPaise)}',
                          style: ExpressType.labelSmall(color: semantic.mila),
                        ),
                        Text(
                          '${l10n.returnRemainingLabel}: ${CurrencyUtils.formatPaise(arr.remainingPaise)}',
                          style: ExpressType.labelSmall(
                            color: arr.effectiveIsSettled
                                ? semantic.mila
                                : semantic.diya,
                            weight: FontWeight.w800,
                          ),
                        ),
                        if (arr.returnTargetDate?.isNotEmpty ?? false)
                          Text(
                            '${l10n.returnTargetDateLabel}: ${AppDateUtils.formatLocalizedDate(arr.returnTargetDate, l10n.locale.languageCode)}',
                            style: ExpressType.labelSmall(
                              color: semantic.warning,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }
}

class _TriFilterRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TriFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [l10n.all, l10n.filterActiveOnly, l10n.filterSettledOnly];
    return Wrap(
      spacing: 8,
      children: [
        for (var i = 0; i < items.length; i++)
          ChoiceChip(
            label: Text(items[i]),
            selected: selected == i,
            onSelected: (_) => onChanged(i),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExpressType.labelSmall(color: semantic.textSecondary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: ExpressType.titleSmall(color: color, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: semantic.cardBorder),
      ),
      child: Column(
        children: [
          ExpressBlob(
            size: 52,
            color: semantic.primary.withValues(alpha: 0.12),
            shape: ExpressShape.cookie,
            child: Icon(icon, size: 24, color: semantic.primary),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ExpressType.bodyMedium(color: semantic.textSecondary),
          ),
        ],
      ),
    );
  }
}
