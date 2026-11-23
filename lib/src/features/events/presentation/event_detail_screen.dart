import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Event Details Screen (कार्यक्रम विवरण एवं लेन-देन सूची)
/// Fully theme-adaptive with celebration summary, event editing, and transaction timeline.
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

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  int _refreshKey = 0;

  void _showEditEventDialog(BuildContext context, Event event, AppLocalizations l10n) {
    final titleController = TextEditingController(text: event.title);
    final venueController = TextEditingController(text: event.venue ?? '');
    final notesController = TextEditingController(text: event.notes ?? '');
    EventType selectedType = event.eventType;
    String selectedDate = event.eventDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editEvent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.eventType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<EventType>(
                  value: selectedType,
                  items: EventType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.labelHindi))).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val ?? EventType.other),
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.eventDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(selectedDate) ?? now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked.toIso8601String().split('T').first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.calendar_month, size: 18, color: AppColors.terracotta),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.eventLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: venueController,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.notes, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final repo = ref.read(eventsRepositoryProvider);
                final updated = Event(
                  id: event.id,
                  title: title,
                  eventType: selectedType,
                  eventDate: selectedDate,
                  venue: venueController.text.trim().isNotEmpty ? venueController.text.trim() : null,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  createdAt: event.createdAt,
                  updatedAt: DateTime.now(),
                );

                await repo.updateEvent(updated);

                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.eventUpdatedSuccess), backgroundColor: AppColors.milaGreen),
                  );
                }
              },
              child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchiveEvent(BuildContext context, WidgetRef ref, AppLocalizations l10n, Color cardBg, Color textPrimary, Color primaryAccent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.confirmDeleteEventTitle, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text(l10n.confirmDeleteEventBody, style: TextStyle(color: textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventsRepositoryProvider).archiveEvent(widget.eventId);
              if (widget.onClose != null) {
                widget.onClose!();
              } else if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventsRepo = ref.watch(eventsRepositoryProvider);
    final entriesRepo = ref.watch(entriesRepositoryProvider);
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      key: ValueKey(_refreshKey),
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          l10n.eventDetails,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
              tooltip: l10n.close,
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ExpressSquish(
          scale: 0.94,
          onTap: () => context.push('/entry/new?eventId=${widget.eventId}'),
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
                  l10n.recordNewTransaction,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<Event?>(
        future: eventsRepo.getEventById(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final event = snapshot.data;
          if (event == null) {
            return Center(child: Text(l10n.eventNotFound, style: TextStyle(color: textPrimary)));
          }

          return StreamBuilder<List<TransactionEntry>>(
            stream: entriesRepo.watchEntries(eventId: widget.eventId),
            builder: (context, entriesSnap) {
              final entries = entriesSnap.data ?? [];

              // Calculate ceremony totals
              int receivedPaise = 0;
              int givenPaise = 0;
              for (final e in entries) {
                if (e.amountPaise != null) {
                  if (e.direction == TransactionDirection.received) {
                    receivedPaise += e.amountPaise!;
                  } else {
                    givenPaise += e.amountPaise!;
                  }
                }
              }

              return Column(
                children: [
                  // Event Header Card
                  Container(
                    width: double.infinity,
                    color: headerBg,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                              tooltip: l10n.editEvent,
                              onPressed: () => _showEditEventDialog(context, event, l10n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                              tooltip: l10n.deleteEvent,
                              onPressed: () => _confirmArchiveEvent(context, ref, l10n, cardBg, textPrimary, primaryAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                event.eventType.labelHindi,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              VyavahaarDateUtils.formatIsoDate(event.eventDate, l10n.locale.languageCode),
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (event.venue != null && event.venue!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.terracotta),
                              const SizedBox(width: 4),
                              Text(
                                event.venue!,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        if (event.notes != null && event.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            event.notes!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Event Stats Passbook
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryBox(
                            title: l10n.totalReceived,
                            amountPaise: receivedPaise,
                            accentColor: AppColors.forestGreen,
                            icon: Icons.south_west_rounded,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textSecondary: textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SummaryBox(
                            title: l10n.totalGiven,
                            amountPaise: givenPaise,
                            accentColor: AppColors.diyaRed,
                            icon: Icons.north_east_rounded,
                            cardBg: cardBg,
                            cardBorder: cardBorder,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List Heading
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.transactions,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          '${entries.length} ${l10n.items}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transactions Timeline
                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.noTransactionsFound,
                                  style: TextStyle(color: textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 80),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = entries[index];
                              return ExpressCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                radius: 14,
                                color: cardBg,
                                borderColor: cardBorder,
                                elevation: 0,
                                onTap: () => context.push('/entry/${item.id}'),
                                child: Row(
                                  children: [
                                    DirectionBadge(direction: item.direction),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.personName ?? l10n.unknownPerson,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${VyavahaarDateUtils.formatIsoDate(item.transactionDate, l10n.locale.languageCode)}${item.items.isNotEmpty ? ' • ${item.items.length} ${l10n.items}' : ''}',
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      item.amountPaise != null
                                          ? CurrencyUtils.formatPaiseToRupees(item.amountPaise!)
                                          : l10n.giftItem,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: item.direction == TransactionDirection.received
                                            ? AppColors.forestGreen
                                            : AppColors.diyaRed,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final int amountPaise;
  final Color accentColor;
  final IconData icon;
  final Color cardBg;
  final Color cardBorder;
  final Color textSecondary;

  const _SummaryBox({
    required this.title,
    required this.amountPaise,
    required this.accentColor,
    required this.icon,
    required this.cardBg,
    required this.cardBorder,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyUtils.formatPaiseToRupees(amountPaise),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
