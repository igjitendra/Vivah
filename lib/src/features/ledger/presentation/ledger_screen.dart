import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/empty_detail_pane.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../entries/presentation/entry_detail_screen.dart';

/// Modern Material 3 Ledger (बही) Screen with Advanced Filters
/// Fully theme-adaptive with search pill, direction segment filters, and tactile cards.
class LedgerScreen extends ConsumerStatefulWidget {
  final VoidCallback onNewEntry;
  final ValueChanged<String>? onOpenEntryDetail;

  const LedgerScreen({
    super.key,
    required this.onNewEntry,
    this.onOpenEntryDetail,
  });

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  TransactionDirection? _selectedDirection;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedEntryId;

  // Advanced Filters
  String? _filterEventId;
  TransactionType? _filterType;
  TransactionStatus? _filterStatus;
  int _sortBy = 0; // 0: Newest First, 1: Oldest First, 2: Amount High-Low, 3: Amount Low-High

  int get _activeFiltersCount {
    int count = 0;
    if (_filterEventId != null) count++;
    if (_filterType != null) count++;
    if (_filterStatus != null) count++;
    if (_sortBy != 0) count++;
    return count;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context, AppLocalizations l10n) {
    final eventsAsync = ref.read(activeEventsListProvider);

    String? tempEventId = _filterEventId;
    TransactionType? tempType = _filterType;
    TransactionStatus? tempStatus = _filterStatus;
    int tempSortBy = _sortBy;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.advancedFilters,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // 1. Event Filter
                Text(l10n.filterByEvent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                eventsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (events) => DropdownButtonFormField<String?>(
                    value: tempEventId,
                    hint: Text(l10n.all),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      ...events.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.title} (${e.eventDate})'))),
                    ],
                    onChanged: (val) => setSheetState(() => tempEventId = val),
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Type Filter (Cash / Item / Both)
                Text(l10n.filterByType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: tempType == null,
                      onSelected: (val) => setSheetState(() => tempType = null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.cash),
                      selected: tempType == TransactionType.cash,
                      onSelected: (val) => setSheetState(() => tempType = val ? TransactionType.cash : null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.giftItem),
                      selected: tempType == TransactionType.item,
                      onSelected: (val) => setSheetState(() => tempType = val ? TransactionType.item : null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.cashAndItem),
                      selected: tempType == TransactionType.cashAndItem,
                      onSelected: (val) => setSheetState(() => tempType = val ? TransactionType.cashAndItem : null),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Status Filter (Recorded vs Planned)
                Text(l10n.filterByStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.all),
                      selected: tempStatus == null,
                      onSelected: (val) => setSheetState(() => tempStatus = null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.statusRecorded),
                      selected: tempStatus == TransactionStatus.recorded,
                      onSelected: (val) => setSheetState(() => tempStatus = val ? TransactionStatus.recorded : null),
                    ),
                    ChoiceChip(
                      label: Text(l10n.statusPlanned),
                      selected: tempStatus == TransactionStatus.planned,
                      onSelected: (val) => setSheetState(() => tempStatus = val ? TransactionStatus.planned : null),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Sort By
                Text(l10n.sortBy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.newestFirst),
                      selected: tempSortBy == 0,
                      onSelected: (val) => setSheetState(() => tempSortBy = 0),
                    ),
                    ChoiceChip(
                      label: Text(l10n.oldestFirst),
                      selected: tempSortBy == 1,
                      onSelected: (val) => setSheetState(() => tempSortBy = 1),
                    ),
                    ChoiceChip(
                      label: Text(l10n.amountHighToLow),
                      selected: tempSortBy == 2,
                      onSelected: (val) => setSheetState(() => tempSortBy = 2),
                    ),
                    ChoiceChip(
                      label: Text(l10n.amountLowToHigh),
                      selected: tempSortBy == 3,
                      onSelected: (val) => setSheetState(() => tempSortBy = 3),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            tempEventId = null;
                            tempType = null;
                            tempStatus = null;
                            tempSortBy = 0;
                          });
                        },
                        child: Text(l10n.clearFilters),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                        onPressed: () {
                          setState(() {
                            _filterEventId = tempEventId;
                            _filterType = tempType;
                            _filterStatus = tempStatus;
                            _sortBy = tempSortBy;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.applyFilters, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final entriesAsync = ref.watch(entriesListProvider(_selectedDirection));
    final eventsAsync = ref.watch(activeEventsListProvider);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final primaryAccent = theme.colorScheme.primary;
    final wide = isWideLayout(context);

    final masterList = Column(
        children: [
          // Filter Chips & Search Bar Header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                // 1. Search Bar with Advanced Filter Icon Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cardBorder),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: TextStyle(fontSize: 14, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.searchLedgerHint,
                            hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                            prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: textSecondary, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _activeFiltersCount > 0 ? primaryAccent.withValues(alpha: 0.15) : searchBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _activeFiltersCount > 0 ? primaryAccent : cardBorder),
                      ),
                      child: IconButton(
                        icon: Badge(
                          isLabelVisible: _activeFiltersCount > 0,
                          label: Text('$_activeFiltersCount', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: primaryAccent,
                          child: Icon(
                            Icons.tune_rounded,
                            color: _activeFiltersCount > 0 ? primaryAccent : textSecondary,
                            size: 20,
                          ),
                        ),
                        onPressed: () => _showFilterSheet(context, l10n),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 2. Filter Segment Chips Row (All / Mila / Diya)
                Row(
                  children: [
                    _buildFilterChip(
                      label: l10n.all,
                      isSelected: _selectedDirection == null,
                      onTap: () => setState(() => _selectedDirection = null),
                      icon: Icons.filter_list,
                      activeColor: isDark ? const Color(0xFF38BDF8) : headerBg,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.received,
                      isSelected: _selectedDirection == TransactionDirection.received,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.received),
                      icon: Icons.arrow_downward,
                      activeColor: AppColors.milaGreen,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.given,
                      isSelected: _selectedDirection == TransactionDirection.given,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.given),
                      icon: Icons.arrow_upward,
                      activeColor: AppColors.diyaRed,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),

                // 3. Active Filters Pill Row
                if (_activeFiltersCount > 0) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_filterEventId != null) ...[
                          Chip(
                            label: Text(
                              eventsAsync.value?.firstWhere((e) => e.id == _filterEventId, orElse: () => Event(id: '', title: l10n.tabEvents, eventType: EventType.other, eventDate: '', createdAt: DateTime.now(), updatedAt: DateTime.now())).title ?? l10n.tabEvents,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _filterEventId = null),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (_filterType != null) ...[
                          Chip(
                            label: Text(
                              _filterType == TransactionType.cash
                                  ? l10n.cash
                                  : (_filterType == TransactionType.item ? l10n.giftItem : l10n.cashAndItem),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _filterType = null),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (_filterStatus != null) ...[
                          Chip(
                            label: Text(
                              _filterStatus == TransactionStatus.recorded ? l10n.statusRecorded : l10n.statusPlanned,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _filterStatus = null),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (_sortBy != 0) ...[
                          Chip(
                            label: Text(
                              _sortBy == 1
                                  ? l10n.oldestFirst
                                  : (_sortBy == 2 ? l10n.amountHighToLow : l10n.amountLowToHigh),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _sortBy = 0),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                        ],
                        ActionChip(
                          label: Text(l10n.clearFilters, style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _filterEventId = null;
                              _filterType = null;
                              _filterStatus = null;
                              _sortBy = 0;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Transactions List View
          Expanded(
            child: entriesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '${l10n.errorGeneric}: $err',
                    style: const TextStyle(color: AppColors.diyaRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (entries) {
                // Apply Search & Advanced Filters
                var filtered = entries.where((e) {
                  if (_searchQuery.isNotEmpty) {
                    final name = e.personName?.toLowerCase() ?? '';
                    final village = e.personAddress?.toLowerCase() ?? '';
                    final event = e.eventTitle?.toLowerCase() ?? '';
                    final notes = e.notes?.toLowerCase() ?? '';
                    final matchesSearch = name.contains(_searchQuery) ||
                        village.contains(_searchQuery) ||
                        event.contains(_searchQuery) ||
                        notes.contains(_searchQuery);
                    if (!matchesSearch) return false;
                  }

                  if (_filterEventId != null && e.eventId != _filterEventId) {
                    return false;
                  }

                  if (_filterType != null && e.transactionType != _filterType) {
                    return false;
                  }

                  if (_filterStatus != null && e.status != _filterStatus) {
                    return false;
                  }

                  return true;
                }).toList();

                // Apply Sorting
                switch (_sortBy) {
                  case 1:
                    filtered.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
                    break;
                  case 2:
                    filtered.sort((a, b) => (b.amountPaise ?? 0).compareTo(a.amountPaise ?? 0));
                    break;
                  case 3:
                    filtered.sort((a, b) => (a.amountPaise ?? 0).compareTo(b.amountPaise ?? 0));
                    break;
                  case 0:
                  default:
                    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
                    break;
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBorder),
                            ),
                            child: Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _activeFiltersCount > 0 ? l10n.noResultsFound : l10n.noEntriesYet,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty || _activeFiltersCount > 0 ? l10n.tryDifferentSearch : l10n.recordFirstTransaction,
                            style: TextStyle(fontSize: 13, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty && _activeFiltersCount == 0) ...[
                            const SizedBox(height: 16),
                            ExpressSquish(
                              scale: 0.95,
                              onTap: widget.onNewEntry,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: primaryAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  l10n.newTransaction,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: wide ? AppSpacing.md : AppSpacing.floatingTabBottomPadding + 20,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TransactionCard(
                        entry: entry,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        searchBg: searchBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                        l10n: l10n,
                        isSelected: wide && _selectedEntryId == entry.id,
                        onTap: () {
                          if (wide) {
                            setState(() => _selectedEntryId = entry.id);
                          } else {
                            widget.onOpenEntryDetail?.call(entry.id);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.ledgerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: headerBg,
        elevation: 0,
      ),
      floatingActionButton: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: ExpressSquish(
                scale: 0.94,
                onTap: widget.onNewEntry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: primaryAccent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_card, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.newTransaction,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 440,
                  child: masterList,
                ),
                VerticalDivider(width: 1, thickness: 1, color: cardBorder),
                Expanded(
                  child: _selectedEntryId != null
                      ? EntryDetailScreen(
                          key: ValueKey(_selectedEntryId),
                          entryId: _selectedEntryId!,
                          showBackButton: false,
                          onClose: () => setState(() => _selectedEntryId = null),
                        )
                      : EmptyDetailPane(
                          title: l10n.selectEntryToViewDetails,
                          icon: Icons.receipt_long_outlined,
                          actionLabel: l10n.newTransaction,
                          onAction: widget.onNewEntry,
                        ),
                ),
              ],
            )
          : masterList,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color activeColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: ExpressSquish(
        scale: 0.96,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : cardBorder,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : textPrimary,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionEntry entry;
  final Color cardBg;
  final Color cardBorder;
  final Color searchBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final AppLocalizations l10n;
  final bool isSelected;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.entry,
    required this.cardBg,
    required this.cardBorder,
    required this.searchBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.l10n,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReceived = entry.direction == TransactionDirection.received || entry.direction == TransactionDirection.mila;
    final themeColor = isReceived ? AppColors.milaGreen : AppColors.diyaRed;
    final personName = entry.personName ?? l10n.unknownPerson;

    return ExpressCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: 16,
      color: isSelected ? themeColor.withValues(alpha: isDark ? 0.15 : 0.08) : cardBg,
      borderColor: isSelected ? themeColor : cardBorder,
      borderWidth: isSelected ? 2.0 : 1.0,
      elevation: isSelected ? 2 : 0,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Direction Indicator Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isReceived ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: themeColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // Person and Detail Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.personRelationship ?? l10n.relativeDefault}${entry.personAddress != null && entry.personAddress!.isNotEmpty ? ' • ${entry.personAddress}' : ''}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (entry.eventTitle != null && entry.eventTitle!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: searchBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration_outlined, size: 10, color: themeColor),
                              const SizedBox(width: 3),
                              Text(
                                entry.eventTitle!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        VyavahaarDateUtils.formatIsoDate(entry.transactionDate, l10n.locale.languageCode),
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount & Items Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.amountPaise != null
                      ? CurrencyUtils.formatPaise(entry.amountPaise!)
                      : l10n.giftItem,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: themeColor,
                    letterSpacing: -0.3,
                  ),
                ),
                if (entry.items.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard, size: 11, color: textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${entry.items.length}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
                if (entry.isPlanned) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B2912) : AppColors.plannedAmberSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.statusPlanned,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.plannedAmber),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
