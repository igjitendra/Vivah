import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../data/vyavahaar_stats.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import 'widgets/express_stat_widgets.dart';
import 'widgets/report_charts.dart';
import 'widgets/share_report_card.dart';

/// Streak-inspired Advanced Reports & Visual Analytics Hub for व्यवहार (Vyavahaar).
/// Derives 100% of surfaces and chart colors from [AppSemanticColors] and [ThemeData].
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _tab = 0;
  int? _selectedYear = DateTime.now().year;
  ReportScopeFilter _scope = ReportScopeFilter.all;
  String? _selectedEventId;
  ReportHeroPeriod _heroPeriod = ReportHeroPeriod.selectedYear;
  bool _heroShowCashRatio = false;
  bool _donutByMode = false;
  bool _isGeneratingExport = false;

  String _periodTitle(AppLocalizations l10n) {
    final yearText = _selectedYear == null ? l10n.allYearsLabel : '$_selectedYear';
    final scopeText = switch (_scope) {
      ReportScopeFilter.all => l10n.all,
      ReportScopeFilter.milaOnly => l10n.received,
      ReportScopeFilter.diyaOnly => l10n.given,
      ReportScopeFilter.cashOnly => l10n.cashOnlyFilter,
      ReportScopeFilter.giftsOnly => l10n.giftsOnlyFilter,
    };
    return '$yearText • $scopeText';
  }

  String _heroPeriodLabel(AppLocalizations l10n, ReportHeroPeriod p) {
    return switch (p) {
      ReportHeroPeriod.thisMonth => l10n.heroPeriodMonth,
      ReportHeroPeriod.quarter => l10n.heroPeriodQuarter,
      ReportHeroPeriod.selectedYear => _selectedYear == null ? l10n.allYearsLabel : '$_selectedYear',
      ReportHeroPeriod.allTime => l10n.heroPeriodAll,
    };
  }

  Future<void> _pickHeroPeriod(AppLocalizations l10n, AppSemanticColors semantic) async {
    final chosen = await showModalBottomSheet<ReportHeroPeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: semantic.cardBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: semantic.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (final p in ReportHeroPeriod.values)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(
                  p == _heroPeriod ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: p == _heroPeriod ? semantic.primary : semantic.textSecondary,
                ),
                title: Text(
                  _heroPeriodLabel(l10n, p),
                  style: TextStyle(
                    fontWeight: p == _heroPeriod ? FontWeight.w800 : FontWeight.w600,
                    color: semantic.textPrimary,
                  ),
                ),
                onTap: () => Navigator.of(ctx).pop(p),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _heroPeriod = chosen);
    }
  }

  Future<void> _pickEventFilter(
    List<Event> events,
    AppLocalizations l10n,
    AppSemanticColors semantic,
  ) async {
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: semantic.cardBorder)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: semantic.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.tabEvents,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: semantic.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: Icon(Icons.layers_outlined, color: semantic.primary),
                      title: Text(
                        l10n.allEventsLabel,
                        style: TextStyle(
                          fontWeight: _selectedEventId == null ? FontWeight.w800 : FontWeight.w600,
                          color: semantic.textPrimary,
                        ),
                      ),
                      trailing: _selectedEventId == null
                          ? Icon(Icons.check_circle, color: semantic.primary)
                          : null,
                      onTap: () => Navigator.of(sheetCtx).pop('__ALL__'),
                    ),
                    for (final ev in events)
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Icon(Icons.event_outlined, color: semantic.secondary),
                        title: Text(
                          ev.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: _selectedEventId == ev.id ? FontWeight.w800 : FontWeight.w600,
                            color: semantic.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          AppDateUtils.formatLocalizedDate(ev.eventDate, l10n.locale.languageCode),
                          style: TextStyle(fontSize: 11.5, color: semantic.textSecondary),
                        ),
                        trailing: _selectedEventId == ev.id
                            ? Icon(Icons.check_circle, color: semantic.primary)
                            : null,
                        onTap: () => Navigator.of(sheetCtx).pop(ev.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() {
      _selectedEventId = chosen == '__ALL__' ? null : chosen;
    });
  }

  Future<void> _runExportTask(Future<void> Function() task) async {
    if (_isGeneratingExport) return;
    setState(() => _isGeneratingExport = true);
    try {
      await task();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingExport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final wide = isWideLayout(context);

    final entriesAsync = ref.watch(entriesListProvider(null));
    final eventsAsync = ref.watch(activeEventsListProvider);
    final familyProfile = ref.watch(familyProfileProvider).value ?? const FamilyProfile();

    final events = eventsAsync.value ?? const <Event>[];
    if (_selectedEventId != null && !events.any((e) => e.id == _selectedEventId)) {
      _selectedEventId = null;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.insightsTitle,
          style: TextStyle(
            color: semantic.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: semantic.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: semantic.textPrimary),
        actions: [
          if (_tab != 2)
            IconButton(
              tooltip: l10n.reportTabExports,
              icon: Icon(Icons.ios_share_rounded, color: semantic.primary),
              onPressed: () => setState(() => _tab = 2),
            ),
        ],
      ),
      body: _isGeneratingExport
          ? Center(child: CircularProgressIndicator(color: semantic.primary))
          : entriesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: semantic.primary)),
              error: (err, _) => Center(
                child: Text(
                  '${l10n.errorGeneric}: $err',
                  style: TextStyle(color: semantic.diya),
                ),
              ),
              data: (entries) {
                final stats = VyavahaarStats.compute(
                  allEntries: entries,
                  events: events,
                  scope: _scope,
                  selectedYear: _selectedYear,
                  selectedEventId: _selectedEventId,
                  heroPeriod: _heroPeriod,
                );

                final selectedEventObj = _selectedEventId != null
                    ? events.where((e) => e.id == _selectedEventId).firstOrNull
                    : null;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1040 : 720),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl * 2,
                      ),
                      children: [
                        // 1. Streak-style Animated Pill Tab Switcher
                        ExpressPillTabs(
                          labels: [
                            l10n.reportTabOverview,
                            l10n.reportTabAnalytics,
                            l10n.reportTabExports,
                          ],
                          index: _tab,
                          onChanged: (idx) => setState(() => _tab = idx),
                        ),
                        const SizedBox(height: 14),

                        // 2. Scope & Event Chip Bar
                        _buildScopeChipBar(
                          l10n: l10n,
                          semantic: semantic,
                          events: events,
                          selectedEvent: selectedEventObj,
                        ),
                        const SizedBox(height: 12),

                        // 3. Year Navigator Bar
                        ExpressYearNavigator(
                          selectedYear: _selectedYear,
                          fallbackYear: DateTime.now().year,
                          canGoForward: (_selectedYear ?? DateTime.now().year) < DateTime.now().year,
                          allYearsLabel: l10n.allYearsLabel,
                          onSelectYear: (yr) => setState(() => _selectedYear = yr),
                        ),
                        const SizedBox(height: 18),

                        // 4. Tab Content with AnimatedSwitcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeOutCubic,
                          child: KeyedSubtree(
                            key: ValueKey('tab-$_tab-$_selectedYear-${_scope.name}-$_selectedEventId'),
                            child: switch (_tab) {
                              0 => _buildOverviewTab(
                                  context: context,
                                  stats: stats,
                                  l10n: l10n,
                                  semantic: semantic,
                                ),
                              1 => _buildAnalyticsTab(
                                  context: context,
                                  stats: stats,
                                  l10n: l10n,
                                  semantic: semantic,
                                ),
                              _ => _buildExportsTab(
                                  context: context,
                                  stats: stats,
                                  familyProfile: familyProfile,
                                  l10n: l10n,
                                  semantic: semantic,
                                  selectedEvent: selectedEventObj,
                                ),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildScopeChipBar({
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
    required List<Event> events,
    required Event? selectedEvent,
  }) {
    final chips = [
      (filter: ReportScopeFilter.all, label: l10n.filterAll, tint: semantic.primary),
      (filter: ReportScopeFilter.milaOnly, label: l10n.received, tint: semantic.mila),
      (filter: ReportScopeFilter.diyaOnly, label: l10n.given, tint: semantic.diya),
      (filter: ReportScopeFilter.cashOnly, label: l10n.cashOnlyFilter, tint: semantic.cashAccent),
      (filter: ReportScopeFilter.giftsOnly, label: l10n.giftsOnlyFilter, tint: semantic.giftAccent),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final item in chips) ...[
            InkWell(
              onTap: () => setState(() => _scope = item.filter),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _scope == item.filter
                      ? item.tint.withValues(alpha: 0.16)
                      : semantic.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _scope == item.filter ? item.tint : semantic.cardBorder,
                    width: _scope == item.filter ? 1.4 : 1.0,
                  ),
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _scope == item.filter ? item.tint : semantic.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (events.isNotEmpty)
            InkWell(
              onTap: () => _pickEventFilter(events, l10n, semantic),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedEvent != null
                      ? semantic.secondary.withValues(alpha: 0.16)
                      : semantic.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selectedEvent != null ? semantic.secondary : semantic.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 15,
                      color: selectedEvent != null ? semantic.secondary : semantic.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      selectedEvent != null ? selectedEvent.title : l10n.allEventsLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selectedEvent != null ? semantic.secondary : semantic.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: selectedEvent != null ? semantic.secondary : semantic.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab({
    required BuildContext context,
    required VyavahaarStats stats,
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
  }) {
    final hero = stats.heroMetrics;
    final heroPercent = _heroShowCashRatio ? hero.cashSharePercent : hero.milaSharePercent;
    final heroAccent = _heroShowCashRatio ? semantic.cashAccent : semantic.mila;
    final heroMetricTitle = _heroShowCashRatio ? l10n.cashShareLabel : l10n.milaShareLabel;

    final months = l10n.locale.languageCode == 'en'
        ? AppDateUtils.englishMonths
        : (l10n.locale.languageCode == 'ur' ? AppDateUtils.urduMonths : AppDateUtils.hindiMonths);

    final peakMonthName = stats.totalCount == 0
        ? '-'
        : '${months[stats.bestMonthIndex]} (${CurrencyUtils.formatPaise(stats.bestMonthVolumePaise)})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Streak-style Hero Wave Ring Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: semantic.cardBorder),
            boxShadow: [
              BoxShadow(
                color: semantic.shadow,
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _heroShowCashRatio = !_heroShowCashRatio),
                child: ExpressWaveRing(
                  value: heroPercent / 100.0,
                  color: heroAccent,
                  track: semantic.cardSubtleBg,
                  size: 168,
                  stroke: 16,
                  waves: 10,
                  amplitude: 2.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$heroPercent%',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: semantic.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        heroMetricTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: semantic.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickHeroPeriod(l10n, semantic),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: semantic.cardSubtleBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: semantic.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _heroPeriodLabel(l10n, _heroPeriod),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: semantic.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: semantic.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.tapToSwitchMode,
                style: TextStyle(fontSize: 11, color: semantic.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniPillMetric(
                      label: l10n.received,
                      value: CurrencyUtils.formatPaise(hero.receivedPaise),
                      color: semantic.mila,
                      bg: semantic.milaContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MiniPillMetric(
                      label: l10n.given,
                      value: CurrencyUtils.formatPaise(hero.givenPaise),
                      color: semantic.diya,
                      bg: semantic.diyaContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // B. 2x2 Express KPI Grid
        Row(
          children: [
            Expanded(
              child: ExpressStatTile(
                icon: Icons.arrow_downward_rounded,
                value: CurrencyUtils.formatPaise(stats.totalReceivedPaise),
                label: l10n.totalReceived,
                sublabel: '${stats.receivedCount} ${l10n.items}',
                tint: semantic.mila,
                shape: ExpressBlobShape.cookie,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ExpressStatTile(
                icon: Icons.arrow_upward_rounded,
                value: CurrencyUtils.formatPaise(stats.totalGivenPaise),
                label: l10n.totalGiven,
                sublabel: '${stats.givenCount} ${l10n.items}',
                tint: semantic.diya,
                shape: ExpressBlobShape.gem,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ExpressStatTile(
                icon: Icons.payments_outlined,
                value: CurrencyUtils.formatPaise(stats.cashTotalPaise),
                label: l10n.cash,
                sublabel: '${stats.totalCount} ${l10n.items}',
                tint: semantic.cashAccent,
                shape: ExpressBlobShape.sunny,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ExpressStatTile(
                icon: Icons.card_giftcard_rounded,
                value: stats.estimatedGiftPaise > 0
                    ? CurrencyUtils.formatPaise(stats.estimatedGiftPaise)
                    : '${stats.giftItemCount} ${l10n.itemsCountSuffix}',
                label: l10n.giftsLabel,
                sublabel: '${stats.giftItemCount} ${l10n.itemsCountSuffix}',
                tint: semantic.giftAccent,
                shape: ExpressBlobShape.flower,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // C. Key Highlights Section
        _SectionHeading(title: l10n.keyHighlightsLabel, color: semantic.textSecondary),
        const SizedBox(height: 8),
        ExpressStatRow(
          icon: Icons.calendar_today_rounded,
          label: l10n.activeDaysCountLabel,
          value: '${stats.activeDays}',
          tint: semantic.primary,
          shape: ExpressBlobShape.clover,
        ),
        const SizedBox(height: 8),
        ExpressStatRow(
          icon: Icons.analytics_outlined,
          label: l10n.avgPerEntryLabel,
          value: CurrencyUtils.formatPaise(stats.avgEntryPaise),
          tint: semantic.info,
          shape: ExpressBlobShape.pebble,
        ),
        const SizedBox(height: 8),
        ExpressStatRow(
          icon: Icons.emoji_events_outlined,
          label: l10n.bestMonthStatLabel,
          value: peakMonthName,
          tint: semantic.warning,
          shape: ExpressBlobShape.burst,
        ),
        const SizedBox(height: 8),
        ExpressStatRow(
          icon: Icons.schedule_rounded,
          label: l10n.pendingExpectedLabel,
          value: '${stats.pendingCount} (${CurrencyUtils.formatPaise(stats.pendingPaise)})',
          tint: semantic.secondary,
          shape: ExpressBlobShape.gem,
        ),

        // D. Rankings: Top Relatives (Received & Given) and Top Events
        if (stats.topPeopleReceived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          ExpressStatPanel(
            title: l10n.topPeopleReceivedTitle,
            icon: Icons.workspace_premium_outlined,
            tint: semantic.mila,
            shape: ExpressBlobShape.cookie,
            child: ExpressRankingList(
              items: stats.topPeopleReceived
                  .take(5)
                  .map(
                    (p) => ExpressRankedItem(
                      name: p.name,
                      formattedValue: CurrencyUtils.formatPaise(p.totalPaise),
                      rawScore: p.totalPaise,
                      subtitle: '${p.count} ${l10n.items}',
                      color: semantic.mila,
                      onTap: () => context.push('/person/${p.personId}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],

        if (stats.topPeopleGiven.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ExpressStatPanel(
            title: l10n.topPeopleGivenTitle,
            icon: Icons.volunteer_activism_outlined,
            tint: semantic.diya,
            shape: ExpressBlobShape.gem,
            child: ExpressRankingList(
              items: stats.topPeopleGiven
                  .take(5)
                  .map(
                    (p) => ExpressRankedItem(
                      name: p.name,
                      formattedValue: CurrencyUtils.formatPaise(p.totalPaise),
                      rawScore: p.totalPaise,
                      subtitle: '${p.count} ${l10n.items}',
                      color: semantic.diya,
                      onTap: () => context.push('/person/${p.personId}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],

        if (stats.topEvents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ExpressStatPanel(
            title: l10n.topEventsTitle,
            icon: Icons.celebration_outlined,
            tint: semantic.primary,
            shape: ExpressBlobShape.flower,
            child: ExpressRankingList(
              items: stats.topEvents
                  .take(5)
                  .map(
                    (ev) => ExpressRankedItem(
                      name: ev.eventId == 'general' ? l10n.generalCategory : ev.title,
                      formattedValue: CurrencyUtils.formatPaise(ev.totalVolumePaise),
                      rawScore: ev.totalVolumePaise,
                      subtitle:
                          '${ev.count} ${l10n.items} • ${l10n.received}: ${CurrencyUtils.formatPaise(ev.receivedPaise)} | ${l10n.given}: ${CurrencyUtils.formatPaise(ev.givenPaise)}',
                      color: semantic.primary,
                      onTap: ev.eventId == 'general' ? null : () => context.push('/event/${ev.eventId}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],

        if (stats.totalCount == 0) ...[
          const SizedBox(height: AppSpacing.md),
          _EmptyStatsBanner(message: l10n.noDataForFilter, semantic: semantic),
        ],
      ],
    );
  }

  Widget _buildAnalyticsTab({
    required BuildContext context,
    required VyavahaarStats stats,
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
  }) {
    final localeCode = l10n.locale.languageCode;
    final paletteSliceColors = [
      semantic.primary,
      semantic.mila,
      semantic.diya,
      semantic.info,
      semantic.warning,
      semantic.giftAccent,
      semantic.cashAccent,
      semantic.secondary,
    ];

    final eventDonutSlices = <DonutSliceData>[
      for (int i = 0; i < stats.eventTypeSlices.length; i++)
        DonutSliceData(
          label: stats.eventTypeSlices[i].eventType != null
              ? l10n.eventTypeLabel(stats.eventTypeSlices[i].eventType!)
              : l10n.generalCategory,
          count: stats.eventTypeSlices[i].count,
          volumePaise: stats.eventTypeSlices[i].volumePaise,
          color: paletteSliceColors[i % paletteSliceColors.length],
        ),
    ];

    final modeDonutSlices = <DonutSliceData>[
      if ((stats.modeCounts[TransactionType.cash] ?? 0) > 0)
        DonutSliceData(
          label: l10n.cash,
          count: stats.modeCounts[TransactionType.cash]!,
          volumePaise: stats.cashTotalPaise,
          color: semantic.cashAccent,
        ),
      if ((stats.modeCounts[TransactionType.item] ?? 0) > 0)
        DonutSliceData(
          label: l10n.giftItem,
          count: stats.modeCounts[TransactionType.item]!,
          volumePaise: stats.estimatedGiftPaise,
          color: semantic.giftAccent,
        ),
      if ((stats.modeCounts[TransactionType.cashAndItem] ?? 0) > 0)
        DonutSliceData(
          label: l10n.cashAndItem,
          count: stats.modeCounts[TransactionType.cashAndItem]!,
          volumePaise: 0,
          color: semantic.primary,
        ),
    ];

    final activeSlices = _donutByMode ? modeDonutSlices : eventDonutSlices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Yearly Activity Heatmap
        ExpressStatPanel(
          title: '${l10n.yearlyActivityTitle} (${stats.heatmapYear})',
          icon: Icons.grid_view_rounded,
          tint: semantic.primary,
          shape: ExpressBlobShape.gem,
          child: VyavahaarYearHeatmap(
            year: stats.heatmapYear,
            dailyCounts: stats.dailyCounts,
            dailyVolumePaise: stats.dailyVolumePaise,
            accentColor: semantic.primary,
            localeCode: localeCode,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Monthly Mila vs Diya Trend Line Chart
        ExpressStatPanel(
          title: l10n.monthlyTrendTitle,
          icon: Icons.show_chart_rounded,
          tint: semantic.mila,
          shape: ExpressBlobShape.sunny,
          child: VyavahaarMonthlyTrendChart(
            monthlyReceivedPaise: stats.monthlyReceivedPaise,
            monthlyGivenPaise: stats.monthlyGivenPaise,
            localeCode: localeCode,
            milaLabel: l10n.received,
            diyaLabel: l10n.given,
            showMila: _scope != ReportScopeFilter.diyaOnly,
            showDiya: _scope != ReportScopeFilter.milaOnly,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 3. Interactive Donut Chart (Event Types vs Payment Modes)
        ExpressStatPanel(
          title: l10n.categoryDonutTitle,
          icon: Icons.donut_large_rounded,
          tint: semantic.giftAccent,
          shape: ExpressBlobShape.flower,
          trailing: InkWell(
            onTap: () => setState(() => _donutByMode = !_donutByMode),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: semantic.cardSubtleBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: semantic.cardBorder),
              ),
              child: Text(
                _donutByMode ? l10n.tabEvents : l10n.type,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: semantic.primary,
                ),
              ),
            ),
          ),
          child: activeSlices.isEmpty
              ? _EmptyStatsBanner(message: l10n.noDataForFilter, semantic: semantic)
              : VyavahaarInteractiveDonut(
                  slices: activeSlices,
                  centerTitle: l10n.items,
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Weekday Activity Bars
        ExpressStatPanel(
          title: l10n.weekdayActivityTitle,
          icon: Icons.bar_chart_rounded,
          tint: semantic.info,
          shape: ExpressBlobShape.clover,
          child: VyavahaarWeekdayBars(
            weekdayCounts: stats.weekdayCounts,
            weekdayVolumePaise: stats.weekdayVolumePaise,
            barColor: semantic.info,
            localeCode: localeCode,
          ),
        ),
      ],
    );
  }

  Widget _buildExportsTab({
    required BuildContext context,
    required VyavahaarStats stats,
    required FamilyProfile familyProfile,
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
    required Event? selectedEvent,
  }) {
    final periodTitle = _periodTitle(l10n);
    final filterDesc = selectedEvent != null ? '$periodTitle • ${selectedEvent.title}' : periodTitle;
    final filtered = stats.filteredEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Streak-style Shareable Report Card (PNG Export)
        ExpressStatPanel(
          title: l10n.shareReportCardTitle,
          icon: Icons.style_outlined,
          tint: semantic.primary,
          shape: ExpressBlobShape.cookie,
          child: ShareReportSummaryCard(
            stats: stats,
            familyProfile: familyProfile,
            periodLabel: filterDesc,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 2. Filtered PDF & CSV Exports
        _SectionHeading(title: l10n.reports, color: semantic.textSecondary),
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 2, bottom: 10),
          child: Text(
            l10n.filteredExportsSubtitle,
            style: TextStyle(fontSize: 11.5, color: semantic.textSecondary),
          ),
        ),

        _ExportActionTile(
          title: l10n.completeLedgerPdf,
          subtitle: '$filterDesc (${filtered.length} ${l10n.items})',
          icon: Icons.picture_as_pdf_rounded,
          iconColor: semantic.primary,
          semantic: semantic,
          onTap: () => _runExportTask(() async {
            final file = await PdfService.generateLedgerPdf(
              entries: filtered,
              title: l10n.completeLedgerPdf,
              subtitle: filterDesc,
              l10n: l10n,
            );
            await PdfService.printOrSharePdf(file);
          }),
        ),
        const SizedBox(height: AppSpacing.sm),

        _ExportActionTile(
          title: l10n.receivedOnlyPdf,
          subtitle: '${stats.receivedCount} ${l10n.items} • ${CurrencyUtils.formatPaise(stats.totalReceivedPaise)}',
          icon: Icons.arrow_downward_rounded,
          iconColor: semantic.mila,
          semantic: semantic,
          onTap: () => _runExportTask(() async {
            final recOnly = filtered.where(VyavahaarStats.isReceived).toList();
            final file = await PdfService.generateLedgerPdf(
              entries: recOnly,
              title: l10n.receivedOnlyPdf,
              subtitle: filterDesc,
              l10n: l10n,
            );
            await PdfService.printOrSharePdf(file);
          }),
        ),
        const SizedBox(height: AppSpacing.sm),

        _ExportActionTile(
          title: l10n.givenOnlyPdf,
          subtitle: '${stats.givenCount} ${l10n.items} • ${CurrencyUtils.formatPaise(stats.totalGivenPaise)}',
          icon: Icons.arrow_upward_rounded,
          iconColor: semantic.diya,
          semantic: semantic,
          onTap: () => _runExportTask(() async {
            final givOnly = filtered.where((e) => !VyavahaarStats.isReceived(e)).toList();
            final file = await PdfService.generateLedgerPdf(
              entries: givOnly,
              title: l10n.givenOnlyPdf,
              subtitle: filterDesc,
              l10n: l10n,
            );
            await PdfService.printOrSharePdf(file);
          }),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (stats.topEvents.isNotEmpty) ...[
          _ExportActionTile(
            title: l10n.eventWisePdfLabel,
            subtitle: '${stats.topEvents.length} ${l10n.tabEvents}',
            icon: Icons.celebration_outlined,
            iconColor: semantic.warning,
            semantic: semantic,
            onTap: () => _runExportTask(() async {
              final rows = stats.topEvents
                  .map((ev) => (
                        title: ev.eventId == 'general' ? l10n.generalCategory : ev.title,
                        count: ev.count,
                        receivedPaise: ev.receivedPaise,
                        givenPaise: ev.givenPaise,
                      ))
                  .toList();
              final file = await PdfService.generateEventSummaryPdf(
                rows: rows,
                title: l10n.eventWisePdfLabel,
                subtitle: filterDesc,
                l10n: l10n,
              );
              await PdfService.printOrSharePdf(file);
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        _ExportActionTile(
          title: l10n.csvExport,
          subtitle: '$filterDesc • UTF-8 Excel CSV',
          icon: Icons.table_chart_outlined,
          iconColor: semantic.info,
          semantic: semantic,
          onTap: () => _runExportTask(() async {
            final file = await CsvService.exportEntriesCsv(filtered, l10n: l10n);
            await CsvService.shareCsv(file, shareText: '${l10n.csvExport} ($filterDesc)');
          }),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeading({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MiniPillMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _MiniPillMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _ExportActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: semantic.cardBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Row(
            children: [
              ExpressBlob(
                size: 40,
                color: iconColor.withValues(alpha: 0.16),
                shape: ExpressBlobShape.cookie,
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: semantic.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: semantic.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.share_outlined, size: 19, color: semantic.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStatsBanner extends StatelessWidget {
  final String message;
  final AppSemanticColors semantic;

  const _EmptyStatsBanner({required this.message, required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: semantic.cardSubtleBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 32, color: semantic.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
