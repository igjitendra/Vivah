import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/direction_badge.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/express_button.dart';
import '../../reports/services/pdf_service.dart';
import '../../reports/services/csv_service.dart';

/// Complete, Advanced Event Management System Details Screen
/// Features 8 structured tabs, real-time data persistence, conflict detection,
/// guest RSVP, task checklists, budget categories, linked transactions, offline reminders, and audit history.
class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  final bool showBackButton;
  final VoidCallback? onClose;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.showBackButton = true,
    this.onClose,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    setState(() => _refreshCounter++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final entriesAsync = ref.watch(entriesListProvider(null));

    return eventAsync.when(
      loading: () => Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryAccent)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: Text('${l10n.errorGeneric}: $err')),
      ),
      data: (event) {
        if (event == null) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(backgroundColor: headerBg),
            body: Center(child: Text(l10n.eventNotFound)),
          );
        }

        // Get linked transactions
        final linkedEntries = entriesAsync.maybeWhen(
          data: (all) => all.where((e) => e.eventId == event.id && e.archivedAt == null).toList(),
          orElse: () => <TransactionEntry>[],
        );

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: headerBg,
            elevation: 0.5,
            leading: widget.showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.5,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.eventTypeLabel(event.eventType, customCategory: event.category),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${event.eventDate}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'कार्यक्रम संपादित करें (Edit Event)',
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'एडिट',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                onPressed: () => _showFullEditEventDialog(event),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (val) => _handleMenuAction(val, event, linkedEntries),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('पूर्ण विवरण संपादित करें (Full Edit)')),
                  const PopupMenuItem(value: 'duplicate', child: Text('प्रतिलिपि बनाएं (Duplicate)')),
                  const PopupMenuItem(value: 'share', child: Text('निमंत्रण साझा करें (Share)')),
                  const PopupMenuItem(value: 'export_pdf', child: Text('बही-खाता PDF निर्यात')),
                  const PopupMenuItem(value: 'export_csv', child: Text('Excel CSV निर्यात')),
                  const PopupMenuDivider(),
                  if (!event.isArchived)
                    const PopupMenuItem(value: 'archive', child: Text('संग्रहीत करें (Archive)'))
                  else
                    const PopupMenuItem(value: 'restore', child: Text('पुनर्स्थापित करें (Restore)')),
                  const PopupMenuItem(value: 'cancel', child: Text('रद्द करें (Cancel)', style: TextStyle(color: Colors.orange))),
                  const PopupMenuItem(value: 'delete', child: Text('हटाएं (Delete Safely)', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF262D3D) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: primaryAccent,
                  unselectedLabelColor: textSecondary,
                  indicatorColor: primaryAccent,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: l10n.eventOverview),
                    Tab(text: '${l10n.eventFunctions} (${event.functions.length})'),
                    Tab(text: '${l10n.eventPeople} (${event.participants.length})'),
                    Tab(text: '${l10n.eventGuests} (${event.guests.length})'),
                    Tab(text: '${l10n.eventTasks} (${event.completedTasksCount}/${event.tasks.length})'),
                    Tab(text: '${l10n.eventBudget} (${linkedEntries.length})'),
                    Tab(text: '${l10n.eventNotesTab} (${event.notesList.length})'),
                    Tab(text: l10n.eventRemindersTab),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Overview Tab
              _buildOverviewTab(event, linkedEntries, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 2. Functions & Schedule Tab
              _buildFunctionsTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 3. People & Families Tab
              _buildPeopleTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 4. Guests & Invitations Tab
              _buildGuestsTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 5. Tasks & Checklist Tab
              _buildTasksTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 6. Budget & Transactions Tab
              _buildBudgetAndLedgerTab(event, linkedEntries, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 7. Notes & Attachments Tab
              _buildNotesTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),

              // 8. Reminders & Activity History Tab
              _buildRemindersAndHistoryTab(event, cardBg, cardBorder, textPrimary, textSecondary, primaryAccent),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW
  // =========================================================================
  Widget _buildOverviewTab(
    Event event,
    List<TransactionEntry> linkedEntries,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    final l10n = context.l10n;
    final totalReceived = linkedEntries
        .where((e) => e.direction.value == 'received' && e.status.value == 'recorded')
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final totalGiven = linkedEntries
        .where((e) => e.direction.value == 'given' && e.status.value == 'recorded')
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Hero Status & Timing Banner
        ExpressCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          radius: 18,
          color: cardBg,
          borderColor: cardBorder,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(event.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.status.labelHindi,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _statusColor(event.status)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.eventTypeLabel(event.eventType, customCategory: event.category),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: primaryAccent.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: Icon(Icons.edit_outlined, size: 14, color: primaryAccent),
                    label: Text(
                      'संपादित करें',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                    onPressed: () => _showFullEditEventDialog(event),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(event.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 16, color: primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    '${event.eventDate}${event.endDate != null ? " से ${event.endDate!}" : ""}',
                    style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                  if (event.startTime != null) ...[
                    const SizedBox(width: 8),
                    Text('• ${event.startTime}', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                  if (event.isAllDay) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('पूरा दिन', style: TextStyle(fontSize: 10.5, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              if (event.venue != null && event.venue!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: primaryAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${event.venue!}${event.villageCity != null && event.villageCity!.isNotEmpty ? ", ${event.villageCity!}" : ""}',
                        style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (event.budgetEstimatedPaise != null && event.budgetEstimatedPaise! > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.milaGreen),
                    const SizedBox(width: 6),
                    Text(
                      'अनुमानित बजट: ${CurrencyUtils.formatPaise(event.budgetEstimatedPaise!)}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.milaGreen),
                    ),
                  ],
                ),
              ],
              if (event.notes != null && event.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  event.notes!,
                  style: TextStyle(fontSize: 12, color: textSecondary, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Quick Stats Strip (4 Pillars)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'चेकलिस्ट',
                value: '${event.completedTasksCount}/${event.tasks.length}',
                subtext: '${event.taskCompletionPercentage.toInt()}% पूर्ण',
                color: const Color(0xFF8B5CF6),
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildMetricCard(
                title: 'मेहमान',
                value: '${event.confirmedGuestCount}',
                subtext: '${event.totalGuestCount} कुल आमंत्रित',
                color: const Color(0xFF38BDF8),
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'कुल मिला (Mila)',
                value: CurrencyUtils.formatPaise(totalReceived),
                subtext: 'शुद्ध रोकड़ प्राप्त',
                color: AppColors.milaGreen,
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildMetricCard(
                title: 'कुल दिया (Diya)',
                value: CurrencyUtils.formatPaise(totalGiven),
                subtext: 'शुद्ध रोकड़ खर्च',
                color: AppColors.diyaRed,
                cardBg: cardBg,
                cardBorder: cardBorder,
                textPrimary: textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Key Associated People Preview
        if (event.participants.isNotEmpty) ...[
          Text('मुख्य आयोजन भूमिकाएं', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.participants.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      child: Text(p.name.substring(0, 1), style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                    const SizedBox(width: 4),
                    Text('(${p.role.labelHindi})', style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Upcoming Activities / Next Function
        if (event.functions.isNotEmpty) ...[
          Text('आगामी रस्में (Upcoming Functions)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
          const SizedBox(height: 8),
          ...event.functions.take(2).map((fn) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fn.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                          Text('${fn.functionDate} • ${fn.venue ?? "स्थल निर्धारित नहीं"}', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color color,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
          ),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: FUNCTIONS & SCHEDULE
  // =========================================================================
  Widget _buildFunctionsTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('रस्में व उत्सव सूची (${event.functions.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddFunctionDialog(event),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('नई रस्म'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (event.functions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('अभी कोई रस्म नहीं जुड़ी है। ऊपर "नई रस्म" पर टैप करें।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...event.functions.map((fn) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.celebration, color: Color(0xFFF59E0B), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditFunctionDialog(event, fn),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fn.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              '${fn.functionDate}${fn.startTime != null ? " • ${fn.startTime!}" : ""}${fn.endTime != null ? " - ${fn.endTime!}" : ""}',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            if (fn.venue != null && fn.venue!.isNotEmpty) Text('स्थल: ${fn.venue}', style: TextStyle(fontSize: 11.5, color: primaryAccent)),
                            if (fn.description != null && fn.description!.isNotEmpty)
                              Text(fn.description!, style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: primaryAccent),
                      tooltip: 'संपादित करें',
                      onPressed: () => _showEditFunctionDialog(event, fn),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'हटाएं',
                      onPressed: () async {
                        await ref.read(eventsRepositoryProvider).deleteFunction(fn.id);
                        _triggerRefresh();
                      },
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // TAB 3: PEOPLE & FAMILIES
  // =========================================================================
  Widget _buildPeopleTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('संबद्ध लोग व भूमिकाएं (${event.participants.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddParticipantSheet(event),
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('व्यक्ति जोड़ें'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (event.participants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('अभी कोई व्यक्ति नहीं जुड़ा है। मेजबान, दुल्हन या आयोजक जोड़ने के लिए ऊपर टैप करें।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...event.participants.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: AppColors.terracotta, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditParticipantDialog(event, p),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                            Text(p.role.labelHindi, style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600)),
                            if (p.phone != null && p.phone!.isNotEmpty) Text('फ़ोन: ${p.phone}', style: TextStyle(fontSize: 11, color: textSecondary)),
                            if (p.notes != null && p.notes!.isNotEmpty)
                              Text(p.notes!, style: TextStyle(fontSize: 10.5, color: textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: primaryAccent),
                      tooltip: 'संपादित करें',
                      onPressed: () => _showEditParticipantDialog(event, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      tooltip: 'हटाएं',
                      onPressed: () async {
                        await ref.read(eventsRepositoryProvider).removeParticipant(p.id);
                        _triggerRefresh();
                      },
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // TAB 4: GUESTS & INVITATIONS
  // =========================================================================
  Widget _buildGuestsTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGuestStat('कुल मेहमान', '${event.totalGuestCount}'),
              _buildGuestStat('स्वीकृत / उपस्थित', '${event.confirmedGuestCount}', color: Colors.green),
              _buildGuestStat('निमंत्रण शेष', '${event.guests.where((g) => g.invitationStatus == InvitationStatus.notSent).length}', color: Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddGuestDialog(event),
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('मेहमान जोड़ें'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
            ),
            OutlinedButton.icon(
              onPressed: () => _copyInvitationToClipboard(event),
              icon: const Icon(Icons.share, size: 16),
              label: const Text('निमंत्रण कॉपी'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (event.guests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('अतिथि सूची खाली है। मेहमानों को जोड़ने के लिए ऊपर टैप करें।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...event.guests.map((g) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withValues(alpha: 0.15),
                      child: Text('${g.accompanyingCount + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditGuestDialog(event, g),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary)),
                            Text(
                              'निमंत्रण: ${g.invitationStatus.labelHindi} • उपस्थिति: ${g.attendanceStatus.labelHindi}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            if (g.familyOrGroup != null && g.familyOrGroup!.isNotEmpty)
                              Text('समूह/परिवार: ${g.familyOrGroup}', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                            if (g.notes != null && g.notes!.isNotEmpty)
                              Text(g.notes!, style: TextStyle(fontSize: 10.5, color: textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: primaryAccent),
                      tooltip: 'संपादित करें',
                      onPressed: () => _showEditGuestDialog(event, g),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'हटाएं',
                      onPressed: () async {
                        await ref.read(eventsRepositoryProvider).deleteGuest(g.id);
                        _triggerRefresh();
                      },
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildGuestStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color ?? Colors.blue.shade800)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  // =========================================================================
  // TAB 5: TASKS & CHECKLIST
  // =========================================================================
  Widget _buildTasksTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Progress Bar Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('तैयारी प्रगति (Checklist Progress)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${event.taskCompletionPercentage.toInt()}%', style: TextStyle(fontWeight: FontWeight.w800, color: primaryAccent)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: event.tasks.isEmpty ? 0 : event.taskCompletionPercentage / 100,
                  backgroundColor: cardBorder,
                  color: primaryAccent,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('कार्य सूची (${event.tasks.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskDialog(event),
              icon: const Icon(Icons.add_task, size: 16),
              label: const Text('नया कार्य'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (event.tasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('चेकलिस्ट में कोई कार्य नहीं है। ऊपर "नया कार्य" जोड़ें।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...event.tasks.map((task) {
            final isDone = task.status == TaskStatus.completed;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
              child: Row(
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: primaryAccent,
                    onChanged: (val) async {
                      await ref.read(eventsRepositoryProvider).toggleTaskStatus(
                            task.id,
                            val == true ? TaskStatus.completed : TaskStatus.pending,
                          );
                      _triggerRefresh();
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showEditTaskDialog(event, task),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDone ? textSecondary : textPrimary,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Row(
                            children: [
                              if (task.dueDate != null)
                                Text('अंतिम तिथि: ${task.dueDate}', style: TextStyle(fontSize: 11, color: isDone ? Colors.grey : Colors.orange.shade800)),
                              if (task.assignedPersonName != null && task.assignedPersonName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('• जिम्मा: ${task.assignedPersonName}', style: TextStyle(fontSize: 11, color: textSecondary)),
                              ],
                            ],
                          ),
                          if (task.description != null && task.description!.isNotEmpty)
                            Text(task.description!, style: TextStyle(fontSize: 10.5, color: textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 16, color: primaryAccent),
                    tooltip: 'संपादित करें',
                    onPressed: () => _showEditTaskDialog(event, task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    tooltip: 'हटाएं',
                    onPressed: () async {
                      await ref.read(eventsRepositoryProvider).deleteTask(task.id);
                      _triggerRefresh();
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // =========================================================================
  // TAB 6: BUDGET & TRANSACTIONS
  // =========================================================================
  Widget _buildBudgetAndLedgerTab(
    Event event,
    List<TransactionEntry> linkedEntries,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalReceived = linkedEntries
        .where((e) => e.direction.value == 'received' && e.status.value == 'recorded')
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final totalGiven = linkedEntries
        .where((e) => e.direction.value == 'given' && e.status.value == 'recorded')
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Budget & Cash Overview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('वित्तीय सारांश (Financial Summary)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  Text(
                    'अनुमानित बजट: ${CurrencyUtils.formatPaise(event.budgetEstimatedPaise ?? 0)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(CurrencyUtils.formatPaise(totalReceived), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.milaGreen)),
                      const Text('कुल मिला (Mila)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Container(width: 1, height: 30, color: cardBorder),
                  Column(
                    children: [
                      Text(CurrencyUtils.formatPaise(totalGiven), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.diyaRed)),
                      const Text('कुल दिया (Diya)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Container(width: 1, height: 30, color: cardBorder),
                  Column(
                    children: [
                      Text(
                        CurrencyUtils.formatPaise(event.remainingBudgetPaise),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: event.remainingBudgetPaise >= 0 ? primaryAccent : Colors.red,
                        ),
                      ),
                      const Text('शेष बजट (Balance)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Budget Categories Breakdown Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('बजट श्रेणियां (${event.budgetCategories.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBudgetCategoryDialog(event),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('श्रेणी जोड़ें', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (event.budgetCategories.isEmpty)
                Text('कोई बजट श्रेणी नहीं जुड़ी है। जैसे खान-पान, सजावट, टेंट आदि जोड़ने के लिए ऊपर टैप करें।', style: TextStyle(fontSize: 11.5, color: textSecondary))
              else
                ...event.budgetCategories.map((cat) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showEditBudgetCategoryDialog(event, cat),
                              borderRadius: BorderRadius.circular(6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.categoryName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text('अनुमान: ${CurrencyUtils.formatPaise(cat.estimatedAmountPaise)}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                      const SizedBox(width: 8),
                                      Text('वास्तविक: ${CurrencyUtils.formatPaise(cat.actualAmountPaise)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.diyaRed)),
                                    ],
                                  ),
                                  if (cat.notes != null && cat.notes!.isNotEmpty)
                                    Text(cat.notes!, style: TextStyle(fontSize: 10, color: textSecondary, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_outlined, size: 16, color: primaryAccent),
                            tooltip: 'संपादित करें',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showEditBudgetCategoryDialog(event, cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            tooltip: 'हटाएं',
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await ref.read(eventsRepositoryProvider).deleteBudgetCategory(cat.id);
                              _triggerRefresh();
                            },
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Action Buttons: Add Transaction Directly
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/entry/new?eventId=${event.id}'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('नया व्यवहार जोड़ें'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.terracotta),
              tooltip: 'PDF बही-खाता',
              onPressed: () => _exportPdf(event, linkedEntries),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text('संबद्ध लेन-देन इतिहास (${linkedEntries.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
        const SizedBox(height: 10),

        if (linkedEntries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noTransactionsForEvent, style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...linkedEntries.map((e) => ExpressSquish(
                onTap: () => context.push('/entry/${e.id}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
                  child: Row(
                    children: [
                      DirectionBadge(direction: e.direction),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.personName ?? 'अज्ञात', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                            Text(
                              '${AppDateUtils.formatIsoDate(e.transactionDate, l10n.locale.languageCode)}${e.notes != null ? " • ${e.notes!}" : ""}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatPaise(e.amountPaise ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: e.direction.isReceived ? AppColors.milaGreen : AppColors.diyaRed,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // TAB 7: NOTES & ATTACHMENTS
  // =========================================================================
  Widget _buildNotesTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('निर्देश व नोट्स (${event.notesList.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddNoteDialog(event),
              icon: const Icon(Icons.note_add, size: 16),
              label: const Text('नया नोट'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (event.notesList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('कोई नोट उपलब्ध नहीं है। ऊपर "नया नोट" पर टैप करें।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...event.notesList.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cardBorder)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEditNoteDialog(event, n),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary)),
                            const SizedBox(height: 3),
                            Text(n.content, style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: primaryAccent),
                      tooltip: 'संपादित करें',
                      onPressed: () => _showEditNoteDialog(event, n),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                      tooltip: 'हटाएं',
                      onPressed: () async {
                        await ref.read(eventsRepositoryProvider).deleteNote(n.id);
                        _triggerRefresh();
                      },
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // TAB 8: REMINDERS & ACTIVITY HISTORY
  // =========================================================================
  Widget _buildRemindersAndHistoryTab(
    Event event,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    Color primaryAccent,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Reminders Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ऑफ़लाइन अनुस्मारक (${event.reminders.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textPrimary)),
            TextButton.icon(
              icon: const Icon(Icons.alarm_add, size: 16),
              label: const Text('अनुस्मारक जोड़ें'),
              onPressed: () => _showAddReminderDialog(event),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...event.reminders.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFFEAB308), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(r.title, style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: r.isEnabled,
                    activeColor: primaryAccent,
                    onChanged: (val) async {
                      await ref.read(eventsRepositoryProvider).toggleReminder(r.id, val);
                      _triggerRefresh();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () async {
                      await ref.read(eventsRepositoryProvider).deleteReminder(r.id);
                      _triggerRefresh();
                    },
                  ),
                ],
              ),
            )),

        const SizedBox(height: 18),

        // Activity Audit Log
        Text('गतिविधि इतिहास (Audit Trail)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textPrimary)),
        const SizedBox(height: 8),
        if (event.activityLogs.isEmpty)
          Text('कोई गतिविधि दर्ज नहीं है।', style: TextStyle(color: textSecondary, fontSize: 12))
        else
          ...event.activityLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: primaryAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.action, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: textPrimary)),
                          if (log.details != null && log.details!.isNotEmpty)
                            Text(log.details!, style: TextStyle(fontSize: 11, color: textSecondary)),
                          Text(
                            '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  // =========================================================================
  // LIFECYCLE ACTION HANDLERS & MODALS
  // =========================================================================

  void _handleMenuAction(String action, Event event, List<TransactionEntry> linkedEntries) async {
    final repo = ref.read(eventsRepositoryProvider);
    switch (action) {
      case 'edit':
        _showEditEventDialog(event);
        break;
      case 'duplicate':
        _showDuplicateDialog(event);
        break;
      case 'share':
        _copyInvitationToClipboard(event);
        break;
      case 'export_pdf':
        _exportPdf(event, linkedEntries);
        break;
      case 'export_csv':
        _exportCsv(event, linkedEntries);
        break;
      case 'archive':
        await repo.archiveEvent(event.id);
        _triggerRefresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कार्यक्रम संग्रहीत किया गया')));
        break;
      case 'restore':
        await repo.restoreEvent(event.id);
        _triggerRefresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कार्यक्रम पुनर्स्थापित किया गया')));
        break;
      case 'cancel':
        _promptCancelEvent(event);
        break;
      case 'delete':
        _confirmDeleteSafely(event);
        break;
    }
  }

  void _copyInvitationToClipboard(Event event) {
    final text = StringBuffer();
    text.writeln('--- सादर निमंत्रण ---');
    text.writeln('आप हमारे पारिवारिक कार्यक्रम "${event.title}" में सपरिवार सादर आमंत्रित हैं।');
    text.writeln('दिनांक: ${event.eventDate}');
    if (event.startTime != null) text.writeln('समय: ${event.startTime}');
    if (event.venue != null) text.writeln('स्थल: ${event.venue}');
    if (event.mapLink != null) text.writeln('नक्शा: ${event.mapLink}');
    text.writeln('— विनीत: समस्त परिवार');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('निमंत्रण पत्र कॉपी कर लिया गया है।'), backgroundColor: AppColors.milaGreen),
    );
  }

  Future<void> _exportPdf(Event event, List<TransactionEntry> entries) async {
    try {
      final file = await PdfService.generateLedgerPdf(
        entries: entries,
        title: '${event.title} - बही-खाता',
        subtitle: 'दिनांक: ${event.eventDate} • स्थल: ${event.venue ?? ""}',
        l10n: context.l10n,
      );
      await Printing.layoutPdf(onLayout: (format) => file.readAsBytes());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF तैयार करने में त्रुटि: $e')));
    }
  }

  Future<void> _exportCsv(Event event, List<TransactionEntry> entries) async {
    try {
      final file = await CsvService.generateLedgerCsv(entries: entries, l10n: context.l10n);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV फ़ाइल सुरक्षित: ${file.path}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV निर्यात में त्रुटि: $e')));
    }
  }

  void _confirmDeleteSafely(Event event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('कार्यक्रम हटाएं?'),
        content: const Text(
          'क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं?\n\n'
          'सुरक्षा नियम: इस कार्यक्रम के सभी वित्तीय लेन-देन सुरक्षित रहेंगे।',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventsRepositoryProvider).deleteEventSafely(event.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कार्यक्रम सुरक्षित रूप से हटा दिया गया')));
                Navigator.of(context).pop();
              }
            },
            child: const Text('हटाएं', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _promptCancelEvent(Event event) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('कार्यक्रम रद्द करें'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'रद्द करने का कारण')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('पीछे जाएं')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventsRepositoryProvider).cancelEvent(event.id, reasonCtrl.text.trim());
              _triggerRefresh();
            },
            child: const Text('रद्द करें', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDuplicateDialog(Event event) {
    final titleCtrl = TextEditingController(text: '${event.title} (प्रतिलिपि)');
    String newDate = event.eventDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('कार्यक्रम की प्रतिलिपि बनाएं'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'नया शीर्षक')),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('दिनांक: $newDate'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDlgState(() => newDate = picked.toIso8601String().split('T').first);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final newId = await ref.read(eventsRepositoryProvider).duplicateEvent(event.id, titleCtrl.text.trim(), newDate);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कार्यक्रम की प्रतिलिपि तैयार है')));
                  context.push('/event/$newId');
                }
              },
              child: const Text('बनाएं'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(Event event) => _showFullEditEventDialog(event);

  void _showFullEditEventDialog(Event event) {
    final titleCtrl = TextEditingController(text: event.title);
    final venueCtrl = TextEditingController(text: event.venue ?? '');
    final villageCityCtrl = TextEditingController(text: event.villageCity ?? '');
    final budgetCtrl = TextEditingController(
      text: event.budgetEstimatedPaise != null && event.budgetEstimatedPaise! > 0
          ? (event.budgetEstimatedPaise! / 100).round().toString()
          : '',
    );
    final notesCtrl = TextEditingController(text: event.notes ?? '');
    final customCtrl = TextEditingController(text: event.category ?? '');
    EventType selType = event.eventType;
    EventStatus selStatus = event.status;
    String selDate = event.eventDate;
    String? selEndDate = event.endDate;
    bool isAllDay = event.isAllDay;
    TimeOfDay? selStartTime = event.startTime != null && event.startTime!.contains(':')
        ? TimeOfDay(
            hour: int.tryParse(event.startTime!.split(':')[0]) ?? 0,
            minute: int.tryParse(event.startTime!.split(':')[1]) ?? 0,
          )
        : null;
    TimeOfDay? selEndTime = event.endTime != null && event.endTime!.contains(':')
        ? TimeOfDay(
            hour: int.tryParse(event.endTime!.split(':')[0]) ?? 0,
            minute: int.tryParse(event.endTime!.split(':')[1]) ?? 0,
          )
        : null;

    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.terracotta, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'कार्यक्रम पूर्ण विवरण संपादित करें',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: '${l10n.eventName} *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Event Type
                  DropdownButtonFormField<EventType>(
                    value: selType,
                    items: [
                      EventType.shaadi,
                      EventType.sagai,
                      EventType.tilak,
                      EventType.baraat,
                      EventType.haldi,
                      EventType.mehndi,
                      EventType.reception,
                      EventType.grihaPravesh,
                      EventType.namkaran,
                      EventType.mundan,
                      EventType.janeu,
                      EventType.godhBharai,
                      EventType.chhathi,
                      EventType.birthday,
                      EventType.anniversary,
                      EventType.katha,
                      EventType.religiousCeremony,
                      EventType.festival,
                      EventType.familyGathering,
                      EventType.retirement,
                      EventType.inauguration,
                      EventType.funeral,
                      EventType.communityEvent,
                      EventType.other,
                    ].map((t) => DropdownMenuItem(value: t, child: Text(l10n.eventTypeLabel(t)))).toList(),
                    onChanged: (val) => setDlgState(() => selType = val ?? EventType.shaadi),
                    decoration: InputDecoration(
                      labelText: l10n.eventType,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  if (selType == EventType.other) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.customCeremony,
                        hintText: l10n.customCeremonyHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Date Picker (Primary Event Date)
                  const Text('कार्यक्रम दिनांक (Event Date) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(selDate) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDlgState(() => selDate = picked.toIso8601String().split('T').first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const Icon(Icons.calendar_month, color: AppColors.terracotta, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // End Date (Optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('समाप्ति दिनांक (वैकल्पिक)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      if (selEndDate != null)
                        InkWell(
                          onTap: () => setDlgState(() => selEndDate = null),
                          child: const Text('हटाएं', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(selEndDate ?? selDate) ?? DateTime.now(),
                        firstDate: DateTime.tryParse(selDate) ?? DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDlgState(() => selEndDate = picked.toIso8601String().split('T').first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selEndDate ?? 'समाप्ति दिनांक चुनें (यदि बहु-दिवसीय है)',
                            style: TextStyle(fontSize: 13, color: selEndDate != null ? null : Colors.grey),
                          ),
                          const Icon(Icons.date_range, color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // All Day Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('पूरा दिन (All-Day Event)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    value: isAllDay,
                    onChanged: (val) => setDlgState(() => isAllDay = val),
                  ),

                  // Times (if not all day)
                  if (!isAllDay) ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selStartTime ?? const TimeOfDay(hour: 10, minute: 0),
                              );
                              if (picked != null) {
                                setDlgState(() => selStartTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selStartTime != null ? selStartTime!.format(context) : 'प्रारंभ समय',
                                    style: TextStyle(fontSize: 12, color: selStartTime != null ? null : Colors.grey),
                                  ),
                                  const Icon(Icons.access_time, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selEndTime ?? const TimeOfDay(hour: 22, minute: 0),
                              );
                              if (picked != null) {
                                setDlgState(() => selEndTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selEndTime != null ? selEndTime!.format(context) : 'समाप्ति समय',
                                    style: TextStyle(fontSize: 12, color: selEndTime != null ? null : Colors.grey),
                                  ),
                                  const Icon(Icons.access_time_filled, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Status
                  DropdownButtonFormField<EventStatus>(
                    value: selStatus,
                    items: EventStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                    onChanged: (val) => setDlgState(() => selStatus = val ?? EventStatus.planned),
                    decoration: InputDecoration(
                      labelText: 'कार्यक्रम स्थिति (Status)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Venue & Village/City
                  TextField(
                    controller: venueCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.eventLocation,
                      hintText: 'उदा. शुभ विवाह भवन / होटल राजमहल',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: villageCityCtrl,
                    decoration: InputDecoration(
                      labelText: 'गाँव / शहर / कस्बा',
                      hintText: 'उदा. जयपुर / वाराणसी / बदायूँ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Estimated Budget
                  TextField(
                    controller: budgetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'अनुमानित बजट राशि (Budget Estimate)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.notes,
                      hintText: 'अतिरिक्त विवरण या महत्वपूर्ण निर्देश...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final customCat = customCtrl.text.trim();
                final budgetPaise = (int.tryParse(budgetCtrl.text.trim()) ?? 0) * 100;
                final startTimeStr = selStartTime != null
                    ? '${selStartTime!.hour.toString().padLeft(2, '0')}:${selStartTime!.minute.toString().padLeft(2, '0')}'
                    : null;
                final endTimeStr = selEndTime != null
                    ? '${selEndTime!.hour.toString().padLeft(2, '0')}:${selEndTime!.minute.toString().padLeft(2, '0')}'
                    : null;

                final updated = event.copyWith(
                  title: title,
                  eventType: selType,
                  category: selType == EventType.other && customCat.isNotEmpty ? customCat : null,
                  eventDate: selDate,
                  endDate: selEndDate != null && selEndDate!.isNotEmpty ? selEndDate : null,
                  startTime: startTimeStr,
                  endTime: endTimeStr,
                  isAllDay: isAllDay,
                  status: selStatus,
                  venue: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : null,
                  villageCity: villageCityCtrl.text.trim().isNotEmpty ? villageCityCtrl.text.trim() : null,
                  budgetEstimatedPaise: budgetPaise > 0 ? budgetPaise : null,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  updatedAt: DateTime.now(),
                );

                await ref.read(eventsRepositoryProvider).updateEvent(updated);
                if (selType == EventType.other && customCat.isNotEmpty) {
                  await ref.read(settingsRepositoryProvider).addCustomEventType(customCat);
                }
                Navigator.pop(ctx);
                _triggerRefresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('कार्यक्रम पूर्ण विवरण सफलतापूर्वक अपडेट हुआ')),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFunctionDialog(Event event, EventFunction fn) {
    final fnCtrl = TextEditingController(text: fn.title);
    final venueCtrl = TextEditingController(text: fn.venue ?? '');
    final descCtrl = TextEditingController(text: fn.description ?? '');
    String selDate = fn.functionDate;
    TimeOfDay? selStartTime = fn.startTime != null && fn.startTime!.contains(':')
        ? TimeOfDay(
            hour: int.tryParse(fn.startTime!.split(':')[0]) ?? 0,
            minute: int.tryParse(fn.startTime!.split(':')[1]) ?? 0,
          )
        : null;
    EventStatus selStatus = fn.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('रस्म / उप-कार्यक्रम संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: fnCtrl,
                  decoration: const InputDecoration(labelText: 'रस्म का नाम * (उदा. हल्दी, मेहंदी)'),
                ),
                const SizedBox(height: 12),
                const Text('दिनांक (Date) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(selDate) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDlgState(() => selDate = picked.toIso8601String().split('T').first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.calendar_month, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('समय (Time)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selStartTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setDlgState(() => selStartTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selStartTime != null ? selStartTime!.format(context) : 'समय चुनें (वैकल्पिक)',
                          style: TextStyle(color: selStartTime != null ? null : Colors.grey),
                        ),
                        const Icon(Icons.access_time, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'स्थल (Venue)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'विवरण / निर्देश (वैकल्पिक)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventStatus>(
                  value: selStatus,
                  items: [
                    EventStatus.planned,
                    EventStatus.inProgress,
                    EventStatus.completed,
                    EventStatus.cancelled,
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                  onChanged: (val) => setDlgState(() => selStatus = val ?? EventStatus.planned),
                  decoration: const InputDecoration(labelText: 'स्थिति'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                final title = fnCtrl.text.trim();
                if (title.isEmpty) return;
                final startTimeStr = selStartTime != null
                    ? '${selStartTime!.hour.toString().padLeft(2, '0')}:${selStartTime!.minute.toString().padLeft(2, '0')}'
                    : null;
                final updated = fn.copyWith(
                  title: title,
                  functionDate: selDate,
                  startTime: startTimeStr,
                  venue: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : null,
                  description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                  status: selStatus,
                  updatedAt: DateTime.now(),
                );
                await ref.read(eventsRepositoryProvider).updateFunction(updated);
                Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('सहेजें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(Event event, EventTask task) {
    final tCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description ?? '');
    final personCtrl = TextEditingController(text: task.assignedPersonName ?? '');
    String? dueDate = task.dueDate;
    EventPriority selPriority = task.priority;
    TaskStatus selStatus = task.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('कार्य संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'कार्य शीर्षक *')),
                const SizedBox(height: 10),
                TextField(controller: personCtrl, decoration: const InputDecoration(labelText: 'जिम्मेदार व्यक्ति')),
                const SizedBox(height: 10),
                const Text('अंतिम तिथि (Due Date)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(dueDate ?? event.eventDate) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDlgState(() => dueDate = picked.toIso8601String().split('T').first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dueDate ?? 'तारीख चुनें', style: TextStyle(fontWeight: FontWeight.w600, color: dueDate != null ? null : Colors.grey)),
                        const Icon(Icons.calendar_month, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<EventPriority>(
                  value: selPriority,
                  items: EventPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.labelHindi))).toList(),
                  onChanged: (val) => setDlgState(() => selPriority = val ?? EventPriority.normal),
                  decoration: const InputDecoration(labelText: 'प्राथमिकता (Priority)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskStatus>(
                  value: selStatus,
                  items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                  onChanged: (val) => setDlgState(() => selStatus = val ?? TaskStatus.pending),
                  decoration: const InputDecoration(labelText: 'स्थिति (Status)'),
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'विवरण / निर्देश')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                if (tCtrl.text.trim().isEmpty) return;
                final updated = task.copyWith(
                  title: tCtrl.text.trim(),
                  assignedPersonName: personCtrl.text.trim().isNotEmpty ? personCtrl.text.trim() : null,
                  dueDate: dueDate,
                  priority: selPriority,
                  status: selStatus,
                  description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                  completedAt: selStatus == TaskStatus.completed ? (task.completedAt ?? DateTime.now()) : null,
                );
                await ref.read(eventsRepositoryProvider).updateTask(updated);
                Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('सहेजें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGuestDialog(Event event, EventGuest guest) {
    final nameCtrl = TextEditingController(text: guest.name);
    final phoneCtrl = TextEditingController(text: guest.phoneNumber ?? '');
    final familyCtrl = TextEditingController(text: guest.familyOrGroup ?? '');
    final countCtrl = TextEditingController(text: guest.accompanyingCount.toString());
    final notesCtrl = TextEditingController(text: guest.notes ?? '');
    InvitationStatus selInv = guest.invitationStatus;
    AttendanceStatus selAtt = guest.attendanceStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('अतिथि विवरण संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'नाम *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'फ़ोन नंबर')),
                const SizedBox(height: 10),
                TextField(controller: familyCtrl, decoration: const InputDecoration(labelText: 'परिवार / समूह')),
                const SizedBox(height: 10),
                TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'साथ में आने वाले सदस्य संख्या')),
                const SizedBox(height: 10),
                DropdownButtonFormField<InvitationStatus>(
                  value: selInv,
                  items: InvitationStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                  onChanged: (val) => setDlgState(() => selInv = val ?? InvitationStatus.notSent),
                  decoration: const InputDecoration(labelText: 'निमंत्रण स्थिति'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AttendanceStatus>(
                  value: selAtt,
                  items: AttendanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                  onChanged: (val) => setDlgState(() => selAtt = val ?? AttendanceStatus.notConfirmed),
                  decoration: const InputDecoration(labelText: 'उपस्थिति स्थिति'),
                ),
                const SizedBox(height: 10),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'टिप्पणी')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final updated = guest.copyWith(
                  name: nameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  familyOrGroup: familyCtrl.text.trim().isNotEmpty ? familyCtrl.text.trim() : null,
                  accompanyingCount: int.tryParse(countCtrl.text.trim()) ?? 0,
                  invitationStatus: selInv,
                  attendanceStatus: selAtt,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                );
                await ref.read(eventsRepositoryProvider).updateGuest(updated);
                Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('सहेजें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditParticipantDialog(Event event, EventParticipant p) {
    final nameCtrl = TextEditingController(text: p.name);
    final phoneCtrl = TextEditingController(text: p.phone ?? '');
    final notesCtrl = TextEditingController(text: p.notes ?? '');
    ParticipantRole selRole = p.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('व्यक्ति व भूमिका संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'नाम *')),
              const SizedBox(height: 10),
              DropdownButtonFormField<ParticipantRole>(
                value: selRole,
                items: ParticipantRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.labelHindi))).toList(),
                onChanged: (val) => setDlgState(() => selRole = val ?? ParticipantRole.other),
                decoration: const InputDecoration(labelText: 'भूमिका (Role)'),
              ),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'फ़ोन नंबर')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'नोट्स')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final updated = p.copyWith(
                  name: nameCtrl.text.trim(),
                  role: selRole,
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                );
                await ref.read(eventsRepositoryProvider).updateParticipant(updated);
                Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('सहेजें'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetCategoryDialog(Event event) {
    final nameCtrl = TextEditingController();
    final estCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नई बजट श्रेणी जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'श्रेणी नाम * (उदा. खान-पान, मंडप, उपहार)')),
            const SizedBox(height: 10),
            TextField(controller: estCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अनुमानित बजट राशि (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final estPaise = (int.tryParse(estCtrl.text.trim()) ?? 0) * 100;
                await ref.read(eventsRepositoryProvider).addBudgetCategory(
                      EventBudgetCategory(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        categoryName: nameCtrl.text.trim(),
                        estimatedAmountPaise: estPaise,
                        createdAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showEditBudgetCategoryDialog(Event event, EventBudgetCategory cat) {
    final nameCtrl = TextEditingController(text: cat.categoryName);
    final estCtrl = TextEditingController(
      text: cat.estimatedAmountPaise > 0 ? (cat.estimatedAmountPaise / 100).round().toString() : '',
    );
    final actCtrl = TextEditingController(
      text: cat.actualAmountPaise > 0 ? (cat.actualAmountPaise / 100).round().toString() : '',
    );
    final notesCtrl = TextEditingController(text: cat.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('बजट श्रेणी संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'श्रेणी नाम *')),
            const SizedBox(height: 10),
            TextField(controller: estCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अनुमानित राशि (₹)')),
            const SizedBox(height: 10),
            TextField(controller: actCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'वास्तविक खर्च (₹)')),
            const SizedBox(height: 10),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'नोट्स')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final estPaise = (int.tryParse(estCtrl.text.trim()) ?? 0) * 100;
              final actPaise = (int.tryParse(actCtrl.text.trim()) ?? 0) * 100;
              final updated = cat.copyWith(
                categoryName: nameCtrl.text.trim(),
                estimatedAmountPaise: estPaise,
                actualAmountPaise: actPaise,
                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
              );
              await ref.read(eventsRepositoryProvider).updateBudgetCategory(updated);
              Navigator.pop(ctx);
              _triggerRefresh();
            },
            child: const Text('सहेजें'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(Event event, EventNote note) {
    final titleCtrl = TextEditingController(text: note.title);
    final bodyCtrl = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नोट संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'शीर्षक *')),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'सामग्री व निर्देश *')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty && bodyCtrl.text.trim().isNotEmpty) {
                final updated = note.copyWith(
                  title: titleCtrl.text.trim(),
                  content: bodyCtrl.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await ref.read(eventsRepositoryProvider).updateNote(updated);
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('सहेजें'),
          ),
        ],
      ),
    );
  }

  void _showAddFunctionDialog(Event event) {
    final fnCtrl = TextEditingController();
    final venueCtrl = TextEditingController(text: event.venue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नई रस्म जोड़ें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'रस्म (उदा. हल्दी, मेहंदी)')),
            TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'स्थल')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (fnCtrl.text.trim().isNotEmpty) {
                await ref.read(eventsRepositoryProvider).addFunction(
                      EventFunction(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        title: fnCtrl.text.trim(),
                        functionDate: event.eventDate,
                        venue: venueCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(Event event) {
    final tCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नया कार्य जोड़ें'),
        content: TextField(controller: tCtrl, decoration: const InputDecoration(labelText: 'कार्य विवरण')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (tCtrl.text.trim().isNotEmpty) {
                await ref.read(eventsRepositoryProvider).addTask(
                      EventTask(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        title: tCtrl.text.trim(),
                        dueDate: event.eventDate,
                        createdAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showAddGuestDialog(Event event) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('मेहमान जोड़ें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'नाम *')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'फ़ोन नंबर')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await ref.read(eventsRepositoryProvider).addGuest(
                      EventGuest(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        name: nameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                        invitationStatus: InvitationStatus.sent,
                        attendanceStatus: AttendanceStatus.attending,
                        createdAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantSheet(Event event) {
    final peopleAsync = ref.read(activePeopleListProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('त्रुटि: $e')),
        data: (people) => ListView.builder(
          itemCount: people.length,
          itemBuilder: (context, i) {
            final p = people[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(p.fullName),
              subtitle: Text(p.relationshipLabel ?? ''),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(eventsRepositoryProvider).addParticipant(
                      EventParticipant(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        personId: p.id,
                        name: p.fullName,
                        role: ParticipantRole.familyMember,
                        phone: p.phoneNumber,
                        createdAt: DateTime.now(),
                      ),
                    );
                _triggerRefresh();
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddNoteDialog(Event event) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नया नोट जोड़ें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'शीर्षक')),
            TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'विवरण')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                await ref.read(eventsRepositoryProvider).addNote(
                      EventNote(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        title: titleCtrl.text.trim(),
                        content: bodyCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              }
            },
            child: const Text('जोड़ें'),
          ),
        ],
      ),
    );
  }

  void _showAddReminderDialog(Event event) {
    String preset = '3_days_before';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('अनुस्मारक जोड़ें'),
          content: DropdownButtonFormField<String>(
            value: preset,
            items: const [
              DropdownMenuItem(value: '1_day_before', child: Text('1 दिन पहले (1 Day Before)')),
              DropdownMenuItem(value: '3_days_before', child: Text('3 दिन पहले (3 Days Before)')),
              DropdownMenuItem(value: '7_days_before', child: Text('7 दिन पहले (7 Days Before)')),
              DropdownMenuItem(value: '15_days_before', child: Text('15 दिन पहले (15 Days Before)')),
              DropdownMenuItem(value: '30_days_before', child: Text('30 दिन पहले (30 Days Before)')),
            ],
            onChanged: (val) => setDlgState(() => preset = val ?? '3_days_before'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(eventsRepositoryProvider).addReminder(
                      EventReminder(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        title: '${event.title} - आगामी उत्सव',
                        reminderDate: event.eventDate,
                        preset: preset,
                        createdAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('जोड़ें'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(EventStatus status) {
    switch (status) {
      case EventStatus.confirmed:
      case EventStatus.completed:
        return AppColors.milaGreen;
      case EventStatus.inProgress:
        return const Color(0xFFF59E0B);
      case EventStatus.cancelled:
        return AppColors.diyaRed;
      case EventStatus.draft:
      case EventStatus.archived:
        return Colors.grey;
      case EventStatus.planned:
        return const Color(0xFF38BDF8);
    }
  }
}
