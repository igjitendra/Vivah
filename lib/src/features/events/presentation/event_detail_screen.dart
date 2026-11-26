import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_semantic_colors.dart';
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
  String _guestFilter = 'all';
  String _guestSearchQuery = '';
  final TextEditingController _guestSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _guestSearchCtrl.dispose();
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
            appBar: AppBar(backgroundColor: cardBg),
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
            backgroundColor: cardBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: textPrimary),
            leading: widget.showBackButton
                ? IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
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
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.2,
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
                        color: primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.eventTypeLabel(event.eventType, customCategory: event.category),
                        style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${event.eventDate}',
                      style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w400),
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
                    color: isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, color: textPrimary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'एडिट',
                        style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                onPressed: () => _showFullEditEventDialog(event),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: textPrimary),
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
    final semantic = AppSemanticColors.of(context);
    final totalReceived = linkedEntries
        .where((e) => (e.direction.isReceived) && e.status == TransactionStatus.recorded)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final totalGiven = linkedEntries
        .where((e) => (e.direction.isGiven) && e.status == TransactionStatus.recorded)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final hostParam = (event.hostPersonId != null && event.hostPersonId!.isNotEmpty)
        ? '&personId=${event.hostPersonId}'
        : '';

    final catEstimatedPaise = event.budgetCategories.fold<int>(0, (s, c) => s + c.estimatedAmountPaise);
    final catSpentPaise = event.budgetCategories.fold<int>(0, (s, c) => s + c.actualAmountPaise);
    final effectiveBudgetPaise = (event.budgetEstimatedPaise != null && event.budgetEstimatedPaise! > 0)
        ? event.budgetEstimatedPaise!
        : catEstimatedPaise;
    final effectiveSpentPaise = catSpentPaise > 0 ? catSpentPaise : totalGiven;
    final remainingBudgetPaise = effectiveBudgetPaise - effectiveSpentPaise;
    final sentInvitesCount = event.guests
        .where((g) => g.invitationStatus == InvitationStatus.sent || g.invitationStatus == InvitationStatus.accepted)
        .length;
    final pendingInvitesCount = event.guests.where((g) => g.invitationStatus == InvitationStatus.notSent).length;

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

        // Event Scope & Quick Shagun Strip Card (Own Family vs Relative Event)
        ExpressCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          radius: 16,
          color: cardBg,
          borderColor: cardBorder,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (event.isRelativeEvent ? semantic.info : semantic.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (event.isRelativeEvent ? semantic.info : semantic.primary).withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.isRelativeEvent ? Icons.people_alt_outlined : Icons.home_rounded,
                          size: 15,
                          color: event.isRelativeEvent ? semantic.info : semantic.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.isRelativeEvent ? l10n.relativeEvent : l10n.ownFamilyEvent,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: event.isRelativeEvent ? semantic.info : semantic.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.isRelativeEvent) ...[
                const SizedBox(height: 10),
                if (event.hostPersonName != null && event.hostPersonName!.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: (event.hostPersonId != null && event.hostPersonId!.isNotEmpty)
                        ? () => context.push('/person/${event.hostPersonId}')
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: semantic.cardSubtleBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: semantic.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: semantic.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.selectHostRelative,
                                  style: TextStyle(fontSize: 10.5, color: textSecondary),
                                ),
                                Text(
                                  event.hostPersonName!,
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                          if (event.hostPersonId != null && event.hostPersonId!.isNotEmpty)
                            Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                        ],
                      ),
                    ),
                  ),
                if (event.attendingFamilyNote != null && event.attendingFamilyNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.groups_outlined, size: 16, color: textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.whoWillAttend}: ${event.attendingFamilyNote!}',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: semantic.mila,
                        backgroundColor: semantic.milaContainer,
                        side: BorderSide(color: semantic.milaBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push('/entry/new?direction=received&eventId=${event.id}$hostParam'),
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text(
                        l10n.isEnglish ? '+ Received' : '+ शगुन मिला',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: semantic.diya,
                        backgroundColor: semantic.diyaContainer,
                        side: BorderSide(color: semantic.diyaBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.push('/entry/new?direction=given&eventId=${event.id}$hostParam'),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                      label: Text(
                        l10n.isEnglish ? '+ Given' : '+ शगुन दिया',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // A-to-Z Budget & Expense Live Progress Card (Tap jumps to Budget Tab)
        if (effectiveBudgetPaise > 0 || effectiveSpentPaise > 0) ...[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _tabController.animateTo(5),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 16, color: primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            'बजट व खर्च स्थिति',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            remainingBudgetPaise >= 0
                                ? 'बचा: ${CurrencyUtils.formatPaise(remainingBudgetPaise)}'
                                : 'अधिक: ${CurrencyUtils.formatPaise(remainingBudgetPaise.abs())}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: remainingBudgetPaise >= 0 ? semantic.mila : semantic.diya,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 18, color: textSecondary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: effectiveBudgetPaise > 0
                          ? (effectiveSpentPaise / effectiveBudgetPaise).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 7,
                      backgroundColor: semantic.cardSubtleBg,
                      color: remainingBudgetPaise < 0 ? semantic.diya : semantic.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'खर्च: ${CurrencyUtils.formatPaise(effectiveSpentPaise)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: semantic.diya),
                      ),
                      Text(
                        'बजट: ${CurrencyUtils.formatPaise(effectiveBudgetPaise)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Quick Stats Strip (4 Tappable A-to-Z Pillars)
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tabController.animateTo(4),
                child: _buildMetricCard(
                  title: 'चेकलिस्ट (Tasks)',
                  value: '${event.completedTasksCount}/${event.tasks.length}',
                  subtext: '${event.taskCompletionPercentage.toInt()}% कार्य पूर्ण',
                  color: semantic.secondary,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tabController.animateTo(3),
                child: _buildMetricCard(
                  title: 'मेहमान व निमंत्रण',
                  value: '$sentInvitesCount/${event.guests.length}',
                  subtext: event.guests.isEmpty
                      ? 'निमंत्रण सूची जोड़ें'
                      : '$pendingInvitesCount बाकी • ${event.confirmedGuestCount} आएंगे',
                  color: semantic.info,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tabController.animateTo(5),
                child: _buildMetricCard(
                  title: 'कुल मिला (Mila)',
                  value: CurrencyUtils.formatPaise(totalReceived),
                  subtext: 'शगुन प्राप्त (विवरण देखें)',
                  color: semantic.mila,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _tabController.animateTo(5),
                child: _buildMetricCard(
                  title: 'कुल दिया / खर्च',
                  value: CurrencyUtils.formatPaise(totalGiven),
                  subtext: 'लेन-देन विवरण देखें',
                  color: semantic.diya,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                ),
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
    final semantic = AppSemanticColors.of(context);
    final guests = event.guests;
    final sentCount = guests
        .where((g) => g.invitationStatus == InvitationStatus.sent || g.invitationStatus == InvitationStatus.accepted)
        .length;
    final notSentCount = guests.where((g) => g.invitationStatus == InvitationStatus.notSent).length;
    final attendingCount = guests
        .where((g) => g.attendanceStatus == AttendanceStatus.attending || g.attendanceStatus == AttendanceStatus.attended)
        .length;
    final declinedCount = guests
        .where((g) => g.attendanceStatus == AttendanceStatus.notAttending || g.invitationStatus == InvitationStatus.declined)
        .length;

    final filteredGuests = guests.where((g) {
      if (_guestSearchQuery.isNotEmpty) {
        final match = g.name.toLowerCase().contains(_guestSearchQuery) ||
            (g.phoneNumber ?? '').toLowerCase().contains(_guestSearchQuery) ||
            (g.familyOrGroup ?? '').toLowerCase().contains(_guestSearchQuery) ||
            (g.notes ?? '').toLowerCase().contains(_guestSearchQuery);
        if (!match) return false;
      }
      switch (_guestFilter) {
        case 'sent':
          return g.invitationStatus == InvitationStatus.sent || g.invitationStatus == InvitationStatus.accepted;
        case 'not_sent':
          return g.invitationStatus == InvitationStatus.notSent;
        case 'attending':
          return g.attendanceStatus == AttendanceStatus.attending || g.attendanceStatus == AttendanceStatus.attended;
        case 'declined':
          return g.attendanceStatus == AttendanceStatus.notAttending || g.invitationStatus == InvitationStatus.declined;
        default:
          return true;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Summary Card (Sent vs Pending vs Attending)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: semantic.infoContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: semantic.info.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGuestStat('कुल परिवार', '${guests.length}', textSecondary: textSecondary, color: semantic.info),
                  _buildGuestStat('निमंत्रण गया', '$sentCount', textSecondary: textSecondary, color: semantic.mila),
                  _buildGuestStat('निमंत्रण बाकी', '$notSentCount', textSecondary: textSecondary, color: semantic.warning),
                  _buildGuestStat('कुल सदस्य', '${event.confirmedGuestCount}/${event.totalGuestCount}',
                      textSecondary: textSecondary, color: primaryAccent),
                ],
              ),
              if (guests.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: guests.isEmpty ? 0.0 : (sentCount / guests.length).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: cardBg.withValues(alpha: 0.7),
                    color: semantic.mila,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick Action Buttons: Import from People Directory + Manual Add
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showImportGuestsFromPeopleSheet(event),
                icon: const Icon(Icons.group_add_outlined, size: 17),
                label: const Text('रिश्तेदारों से जोड़ें', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: semantic.onVibrant,
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddGuestDialog(event),
                icon: Icon(Icons.person_add_alt, size: 17, color: primaryAccent),
                label: Text('नया मेहमान', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryAccent)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  side: BorderSide(color: primaryAccent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Secondary Copy / Export Actions (Card text & Who is Sent vs Pending report)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyInvitationToClipboard(event),
                icon: Icon(Icons.card_giftcard_outlined, size: 15, color: textPrimary),
                label: Text('निमंत्रण कार्ड कॉपी', style: TextStyle(fontSize: 11.5, color: textPrimary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  side: BorderSide(color: cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: guests.isEmpty ? null : () => _copyInvitationStatusSummary(event),
                icon: Icon(Icons.checklist_rtl_outlined, size: 15, color: semantic.info),
                label: Text('भेजी/बाकी सूची कॉपी', style: TextStyle(fontSize: 11.5, color: semantic.info)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  side: BorderSide(color: cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Box
        if (guests.isNotEmpty) ...[
          TextField(
            controller: _guestSearchCtrl,
            onChanged: (v) => setState(() => _guestSearchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'मेहमान, फ़ोन या गाँव/परिवार खोजें...',
              prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
              suffixIcon: _guestSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16, color: textSecondary),
                      onPressed: () {
                        _guestSearchCtrl.clear();
                        setState(() => _guestSearchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: semantic.cardSubtleBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Chips (All / Invite Sent / Invite Pending / Attending / Declined)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildGuestFilterChip('सभी (${guests.length})', 'all', primaryAccent, cardBorder, textSecondary),
                _buildGuestFilterChip('निमंत्रण गया ($sentCount)', 'sent', semantic.mila, cardBorder, textSecondary),
                _buildGuestFilterChip('बाकी है ($notSentCount)', 'not_sent', semantic.warning, cardBorder, textSecondary),
                _buildGuestFilterChip('आएंगे ($attendingCount)', 'attending', semantic.info, cardBorder, textSecondary),
                _buildGuestFilterChip('नहीं आएंगे ($declinedCount)', 'declined', semantic.diya, cardBorder, textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (guests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.mail_outline_rounded, size: 40, color: textSecondary.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                Text(
                  'अतिथि एवं निमंत्रण सूची अभी खाली है।',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '"रिश्तेदारों से जोड़ें" दबाकर अपने पूरे रिश्तेदार डेटाबेस से एक साथ मेहमान चुनें और निमंत्रण ट्रैक करें।',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (filteredGuests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('इस फ़िल्टर में कोई मेहमान नहीं मिला।', style: TextStyle(color: textSecondary)),
            ),
          )
        else
          ...filteredGuests.map((g) {
            final isSent = g.invitationStatus == InvitationStatus.sent || g.invitationStatus == InvitationStatus.accepted;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSent ? semantic.milaBorder : cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: (isSent ? semantic.mila : semantic.warning).withValues(alpha: 0.14),
                        child: Text(
                          '${g.accompanyingCount + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: isSent ? semantic.mila : semantic.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showEditGuestDialog(event, g),
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                              if (g.phoneNumber != null && g.phoneNumber!.isNotEmpty ||
                                  g.familyOrGroup != null && g.familyOrGroup!.isNotEmpty)
                                Text(
                                  [
                                    if (g.familyOrGroup != null && g.familyOrGroup!.isNotEmpty) g.familyOrGroup!,
                                    if (g.phoneNumber != null && g.phoneNumber!.isNotEmpty) g.phoneNumber!,
                                  ].join(' • '),
                                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (g.notes != null && g.notes!.isNotEmpty)
                                Text(
                                  g.notes!,
                                  style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.share_outlined, size: 18, color: semantic.info),
                        tooltip: 'व्यक्तिगत निमंत्रण कॉपी',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _copyPersonalizedInvite(event, g),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: primaryAccent),
                        tooltip: 'संपादित करें',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showEditGuestDialog(event, g),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: semantic.diya),
                        tooltip: 'हटाएं',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          await ref.read(eventsRepositoryProvider).deleteGuest(g.id);
                          _triggerRefresh();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // 1-Tap Toggle Invite Sent / Pending
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final nextStatus =
                              g.invitationStatus == InvitationStatus.notSent ? InvitationStatus.sent : InvitationStatus.notSent;
                          await ref.read(eventsRepositoryProvider).updateGuest(
                                g.copyWith(
                                  invitationStatus: nextStatus,
                                  invitationDate: nextStatus == InvitationStatus.sent
                                      ? AppDateUtils.getTodayIsoString()
                                      : g.invitationDate,
                                ),
                              );
                          _triggerRefresh();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSent ? semantic.milaContainer : semantic.warningContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSent ? semantic.milaBorder : semantic.warning.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSent ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                                size: 13.5,
                                color: isSent ? semantic.mila : semantic.warning,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isSent
                                    ? 'निमंत्रण गया (${g.invitationStatus.labelHindi})'
                                    : 'निमंत्रण बाकी • अभी भेजें',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSent ? semantic.mila : semantic.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 1-Tap RSVP / Attendance Picker
                      PopupMenuButton<AttendanceStatus>(
                        padding: EdgeInsets.zero,
                        color: cardBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        initialValue: g.attendanceStatus,
                        onSelected: (att) async {
                          await ref.read(eventsRepositoryProvider).updateGuest(
                                g.copyWith(
                                  attendanceStatus: att,
                                  invitationStatus: att == AttendanceStatus.attending &&
                                          g.invitationStatus == InvitationStatus.notSent
                                      ? InvitationStatus.sent
                                      : g.invitationStatus,
                                ),
                              );
                          _triggerRefresh();
                        },
                        itemBuilder: (_) => AttendanceStatus.values
                            .map((s) => PopupMenuItem<AttendanceStatus>(
                                  value: s,
                                  child: Text(s.labelHindi, style: TextStyle(color: textPrimary, fontSize: 13)),
                                ))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: semantic.cardSubtleBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.how_to_reg_outlined, size: 13.5, color: semantic.info),
                              const SizedBox(width: 4),
                              Text(
                                g.attendanceStatus.labelHindi,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 15, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildGuestFilterChip(
    String label,
    String value,
    Color activeColor,
    Color cardBorder,
    Color textSecondary,
  ) {
    final isSelected = _guestFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _guestFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? activeColor : cardBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestStat(String label, String value, {required Color textSecondary, Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10.5, color: textSecondary)),
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
    final semantic = AppSemanticColors.of(context);
    final totalReceived = linkedEntries
        .where((e) => e.direction.isReceived && e.status == TransactionStatus.recorded)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final totalGiven = linkedEntries
        .where((e) => e.direction.isGiven && e.status == TransactionStatus.recorded)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));
    final hostParam = (event.hostPersonId != null && event.hostPersonId!.isNotEmpty)
        ? '&personId=${event.hostPersonId}'
        : '';

    final catEstimatedPaise = event.budgetCategories.fold<int>(0, (s, c) => s + c.estimatedAmountPaise);
    final catSpentPaise = event.budgetCategories.fold<int>(0, (s, c) => s + c.actualAmountPaise);
    final totalBudgetPaise = (event.budgetEstimatedPaise != null && event.budgetEstimatedPaise! > 0)
        ? event.budgetEstimatedPaise!
        : catEstimatedPaise;
    final effectiveSpentPaise = catSpentPaise > 0 ? catSpentPaise : totalGiven;
    final remainingBudgetPaise = totalBudgetPaise - effectiveSpentPaise;

    // Aggregate expenses by person/vendor from recorded 'given' entries
    final Map<String, ({int amountPaise, int count})> payeeTotals = {};
    for (final e in linkedEntries) {
      if (!e.direction.isGiven || e.status != TransactionStatus.recorded) continue;
      final payee = (e.personName != null && e.personName!.trim().isNotEmpty) ? e.personName!.trim() : 'अन्य / नकद';
      final prev = payeeTotals[payee] ?? (amountPaise: 0, count: 0);
      payeeTotals[payee] = (
        amountPaise: prev.amountPaise + (e.amountPaise ?? 0),
        count: prev.count + 1,
      );
    }
    final sortedPayees = payeeTotals.entries.toList()
      ..sort((a, b) => b.value.amountPaise.compareTo(a.value.amountPaise));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // A-to-Z Budget, Expenses, Remaining & Shagun Overview Card
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
                  Text(
                    'बजट व खर्च सारांश',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (remainingBudgetPaise >= 0 ? semantic.mila : semantic.diya).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      remainingBudgetPaise >= 0
                          ? 'बचा: ${CurrencyUtils.formatPaise(remainingBudgetPaise)}'
                          : 'अधिक: ${CurrencyUtils.formatPaise(remainingBudgetPaise.abs())}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: remainingBudgetPaise >= 0 ? semantic.mila : semantic.diya,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (totalBudgetPaise > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (effectiveSpentPaise / totalBudgetPaise).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: semantic.cardSubtleBg,
                    color: remainingBudgetPaise < 0 ? semantic.diya : primaryAccent,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        CurrencyUtils.formatPaise(totalBudgetPaise),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: primaryAccent),
                      ),
                      Text('कुल बजट', style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: cardBorder),
                  Column(
                    children: [
                      Text(
                        CurrencyUtils.formatPaise(effectiveSpentPaise),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: semantic.diya),
                      ),
                      Text('कुल खर्च', style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                  Container(width: 1, height: 28, color: cardBorder),
                  Column(
                    children: [
                      Text(
                        CurrencyUtils.formatPaise(remainingBudgetPaise.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: remainingBudgetPaise >= 0 ? semantic.mila : semantic.diya,
                        ),
                      ),
                      Text(
                        remainingBudgetPaise >= 0 ? 'शेष बचा' : 'बजट से अधिक',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'शगुन मिला: + ${CurrencyUtils.formatPaise(totalReceived)}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: semantic.mila),
                    ),
                    Text(
                      'दिया (बही-खाता): - ${CurrencyUtils.formatPaise(totalGiven)}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: semantic.diya),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Budget Categories & Expense Tracking ("कहाँ कितना किससे खर्चा किया")
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
                  Expanded(
                    child: Text(
                      'मद / श्रेणीवार खर्च (${event.budgetCategories.length})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBudgetCategoryDialog(event),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('मद जोड़ें', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: semantic.onVibrant,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (event.budgetCategories.isEmpty)
                Text(
                  'कोई खर्च मद नहीं जुड़ी है। टेंट, हलवाई, कपड़े, बाजा, कार्ड आदि जोड़कर जानें कि किस मद में कितना खर्च और कितना शेष है।',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                )
              else
                ...event.budgetCategories.map((cat) {
                  final catRemaining = cat.estimatedAmountPaise - cat.actualAmountPaise;
                  final ratio = cat.estimatedAmountPaise > 0
                      ? (cat.actualAmountPaise / cat.estimatedAmountPaise).clamp(0.0, 1.0)
                      : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: semantic.cardSubtleBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: catRemaining < 0 ? semantic.diyaBorder : cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _showEditBudgetCategoryDialog(event, cat),
                                child: Text(
                                  cat.categoryName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary),
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _showQuickLogCategoryExpenseSheet(event, cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 14, color: primaryAccent),
                                    const SizedBox(width: 2),
                                    Text(
                                      'खर्चा जोड़ें',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryAccent),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 16, color: textSecondary),
                              tooltip: 'संपादित करें',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _showEditBudgetCategoryDialog(event, cat),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 16, color: semantic.diya),
                              tooltip: 'हटाएं',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                await ref.read(eventsRepositoryProvider).deleteBudgetCategory(cat.id);
                                _triggerRefresh();
                              },
                            ),
                          ],
                        ),
                        if (cat.estimatedAmountPaise > 0) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 5,
                              backgroundColor: cardBg,
                              color: catRemaining < 0 ? semantic.diya : semantic.mila,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Text(
                              'बजट: ${CurrencyUtils.formatPaise(cat.estimatedAmountPaise)}',
                              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'खर्च: ${CurrencyUtils.formatPaise(cat.actualAmountPaise)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: semantic.diya),
                            ),
                            Text(
                              catRemaining >= 0
                                  ? 'बचा: ${CurrencyUtils.formatPaise(catRemaining)}'
                                  : 'अधिक: ${CurrencyUtils.formatPaise(catRemaining.abs())}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: catRemaining >= 0 ? semantic.mila : semantic.diya,
                              ),
                            ),
                          ],
                        ),
                        if (cat.notes != null && cat.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cardBorder.withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.storefront_outlined, size: 14, color: semantic.info),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'कहाँ / किसको: ${cat.notes!}',
                                    style: TextStyle(fontSize: 11, color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        // Payee / Vendor Summary ("किससे / किसको कितना दिया")
        if (sortedPayees.isNotEmpty) ...[
          const SizedBox(height: 14),
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
                Text(
                  'किसको / कहाँ कितना दिया (${sortedPayees.length})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                ),
                const SizedBox(height: 8),
                ...sortedPayees.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person_pin_circle_outlined, size: 16, color: semantic.diya),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${entry.key} (${entry.value.count})',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ),
                          Text(
                            CurrencyUtils.formatPaise(entry.value.amountPaise),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: semantic.diya),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Action Buttons: Add Shagun/Expense Entry Directly + PDF
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/entry/new?direction=given&eventId=${event.id}$hostParam'),
                icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                label: const Text('दिया / खर्चा जोड़ें', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: semantic.diya,
                  foregroundColor: semantic.onVibrant,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/entry/new?direction=received&eventId=${event.id}$hostParam'),
                icon: const Icon(Icons.arrow_downward_rounded, size: 17),
                label: const Text('शगुन मिला जोड़ें', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: semantic.mila,
                  foregroundColor: semantic.onVibrant,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(Icons.picture_as_pdf_outlined, color: primaryAccent),
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
              padding: const EdgeInsets.all(24),
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
                              '${AppDateUtils.formatIsoDate(e.transactionDate, l10n.locale.languageCode)}${e.notes != null && e.notes!.isNotEmpty ? " • ${e.notes!}" : ""}',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                              maxLines: 2,
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
                          color: e.direction.isReceived ? semantic.mila : semantic.diya,
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

  void _copyPersonalizedInvite(Event event, EventGuest guest) {
    final text = StringBuffer();
    text.writeln('सादर नमस्ते ${guest.name} जी,');
    text.writeln('आप सपरिवार हमारे कार्यक्रम "${event.title}" में सादर आमंत्रित हैं।');
    text.writeln('दिनांक: ${event.eventDate}');
    if (event.startTime != null && event.startTime!.isNotEmpty) text.writeln('समय: ${event.startTime}');
    if (event.venue != null && event.venue!.isNotEmpty) text.writeln('स्थल: ${event.venue}');
    if (event.mapLink != null && event.mapLink!.isNotEmpty) text.writeln('लोकेशन: ${event.mapLink}');
    text.writeln('कृपया समय पर पधारकर हमें अनुग्रहीत करें।');

    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${guest.name} के लिए व्यक्तिगत निमंत्रण कॉपी किया गया')),
    );
  }

  void _copyInvitationStatusSummary(Event event) {
    final sent = event.guests
        .where((g) => g.invitationStatus == InvitationStatus.sent || g.invitationStatus == InvitationStatus.accepted)
        .toList();
    final pending = event.guests.where((g) => g.invitationStatus == InvitationStatus.notSent).toList();
    final buf = StringBuffer();
    buf.writeln('${event.title} — निमंत्रण सूची (${event.guests.length})');
    buf.writeln('');
    buf.writeln('निमंत्रण भेजा गया (${sent.length}):');
    if (sent.isEmpty) {
      buf.writeln('- अभी कोई नहीं');
    } else {
      for (final g in sent) {
        buf.writeln('- ${g.name}${g.familyOrGroup != null && g.familyOrGroup!.isNotEmpty ? " (${g.familyOrGroup})" : ""}');
      }
    }
    buf.writeln('');
    buf.writeln('निमंत्रण भेजना बाकी (${pending.length}):');
    if (pending.isEmpty) {
      buf.writeln('- सभी को निमंत्रण जा चुका है');
    } else {
      for (final g in pending) {
        buf.writeln('- ${g.name}${g.familyOrGroup != null && g.familyOrGroup!.isNotEmpty ? " (${g.familyOrGroup})" : ""}');
      }
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('भेजी गई व बाकी निमंत्रण सूची कॉपी की गई')),
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
    final hostNameCtrl = TextEditingController(text: event.hostPersonName ?? '');
    final attendingCtrl = TextEditingController(text: event.attendingFamilyNote ?? '');
    EventScope selScope = event.eventScope;
    String? selHostPersonId = event.hostPersonId;
    final peopleList = [...(ref.read(activePeopleListProvider).value ?? const <Person>[])]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    if (selHostPersonId != null && !peopleList.any((p) => p.id == selHostPersonId)) {
      selHostPersonId = null;
    }
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

                  // Event Scope (Own Family vs Relative Event)
                  Text(
                    l10n.isEnglish ? 'Event Category' : 'आयोजन की श्रेणी',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              l10n.ownFamilyEvent,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: selScope == EventScope.ownFamily,
                          onSelected: (_) => setDlgState(() => selScope = EventScope.ownFamily),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              l10n.relativeEvent,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: selScope == EventScope.relative,
                          onSelected: (_) => setDlgState(() => selScope = EventScope.relative),
                        ),
                      ),
                    ],
                  ),
                  if (selScope == EventScope.relative) ...[
                    const SizedBox(height: 12),
                    if (peopleList.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        value: selHostPersonId,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.isEnglish ? 'Select from People (Optional)' : 'रिश्तेदार सूची से चुनें (वैकल्पिक)'),
                          ),
                          ...peopleList.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text(
                                '${p.fullName}${p.relationshipLabel != null && p.relationshipLabel!.isNotEmpty ? " (${p.relationshipLabel})" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) => setDlgState(() {
                          selHostPersonId = val;
                          if (val != null) {
                            final match = peopleList.where((p) => p.id == val).firstOrNull;
                            if (match != null) {
                              hostNameCtrl.text = match.fullName;
                            }
                          }
                        }),
                        decoration: InputDecoration(
                          labelText: l10n.selectHostRelative,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: hostNameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.isEnglish ? 'Host Relative Name' : 'मेज़बान रिश्तेदार का नाम',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: attendingCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.whoWillAttend,
                        hintText: l10n.entireFamily,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
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
                  eventScope: selScope,
                  clearHostInfo: selScope == EventScope.ownFamily,
                  hostPersonId: selScope == EventScope.relative ? selHostPersonId : null,
                  hostPersonName: selScope == EventScope.relative && hostNameCtrl.text.trim().isNotEmpty
                      ? hostNameCtrl.text.trim()
                      : null,
                  attendingFamilyNote: selScope == EventScope.relative && attendingCtrl.text.trim().isNotEmpty
                      ? attendingCtrl.text.trim()
                      : null,
                  updatedAt: DateTime.now(),
                );

                await ref.read(eventsRepositoryProvider).updateEvent(updated);
                if (selType == EventType.other && customCat.isNotEmpty) {
                  await ref.read(settingsRepositoryProvider).addCustomEventType(customCat);
                }
                if (ctx.mounted) Navigator.pop(ctx);
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
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        titleCtrl.dispose();
        venueCtrl.dispose();
        villageCityCtrl.dispose();
        budgetCtrl.dispose();
        notesCtrl.dispose();
        customCtrl.dispose();
        hostNameCtrl.dispose();
        attendingCtrl.dispose();
      });
    });
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
    final spentCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    const presets = [
      'टेंट व सजावट',
      'खान-पान / हलवाई',
      'कपड़े व आभूषण',
      'बाजा / DJ',
      'कार्ड व निमंत्रण',
      'वाहन / बारात',
      'पंडित व पूजा',
      'मिठाई व उपहार',
      'फोटोग्राफी',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('नई खर्च मद / श्रेणी जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('त्वरित चुनें:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((p) {
                      final active = nameCtrl.text.trim() == p;
                      return ChoiceChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        selected: active,
                        onSelected: (_) => setDlgState(() => nameCtrl.text = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'मद / श्रेणी नाम *'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: estCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'अनुमानित बजट (₹)', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: spentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'अभी तक खर्च (वैकल्पिक ₹)', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vendorCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'कहाँ / किसको / दुकान या व्यक्ति का नाम',
                      hintText: 'उदा. शर्मा टेंट हाउस, अग्रिम भुगतान ₹5,000',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final estPaise = (int.tryParse(estCtrl.text.trim()) ?? 0) * 100;
                final actPaise = (int.tryParse(spentCtrl.text.trim()) ?? 0) * 100;
                await ref.read(eventsRepositoryProvider).addBudgetCategory(
                      EventBudgetCategory(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        categoryName: nameCtrl.text.trim(),
                        estimatedAmountPaise: estPaise,
                        actualAmountPaise: actPaise,
                        notes: vendorCtrl.text.trim().isNotEmpty ? vendorCtrl.text.trim() : null,
                        createdAt: DateTime.now(),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('सहेजें'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        nameCtrl.dispose();
        estCtrl.dispose();
        spentCtrl.dispose();
        vendorCtrl.dispose();
      });
    });
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
        title: const Text('खर्च मद संपादित करें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'मद नाम *')),
              const SizedBox(height: 10),
              TextField(controller: estCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'अनुमानित बजट (₹)', prefixText: '₹ ')),
              const SizedBox(height: 10),
              TextField(controller: actCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'कुल खर्च (₹)', prefixText: '₹ ')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'कहाँ / किसको / विवरण')),
            ],
          ),
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
              if (ctx.mounted) Navigator.pop(ctx);
              _triggerRefresh();
            },
            child: const Text('सहेजें'),
          ),
        ],
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        nameCtrl.dispose();
        estCtrl.dispose();
        actCtrl.dispose();
        notesCtrl.dispose();
      });
    });
  }

  void _showQuickLogCategoryExpenseSheet(Event event, EventBudgetCategory cat) {
    final amountCtrl = TextEditingController();
    final vendorCtrl = TextEditingController();
    final people = [...(ref.read(activePeopleListProvider).value ?? const <Person>[])]
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    String? selectedPersonId;
    bool recordLedgerEntry = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('${cat.categoryName} — खर्चा जोड़ें', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'खर्च राशि (₹) *',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: vendorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'कहाँ / किसको दिया (दुकान, हलवाई या व्यक्ति)',
                      hintText: 'उदा. रामू हलवाई / टेंट वाले',
                    ),
                  ),
                  if (people.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      value: selectedPersonId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('बही-खाता व्यक्ति से लिंक न करें (वैकल्पिक)'),
                        ),
                        ...people.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.fullName, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (val) => setDlgState(() {
                        selectedPersonId = val;
                        recordLedgerEntry = val != null;
                        if (val != null && vendorCtrl.text.trim().isEmpty) {
                          final match = people.where((p) => p.id == val).firstOrNull;
                          if (match != null) vendorCtrl.text = match.fullName;
                        }
                      }),
                      decoration: const InputDecoration(labelText: 'व्यक्ति / रिश्तेदार चुनें (बही-खाता हेतु)'),
                    ),
                    if (selectedPersonId != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('मुख्य बही-खाता (Diya) में भी दर्ज करें', style: TextStyle(fontSize: 12.5)),
                        value: recordLedgerEntry,
                        onChanged: (v) => setDlgState(() => recordLedgerEntry = v),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                final rupees = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (rupees <= 0) return;
                final addedPaise = rupees * 100;
                final vendor = vendorCtrl.text.trim();
                final logLine = vendor.isNotEmpty
                    ? '$vendor (₹$rupees)'
                    : '₹$rupees';
                final nextNotes = (cat.notes != null && cat.notes!.trim().isNotEmpty)
                    ? '${cat.notes!.trim()} • $logLine'
                    : logLine;

                await ref.read(eventsRepositoryProvider).updateBudgetCategory(
                      cat.copyWith(
                        actualAmountPaise: cat.actualAmountPaise + addedPaise,
                        notes: nextNotes,
                      ),
                    );

                if (recordLedgerEntry && selectedPersonId != null) {
                  final now = DateTime.now();
                  await ref.read(entriesRepositoryProvider).saveEntryWithItemsAtomic(
                        entry: TransactionEntry(
                          id: const Uuid().v4(),
                          personId: selectedPersonId!,
                          eventId: event.id,
                          direction: TransactionDirection.given,
                          transactionType: TransactionType.cash,
                          status: TransactionStatus.recorded,
                          amountPaise: addedPaise,
                          transactionDate: AppDateUtils.getTodayIsoString(),
                          notes: '${cat.categoryName}${vendor.isNotEmpty ? " • $vendor" : ""}',
                          createdAt: now,
                          updatedAt: now,
                          recordedAt: now,
                        ),
                        items: const [],
                      );
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('खर्च जोड़ें'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        amountCtrl.dispose();
        vendorCtrl.dispose();
      });
    });
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

  void _showImportGuestsFromPeopleSheet(Event event) {
    final peopleAsync = ref.read(activePeopleListProvider);
    final semantic = AppSemanticColors.of(context);
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final searchCtrl = TextEditingController();
    String searchQuery = '';
    final Set<String> selectedPersonIds = <String>{};
    InvitationStatus initialInvStatus = InvitationStatus.notSent;
    bool onlyUninvited = true;

    final existingGuestsByPersonId = <String, EventGuest>{};
    final existingGuestsByName = <String, EventGuest>{};
    for (final g in event.guests) {
      if (g.personId != null && g.personId!.isNotEmpty) {
        existingGuestsByPersonId[g.personId!] = g;
      }
      existingGuestsByName[g.name.trim().toLowerCase()] = g;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.5,
            maxChildSize: 0.94,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: semantic.cardBorder, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'रिश्तेदारों से निमंत्रण सूची बनाएं',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                            Text(
                              'चुनें कि किस-किस को बुलाना है और निमंत्रण गया या नहीं',
                              style: TextStyle(fontSize: 11.5, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (v) => setSheetState(() => searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'नाम, गाँव या रिश्ता खोजें...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      filled: true,
                      fillColor: semantic.cardSubtleBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('अभी भेजना बाकी', style: TextStyle(fontSize: 11)),
                          selected: initialInvStatus == InvitationStatus.notSent,
                          onSelected: (_) => setSheetState(() => initialInvStatus = InvitationStatus.notSent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('निमंत्रण भेज दिया', style: TextStyle(fontSize: 11)),
                          selected: initialInvStatus == InvitationStatus.sent,
                          onSelected: (_) => setSheetState(() => initialInvStatus = InvitationStatus.sent),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilterChip(
                        label: const Text('केवल जिन्हें अभी नहीं जोड़ा', style: TextStyle(fontSize: 11)),
                        selected: onlyUninvited,
                        onSelected: (v) => setSheetState(() => onlyUninvited = v),
                      ),
                      peopleAsync.maybeWhen(
                        data: (people) {
                          final addable = people.where((p) {
                            final alreadyAdded = existingGuestsByPersonId.containsKey(p.id) ||
                                existingGuestsByName.containsKey(p.fullName.trim().toLowerCase());
                            if (alreadyAdded) return false;
                            if (searchQuery.isEmpty) return true;
                            return p.fullName.toLowerCase().contains(searchQuery) ||
                                (p.village ?? '').toLowerCase().contains(searchQuery) ||
                                (p.relationshipLabel ?? '').toLowerCase().contains(searchQuery);
                          }).toList();
                          final allChecked = addable.isNotEmpty && addable.every((p) => selectedPersonIds.contains(p.id));
                          return TextButton(
                            onPressed: addable.isEmpty
                                ? null
                                : () => setSheetState(() {
                                      if (allChecked) {
                                        for (final p in addable) {
                                          selectedPersonIds.remove(p.id);
                                        }
                                      } else {
                                        for (final p in addable) {
                                          selectedPersonIds.add(p.id);
                                        }
                                      }
                                    }),
                            child: Text(allChecked ? 'सब हटाएं' : 'सभी चुनें (${addable.length})', style: const TextStyle(fontSize: 12)),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: peopleAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('त्रुटि: $e')),
                    data: (people) {
                      final sorted = [...people]..sort((a, b) => a.fullName.compareTo(b.fullName));
                      final filtered = sorted.where((p) {
                        final alreadyAdded = existingGuestsByPersonId.containsKey(p.id) ||
                            existingGuestsByName.containsKey(p.fullName.trim().toLowerCase());
                        if (onlyUninvited && alreadyAdded) return false;
                        if (searchQuery.isEmpty) return true;
                        return p.fullName.toLowerCase().contains(searchQuery) ||
                            (p.village ?? '').toLowerCase().contains(searchQuery) ||
                            (p.relationshipLabel ?? '').toLowerCase().contains(searchQuery) ||
                            (p.phoneNumber ?? '').toLowerCase().contains(searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'सभी उपलब्ध रिश्तेदार पहले ही सूची में जुड़े हैं या खोज से मेल नहीं खाते।',
                              style: TextStyle(color: textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollCtrl,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final existing = existingGuestsByPersonId[p.id] ?? existingGuestsByName[p.fullName.trim().toLowerCase()];
                          final alreadyAdded = existing != null;
                          final isSelected = selectedPersonIds.contains(p.id);
                          final subtitleParts = <String>[];
                          if (p.relationshipLabel != null && p.relationshipLabel!.isNotEmpty) {
                            subtitleParts.add(p.relationshipLabel!);
                          }
                          if (p.village != null && p.village!.isNotEmpty) subtitleParts.add(p.village!);
                          if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) subtitleParts.add(p.phoneNumber!);

                          return CheckboxListTile(
                            value: alreadyAdded ? true : isSelected,
                            onChanged: alreadyAdded
                                ? null
                                : (val) => setSheetState(() {
                                      if (val == true) {
                                        selectedPersonIds.add(p.id);
                                      } else {
                                        selectedPersonIds.remove(p.id);
                                      }
                                    }),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.fullName,
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
                                  ),
                                ),
                                if (alreadyAdded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (existing.invitationStatus == InvitationStatus.sent ||
                                              existing.invitationStatus == InvitationStatus.accepted)
                                          ? semantic.milaContainer
                                          : semantic.warningContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      existing.invitationStatus.labelHindi,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: (existing.invitationStatus == InvitationStatus.sent ||
                                                existing.invitationStatus == InvitationStatus.accepted)
                                            ? semantic.mila
                                            : semantic.warning,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: subtitleParts.isNotEmpty
                                ? Text(subtitleParts.join(' • '), style: TextStyle(fontSize: 11.5, color: textSecondary))
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selectedPersonIds.isEmpty
                            ? null
                            : () async {
                                final people = ref.read(activePeopleListProvider).value ?? const <Person>[];
                                final repo = ref.read(eventsRepositoryProvider);
                                final today = AppDateUtils.getTodayIsoString();
                                for (final p in people) {
                                  if (!selectedPersonIds.contains(p.id)) continue;
                                  final groupLabel = (p.village != null && p.village!.trim().isNotEmpty)
                                      ? p.village!.trim()
                                      : p.relationshipLabel;
                                  await repo.addGuest(
                                    EventGuest(
                                      id: const Uuid().v4(),
                                      eventId: event.id,
                                      personId: p.id,
                                      name: p.fullName,
                                      familyOrGroup: groupLabel,
                                      phoneNumber: p.phoneNumber,
                                      invitationStatus: initialInvStatus,
                                      attendanceStatus: AttendanceStatus.notConfirmed,
                                      invitationDate: initialInvStatus == InvitationStatus.sent ? today : null,
                                      createdAt: DateTime.now(),
                                    ),
                                  );
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                _triggerRefresh();
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          selectedPersonIds.isEmpty
                              ? 'मेहमान चुनें'
                              : '${selectedPersonIds.length} रिश्तेदार सूची में जोड़ें',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: semantic.onVibrant,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), searchCtrl.dispose);
    });
  }

  void _showAddGuestDialog(Event event) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final familyCtrl = TextEditingController();
    final extraCountCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();
    InvitationStatus selInv = InvitationStatus.notSent;
    AttendanceStatus selAtt = AttendanceStatus.notConfirmed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('नया मेहमान जोड़ें', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'मेहमान / परिवार मुखिया का नाम *')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'फ़ोन नंबर')),
                  const SizedBox(height: 8),
                  TextField(controller: familyCtrl, decoration: const InputDecoration(labelText: 'गाँव / परिवार / समूह')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: extraCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'अतिरिक्त परिवार सदस्य संख्या (स्वयं के अलावा)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<InvitationStatus>(
                    value: selInv,
                    items: InvitationStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                    onChanged: (v) => setDlgState(() => selInv = v ?? InvitationStatus.notSent),
                    decoration: const InputDecoration(labelText: 'निमंत्रण स्थिति (गया / नहीं गया)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AttendanceStatus>(
                    value: selAtt,
                    items: AttendanceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.labelHindi))).toList(),
                    onChanged: (v) => setDlgState(() => selAtt = v ?? AttendanceStatus.notConfirmed),
                    decoration: const InputDecoration(labelText: 'उपस्थिति स्थिति (RSVP)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'नोट्स / विशेष विवरण')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(eventsRepositoryProvider).addGuest(
                      EventGuest(
                        id: const Uuid().v4(),
                        eventId: event.id,
                        name: nameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                        familyOrGroup: familyCtrl.text.trim().isNotEmpty ? familyCtrl.text.trim() : null,
                        accompanyingCount: int.tryParse(extraCountCtrl.text.trim()) ?? 0,
                        invitationStatus: selInv,
                        attendanceStatus: selAtt,
                        invitationDate: selInv == InvitationStatus.sent ? AppDateUtils.getTodayIsoString() : null,
                        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        createdAt: DateTime.now(),
                      ),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                _triggerRefresh();
              },
              child: const Text('जोड़ें'),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        nameCtrl.dispose();
        phoneCtrl.dispose();
        familyCtrl.dispose();
        extraCountCtrl.dispose();
        notesCtrl.dispose();
      });
    });
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
