import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/empty_detail_pane.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import 'event_detail_screen.dart';

enum EventViewMode { list, calendar }
enum EventScopeFilter { all, ownFamily, relative }
enum EventFilter { all, upcoming, today, completed, draft, archived }
enum EventSort { dateAsc, dateDesc, titleAsc, priority }

/// Advanced Material 3 Screen listing celebratory family events (विवाह, मुंडन, आदि)
/// Supports Filter Chips, Month Calendar View, Sorting, Search, and Master-Detail responsive layout.
class EventsListScreen extends ConsumerStatefulWidget {
  final VoidCallback onNewEvent;
  final ValueChanged<String>? onOpenEventDetail;
  final VoidCallback? onScanEventQr;

  const EventsListScreen({
    super.key,
    required this.onNewEvent,
    this.onOpenEventDetail,
    this.onScanEventQr,
  });

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedEventId;

  EventViewMode _viewMode = EventViewMode.list;
  EventScopeFilter _scopeFilter = EventScopeFilter.all;
  EventFilter _activeFilter = EventFilter.all;
  EventSort _activeSort = EventSort.dateAsc;

  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);

    // Watch appropriate stream based on archived filter
    final eventsAsync = _activeFilter == EventFilter.archived
        ? ref.watch(archivedEventsListProvider)
        : ref.watch(activeEventsListProvider);
    final entriesAsync = ref.watch(entriesListProvider(null));

    // Single-pass live aggregation per event from recorded transactions
    final Map<String, ({int totalMila, int totalDiya, int count})> eventStats = {};
    if (entriesAsync.hasValue) {
      for (final entry in entriesAsync.value!) {
        if (entry.archivedAt != null || entry.status != TransactionStatus.recorded) continue;
        final evId = entry.eventId;
        if (evId == null || evId.isEmpty) continue;
        final prev = eventStats[evId] ?? (totalMila: 0, totalDiya: 0, count: 0);
        final isReceived = entry.direction == TransactionDirection.received ||
            entry.direction == TransactionDirection.mila;
        final amount = entry.amountPaise ?? 0;
        eventStats[evId] = (
          totalMila: prev.totalMila + (isReceived ? amount : 0),
          totalDiya: prev.totalDiya + (!isReceived ? amount : 0),
          count: prev.count + 1,
        );
      }
    }

    final allActiveForCounts = eventsAsync.value ?? const <Event>[];
    final ownFamilyCount = allActiveForCounts.where((e) => e.isOwnFamilyEvent).length;
    final relativeCount = allActiveForCounts.where((e) => e.isRelativeEvent).length;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;
    final wide = isWideLayout(context);

    final todayIso = AppDateUtils.getTodayIsoString();

    final masterList = Column(
      children: [
        // Top Bar: View Mode Switcher + Search + Sort
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
          ),
          child: Column(
            children: [
              // Search Box + View Switcher
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
                          hintText: l10n.searchEventsHint,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View mode toggle: List / Calendar
                  Container(
                    decoration: BoxDecoration(
                      color: searchBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewModeButton(
                          icon: Icons.view_agenda_outlined,
                          isSelected: _viewMode == EventViewMode.list,
                          tooltip: l10n.listView,
                          onTap: () => setState(() => _viewMode = EventViewMode.list),
                          primaryAccent: primaryAccent,
                          textSecondary: textSecondary,
                        ),
                        _buildViewModeButton(
                          icon: Icons.calendar_month_outlined,
                          isSelected: _viewMode == EventViewMode.calendar,
                          tooltip: l10n.calendarView,
                          onTap: () => setState(() => _viewMode = EventViewMode.calendar),
                          primaryAccent: primaryAccent,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Sort menu button
                  PopupMenuButton<EventSort>(
                    icon: Icon(Icons.sort, color: textSecondary, size: 22),
                    tooltip: 'Sort',
                    color: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    initialValue: _activeSort,
                    onSelected: (sort) => setState(() => _activeSort = sort),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: EventSort.dateAsc,
                        child: Text(
                          l10n.isEnglish ? 'Date (Upcoming First)' : 'तारीख (आगामी पहले)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeSort == EventSort.dateAsc ? FontWeight.bold : FontWeight.normal,
                            color: _activeSort == EventSort.dateAsc ? primaryAccent : textPrimary,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: EventSort.dateDesc,
                        child: Text(
                          l10n.isEnglish ? 'Date (Latest First)' : 'तारीख (नवीनतम पहले)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeSort == EventSort.dateDesc ? FontWeight.bold : FontWeight.normal,
                            color: _activeSort == EventSort.dateDesc ? primaryAccent : textPrimary,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: EventSort.titleAsc,
                        child: Text(
                          l10n.isEnglish ? 'Name (A to Z)' : 'नाम (अ से ज्ञ)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeSort == EventSort.titleAsc ? FontWeight.bold : FontWeight.normal,
                            color: _activeSort == EventSort.titleAsc ? primaryAccent : textPrimary,
                          ),
                        ),
                      ),
                      PopupMenuItem(
                        value: EventSort.priority,
                        child: Text(
                          l10n.isEnglish ? 'Priority (Urgent First)' : 'प्राथमिकता (अति आवश्यक पहले)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _activeSort == EventSort.priority ? FontWeight.bold : FontWeight.normal,
                            color: _activeSort == EventSort.priority ? primaryAccent : textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 2-Type Event Scope Switcher (All / Own Family / Relative Events)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildScopeTab(
                      label: '${l10n.filterAll} (${allActiveForCounts.length})',
                      icon: Icons.grid_view_rounded,
                      isSelected: _scopeFilter == EventScopeFilter.all,
                      accent: semantic.primary,
                      textSecondary: semantic.textSecondary,
                      selectedBg: semantic.cardBg,
                      onTap: () => setState(() => _scopeFilter = EventScopeFilter.all),
                    ),
                    _buildScopeTab(
                      label: '${l10n.ownFamilyEvent} ($ownFamilyCount)',
                      icon: Icons.home_rounded,
                      isSelected: _scopeFilter == EventScopeFilter.ownFamily,
                      accent: semantic.primary,
                      textSecondary: semantic.textSecondary,
                      selectedBg: semantic.cardBg,
                      onTap: () => setState(() => _scopeFilter = EventScopeFilter.ownFamily),
                    ),
                    _buildScopeTab(
                      label: '${l10n.relativeEvent} ($relativeCount)',
                      icon: Icons.people_alt_outlined,
                      isSelected: _scopeFilter == EventScopeFilter.relative,
                      accent: semantic.info,
                      textSecondary: semantic.textSecondary,
                      selectedBg: semantic.cardBg,
                      onTap: () => setState(() => _scopeFilter = EventScopeFilter.relative),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: l10n.filterAll,
                      isSelected: _activeFilter == EventFilter.all,
                      onTap: () => setState(() => _activeFilter = EventFilter.all),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                    _buildFilterChip(
                      label: l10n.filterUpcoming,
                      isSelected: _activeFilter == EventFilter.upcoming,
                      onTap: () => setState(() => _activeFilter = EventFilter.upcoming),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                    _buildFilterChip(
                      label: l10n.filterToday,
                      isSelected: _activeFilter == EventFilter.today,
                      onTap: () => setState(() => _activeFilter = EventFilter.today),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                    _buildFilterChip(
                      label: l10n.filterCompleted,
                      isSelected: _activeFilter == EventFilter.completed,
                      onTap: () => setState(() => _activeFilter = EventFilter.completed),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                    _buildFilterChip(
                      label: l10n.filterDraft,
                      isSelected: _activeFilter == EventFilter.draft,
                      onTap: () => setState(() => _activeFilter = EventFilter.draft),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                    _buildFilterChip(
                      label: l10n.filterArchived,
                      isSelected: _activeFilter == EventFilter.archived,
                      onTap: () => setState(() => _activeFilter = EventFilter.archived),
                      primaryAccent: primaryAccent,
                      cardBorder: cardBorder,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Content: List or Calendar
        Expanded(
          child: eventsAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
            data: (allEvents) {
              // Apply Filter
              var filtered = allEvents.where((e) {
                // Scope filter (Own Family vs Relative)
                if (_scopeFilter == EventScopeFilter.ownFamily && !e.isOwnFamilyEvent) return false;
                if (_scopeFilter == EventScopeFilter.relative && !e.isRelativeEvent) return false;

                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final typeLabel = l10n.eventTypeLabel(e.eventType, customCategory: e.category);
                  final matchQuery = e.title.toLowerCase().contains(_searchQuery) ||
                      (e.venue ?? '').toLowerCase().contains(_searchQuery) ||
                      (e.villageCity ?? '').toLowerCase().contains(_searchQuery) ||
                      (e.hostPersonName ?? '').toLowerCase().contains(_searchQuery) ||
                      (e.attendingFamilyNote ?? '').toLowerCase().contains(_searchQuery) ||
                      (e.description ?? '').toLowerCase().contains(_searchQuery) ||
                      typeLabel.toLowerCase().contains(_searchQuery);
                  if (!matchQuery) return false;
                }

                // Status & Date filter
                switch (_activeFilter) {
                  case EventFilter.all:
                    return true;
                  case EventFilter.upcoming:
                    return (e.eventDate.compareTo(todayIso) >= 0 ||
                            (e.endDate != null && e.endDate!.compareTo(todayIso) >= 0)) &&
                        e.status != EventStatus.completed &&
                        e.status != EventStatus.cancelled;
                  case EventFilter.today:
                    return e.eventDate == todayIso ||
                        (e.endDate != null && e.eventDate.compareTo(todayIso) <= 0 && e.endDate!.compareTo(todayIso) >= 0);
                  case EventFilter.completed:
                    return e.status == EventStatus.completed || e.eventDate.compareTo(todayIso) < 0;
                  case EventFilter.draft:
                    return e.status == EventStatus.draft;
                  case EventFilter.archived:
                    return true;
                }
              }).toList();

              // Apply Sorting
              filtered.sort((a, b) {
                switch (_activeSort) {
                  case EventSort.dateAsc:
                    return a.eventDate.compareTo(b.eventDate);
                  case EventSort.dateDesc:
                    return b.eventDate.compareTo(a.eventDate);
                  case EventSort.titleAsc:
                    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
                  case EventSort.priority:
                    return _priorityWeight(b.priority).compareTo(_priorityWeight(a.priority));
                }
              });

              if (_viewMode == EventViewMode.calendar) {
                final scopeEvents = allEvents.where((e) {
                  if (_scopeFilter == EventScopeFilter.ownFamily) return e.isOwnFamilyEvent;
                  if (_scopeFilter == EventScopeFilter.relative) return e.isRelativeEvent;
                  return true;
                }).toList();
                return _buildCalendarView(
                  events: scopeEvents,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  wide: wide,
                  l10n: l10n,
                  semantic: semantic,
                  eventStats: eventStats,
                );
              }

              // List View
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBorder),
                          ),
                          child: Icon(Icons.event_available_outlined, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noEventsFound,
                          style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? (l10n.isEnglish ? 'No events matching your search.' : 'आपकी खोज के अनुसार कोई कार्यक्रम नहीं मिला।')
                              : (l10n.isEnglish ? 'Tap "+ New Event" to create your first celebration.' : 'नया कार्यक्रम जोड़ने के लिए नीचे दिए बटन पर टैप करें।'),
                          style: TextStyle(color: textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
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
                  final ev = filtered[index];
                  return _buildEventCard(
                    ev: ev,
                    wide: wide,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    primaryAccent: primaryAccent,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                    l10n: l10n,
                    semantic: semantic,
                    stats: eventStats[ev.id],
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
          l10n.eventsTitle,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        actions: [
          if (widget.onScanEventQr != null)
            IconButton(
              onPressed: widget.onScanEventQr,
              tooltip: l10n.scanEventQr,
              icon: Icon(Icons.qr_code_scanner_rounded, color: primaryAccent),
            ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 75),
              child: ExpressSquish(
                scale: 0.94,
                onTap: widget.onNewEvent,
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
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.newEvent,
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
                  width: 460,
                  child: masterList,
                ),
                VerticalDivider(width: 1, thickness: 1, color: cardBorder),
                Expanded(
                  child: _selectedEventId != null
                      ? EventDetailScreen(
                          key: ValueKey(_selectedEventId),
                          eventId: _selectedEventId!,
                          showBackButton: false,
                          onClose: () => setState(() => _selectedEventId = null),
                        )
                      : EmptyDetailPane(
                          title: l10n.selectEventToViewDetails,
                          icon: Icons.celebration_outlined,
                          actionLabel: l10n.newEvent,
                          onAction: widget.onNewEvent,
                        ),
                ),
              ],
            )
          : masterList,
    );
  }

  // View toggle icon button helper
  Widget _buildViewModeButton({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
    required Color primaryAccent,
    required Color textSecondary,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : textSecondary,
          ),
        ),
      ),
    );
  }

  // Filter Chip helper
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryAccent,
    required Color cardBorder,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? primaryAccent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryAccent : cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryAccent : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // Event Card in List View
  Widget _buildEventCard({
    required Event ev,
    required bool wide,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
    ({int totalMila, int totalDiya, int count})? stats,
  }) {
    final eventTypeName = l10n.eventTypeLabel(ev.eventType, customCategory: ev.category);
    final isSelected = wide && _selectedEventId == ev.id;

    // Format date range
    String dateRangeText = ev.eventDate;
    if (ev.endDate != null && ev.endDate!.isNotEmpty && ev.endDate != ev.eventDate) {
      dateRangeText = '${ev.eventDate} ~ ${ev.endDate}';
    }

    // Countdown calculation for active upcoming events
    int? daysLeft;
    if (ev.status != EventStatus.completed && ev.status != EventStatus.cancelled && ev.archivedAt == null) {
      final evDt = DateTime.tryParse(ev.eventDate);
      if (evDt != null) {
        final now = DateTime.now();
        daysLeft = DateTime(evDt.year, evDt.month, evDt.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
      }
    }

    // Location display
    final locationParts = <String>[];
    if (ev.venue != null && ev.venue!.isNotEmpty) locationParts.add(ev.venue!);
    if (ev.villageCity != null && ev.villageCity!.isNotEmpty) locationParts.add(ev.villageCity!);
    final locationStr = locationParts.join(' • ');

    // Status config
    final (statusLabel, statusColor) = _statusStyle(ev.status, l10n);
    final scopeAccent = ev.isRelativeEvent ? semantic.info : semantic.primary;
    final scopeLabel = ev.isRelativeEvent
        ? (ev.hostPersonName != null && ev.hostPersonName!.isNotEmpty
            ? '${l10n.isEnglish ? 'Host' : 'मेज़बान'}: ${ev.hostPersonName}'
            : l10n.relativeEvent)
        : l10n.ownFamilyEvent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpressCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        radius: 16,
        color: isSelected ? primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08) : cardBg,
        borderColor: isSelected ? primaryAccent : cardBorder,
        borderWidth: isSelected ? 2.0 : 1.0,
        elevation: isSelected ? 2 : 0,
        onTap: () {
          if (wide) {
            setState(() => _selectedEventId = ev.id);
          } else {
            widget.onOpenEventDetail?.call(ev.id);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scope Badge + Countdown row
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scopeAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scopeAccent.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ev.isRelativeEvent ? Icons.people_alt_outlined : Icons.home_rounded,
                          size: 12,
                          color: scopeAccent,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            scopeLabel,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: scopeAccent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ev.isRelativeEvent && ev.attendingFamilyNote != null && ev.attendingFamilyNote!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: semantic.cardSubtleBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: semantic.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.groups_outlined, size: 11, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            ev.attendingFamilyNote!,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  if (daysLeft != null && daysLeft >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (daysLeft <= 3 ? semantic.warning : semantic.info).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.daysLeftLabel(daysLeft),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: daysLeft <= 3 ? semantic.warning : semantic.info,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Row 1: Title + Event Type badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (ev.priority == EventPriority.urgent) ...[
                        Icon(Icons.error_outline, color: semantic.diya, size: 16),
                        const SizedBox(width: 4),
                      ] else if (ev.priority == EventPriority.high) ...[
                        Icon(Icons.arrow_upward, color: semantic.warning, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          ev.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    eventTypeName,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Date + Time + Location (overflow-safe Wrap)
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(dateRangeText, style: TextStyle(color: textSecondary, fontSize: 12)),
                  ],
                ),
                if (ev.startTime != null && ev.startTime!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 13, color: textSecondary),
                      const SizedBox(width: 3),
                      Text(ev.startTime!, style: TextStyle(color: textSecondary, fontSize: 12)),
                    ],
                  ),
                if (locationStr.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: textSecondary),
                      const SizedBox(width: 3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          locationStr,
                          style: TextStyle(color: textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 3: Metrics Badges (Status, Functions, Checklist, Budget)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),

                // Functions count
                if (ev.functions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: semantic.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.celebration_outlined, size: 11, color: semantic.secondary),
                        const SizedBox(width: 3),
                        Text(
                          '${ev.functions.length} ${l10n.isEnglish ? 'functions' : 'रस्में'}',
                          style: TextStyle(fontSize: 10.5, color: semantic.secondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Checklist count
                if (ev.tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: semantic.mila.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 11, color: semantic.mila),
                        const SizedBox(width: 3),
                        Text(
                          '${ev.completedTasksCount}/${ev.tasks.length} ${l10n.isEnglish ? 'tasks' : 'कार्य'}',
                          style: TextStyle(fontSize: 10.5, color: semantic.mila, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Budget Estimate
                if (ev.budgetEstimatedPaise != null && ev.budgetEstimatedPaise! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: semantic.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 11, color: semantic.info),
                        const SizedBox(width: 3),
                        Text(
                          CurrencyUtils.formatPaise(ev.budgetEstimatedPaise!),
                          style: TextStyle(fontSize: 10.5, color: semantic.info, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Footer: Live Mila/Diya Totals + 1-Tap Shagun Entry
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder.withValues(alpha: 0.7))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: (stats != null && stats.count > 0)
                        ? Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (stats.totalMila > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: semantic.milaContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: semantic.milaBorder),
                                  ),
                                  child: Text(
                                    '+ ${CurrencyUtils.formatPaise(stats.totalMila)}',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: semantic.mila),
                                  ),
                                ),
                              if (stats.totalDiya > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: semantic.diyaContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: semantic.diyaBorder),
                                  ),
                                  child: Text(
                                    '- ${CurrencyUtils.formatPaise(stats.totalDiya)}',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: semantic.diya),
                                  ),
                                ),
                              Text(
                                '(${stats.count})',
                                style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : Text(
                            l10n.isEnglish ? 'No shagun entries yet' : 'अभी कोई शगुन प्रविष्टि नहीं',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (direction) {
                      final hostParam = (ev.hostPersonId != null && ev.hostPersonId!.isNotEmpty)
                          ? '&personId=${ev.hostPersonId}'
                          : '';
                      context.push('/entry/new?direction=$direction&eventId=${ev.id}$hostParam');
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        value: 'received',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, color: semantic.mila, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.isEnglish ? '+ Received (Mila)' : '+ शगुन मिला दर्ज करें',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'given',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, color: semantic.diya, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.isEnglish ? '+ Given (Diya)' : '+ शगुन दिया दर्ज करें',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryAccent.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: primaryAccent),
                          const SizedBox(width: 3),
                          Text(
                            l10n.isEnglish ? 'Shagun' : 'शगुन',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accent,
    required Color textSecondary,
    required Color selectedBg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: accent.withValues(alpha: 0.35)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? accent : textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calendar View
  Widget _buildCalendarView({
    required List<Event> events,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryAccent,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required bool wide,
    required AppLocalizations l10n,
    required AppSemanticColors semantic,
    required Map<String, ({int totalMila, int totalDiya, int count})> eventStats,
  }) {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;

    // Localized month header
    final monthName = l10n.isEnglish
        ? AppDateUtils.englishMonths[month - 1]
        : (l10n.isUrdu ? AppDateUtils.urduMonths[month - 1] : AppDateUtils.hindiMonths[month - 1]);
    final monthHeaderTitle = '$monthName $year';

    // Days calculation
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingBlanks = (firstWeekday - 1) % 7;

    final weekDays = l10n.isEnglish
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : (l10n.isUrdu
            ? const ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار']
            : const ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि']);

    // Map events by day
    final Map<int, List<Event>> eventsByDay = {};
    for (final ev in events) {
      try {
        final startDt = DateTime.parse(ev.eventDate);
        DateTime endDt = startDt;
        if (ev.endDate != null && ev.endDate!.isNotEmpty) {
          endDt = DateTime.tryParse(ev.endDate!) ?? startDt;
        }

        for (int day = 1; day <= daysInMonth; day++) {
          final target = DateTime(year, month, day);
          if ((target.isAfter(startDt.subtract(const Duration(days: 1))) || _isSameDay(target, startDt)) &&
              (target.isBefore(endDt.add(const Duration(days: 1))) || _isSameDay(target, endDt))) {
            eventsByDay.putIfAbsent(day, () => []).add(ev);
          }
        }
      } catch (_) {}
    }

    final selectedDayIso =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final selectedDayEvents = events.where((e) {
      if (e.eventDate == selectedDayIso) return true;
      if (e.endDate != null && e.endDate!.isNotEmpty) {
        return e.eventDate.compareTo(selectedDayIso) <= 0 && e.endDate!.compareTo(selectedDayIso) >= 0;
      }
      return false;
    }).toList();

    return ListView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: wide ? AppSpacing.md : AppSpacing.floatingTabBottomPadding + 20,
      ),
      children: [
        // Month Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                  });
                },
              ),
              Row(
                children: [
                  Text(
                    monthHeaderTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
                        _calendarMonth = DateTime(now.year, now.month, 1);
                        _selectedDate = DateTime(now.year, now.month, now.day);
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.today,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Calendar Grid Container
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              // Weekday headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays
                    .map((w) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              w,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Calendar Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.0,
                ),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) {
                    return const SizedBox.shrink();
                  }
                  final dayNum = index - leadingBlanks + 1;
                  final dayDate = DateTime(year, month, dayNum);
                  final isToday = _isSameDay(dayDate, DateTime.now());
                  final isSelected = _isSameDay(dayDate, _selectedDate);
                  final dayEvents = eventsByDay[dayNum] ?? [];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = dayDate;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryAccent
                            : (isToday ? primaryAccent.withValues(alpha: 0.12) : Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(color: primaryAccent, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isToday ? primaryAccent : textPrimary),
                            ),
                          ),
                          if (dayEvents.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : primaryAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Events on Selected Date Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.isEnglish
                  ? 'Events on ${AppDateUtils.formatIsoDate(selectedDayIso, 'en')}'
                  : 'निर्धारित कार्यक्रम (${AppDateUtils.formatIsoDate(selectedDayIso, 'hi')})',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            Text(
              '${selectedDayEvents.length} ${l10n.isEnglish ? 'events' : 'आयोजन'}',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (selectedDayEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Center(
              child: Text(
                l10n.isEnglish
                    ? 'No events scheduled on this date.'
                    : 'इस तारीख को कोई कार्यक्रम निर्धारित नहीं है।',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ),
          )
        else
          ...selectedDayEvents.map((ev) => _buildEventCard(
                ev: ev,
                wide: wide,
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryAccent: primaryAccent,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
                l10n: l10n,
                semantic: semantic,
                stats: eventStats[ev.id],
              )),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _priorityWeight(EventPriority priority) {
    switch (priority) {
      case EventPriority.urgent:
        return 4;
      case EventPriority.high:
        return 3;
      case EventPriority.normal:
        return 2;
      case EventPriority.low:
        return 1;
    }
  }

  (String, Color) _statusStyle(EventStatus status, AppLocalizations l10n) {
    switch (status) {
      case EventStatus.draft:
        return (l10n.filterDraft, Colors.amber);
      case EventStatus.planned:
        return (l10n.isEnglish ? 'Planned' : 'योजनाबद्ध', Colors.blue);
      case EventStatus.confirmed:
        return (l10n.isEnglish ? 'Confirmed' : 'पुष्टीकृत', Colors.teal);
      case EventStatus.inProgress:
        return (l10n.isEnglish ? 'In Progress' : 'चल रहा है', Colors.indigo);
      case EventStatus.completed:
        return (l10n.filterCompleted, Colors.green);
      case EventStatus.cancelled:
        return (l10n.filterCancelled, Colors.red);
      case EventStatus.archived:
        return (l10n.filterArchived, Colors.grey);
    }
  }
}
