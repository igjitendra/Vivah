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

/// Transaction Detail & Actions Screen
/// Fully theme-adaptive with status actions and soft archiving.
class EntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  int _refreshKey = 0;

  void _showEditTransactionDialog(BuildContext context, TransactionEntry entry, AppLocalizations l10n) {
    final amountRupees = entry.amountPaise != null ? (entry.amountPaise! / 100).round().toString() : '';
    final amountController = TextEditingController(text: amountRupees);
    final notesController = TextEditingController(text: entry.notes ?? '');
    String selectedDate = entry.transactionDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editTransaction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.transactionType == TransactionType.cash || entry.transactionType == TransactionType.cashAndItem) ...[
                  Text(l10n.amountRupees, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(l10n.transactionDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                final raw = int.tryParse(amountController.text.trim()) ?? 0;
                final paise = raw > 0 ? CurrencyUtils.rupeesToPaise(raw) : entry.amountPaise;

                final repo = ref.read(entriesRepositoryProvider);
                final updated = TransactionEntry(
                  id: entry.id,
                  personId: entry.personId,
                  eventId: entry.eventId,
                  direction: entry.direction,
                  transactionType: entry.transactionType,
                  status: entry.status,
                  amountPaise: paise,
                  transactionDate: selectedDate,
                  notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  createdAt: entry.createdAt,
                  updatedAt: DateTime.now(),
                  items: entry.items,
                );

                await repo.updateEntryWithItemsAtomic(entry: updated, items: entry.items);

                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() => _refreshKey++);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.transactionUpdatedSuccess), backgroundColor: AppColors.milaGreen),
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

  void _confirmArchiveEntry(BuildContext context, WidgetRef ref, AppLocalizations l10n, Color cardBg, Color textPrimary, Color primaryAccent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.confirmDeleteTransactionTitle, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: Text(l10n.confirmDeleteTransaction, style: TextStyle(color: textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(entriesRepositoryProvider).archiveEntry(widget.entryId);
              if (context.mounted) {
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
        title: Text(
          l10n.transactionDetails,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<TransactionEntry?>(
        future: entriesRepo.getEntryById(widget.entryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final entry = snapshot.data;
          if (entry == null) {
            return Center(child: Text(l10n.noTransactionsFound, style: TextStyle(color: textPrimary)));
          }

          final isReceived = entry.direction == TransactionDirection.received;
          final accentColor = isReceived ? AppColors.forestGreen : AppColors.terracotta;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Amount & Direction Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: cardBg,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DirectionBadge(direction: entry.direction),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.isCompleted
                                      ? AppColors.forestGreen.withValues(alpha: 0.12)
                                      : (entry.isPlanned ? Colors.amber.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.isCompleted
                                      ? l10n.statusRecorded
                                      : (entry.isPlanned ? l10n.statusPlanned : l10n.statusCancelled),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: entry.isCompleted
                                        ? AppColors.forestGreen
                                        : (entry.isPlanned ? Colors.amber.shade800 : Colors.red.shade800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 20, color: textSecondary),
                                tooltip: l10n.editTransaction,
                                onPressed: () => _showEditTransactionDialog(context, entry, l10n),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                tooltip: l10n.deleteTransaction,
                                onPressed: () => _confirmArchiveEntry(context, ref, l10n, cardBg, textPrimary, primaryAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        entry.amountPaise != null
                            ? CurrencyUtils.formatPaiseToRupees(entry.amountPaise!)
                            : l10n.itemOnly,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: entry.amountPaise != null ? accentColor : textPrimary,
                        ),
                      ),
                      if (entry.items.isNotEmpty && entry.amountPaise != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.cashAndItem,
                          style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Relative / Person Information
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: cardBg,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: primaryAccent.withValues(alpha: 0.15),
                          child: Icon(Icons.person, color: primaryAccent),
                        ),
                        title: Text(
                          entry.personName ?? l10n.unknownPerson,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                        ),
                        subtitle: Text(
                          '${entry.personRelationship ?? l10n.relativeDefault} • ${entry.personAddress ?? l10n.villageUnknown}',
                          style: TextStyle(color: textSecondary),
                        ),
                        trailing: Icon(Icons.chevron_right, color: textSecondary),
                        onTap: () => context.push('/people/${entry.personId}'),
                      ),
                      if (entry.personPhone != null) ...[
                        const Divider(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: AppColors.mutedText),
                            const SizedBox(width: 8),
                            Text(entry.personPhone!, style: TextStyle(color: textSecondary, fontSize: 14)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Transaction Meta Details
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: cardBg,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: l10n.transactionDate,
                        value: VyavahaarDateUtils.formatIsoDate(entry.transactionDate, l10n.locale.languageCode),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.category,
                        label: l10n.type,
                        value: entry.transactionType == TransactionType.cash
                            ? l10n.cash
                            : (entry.transactionType == TransactionType.item ? l10n.giftItem : l10n.cashAndItem),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      if (entry.eventId != null) ...[
                        const Divider(height: 20),
                        InkWell(
                          onTap: () => context.push('/events/${entry.eventId}'),
                          child: _DetailRow(
                            icon: Icons.celebration,
                            label: l10n.tabEvents,
                            value: entry.eventTitle ?? l10n.generalEvent,
                            trailing: Icon(Icons.chevron_right, size: 18, color: textSecondary),
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        ),
                      ],
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.notes,
                          label: l10n.notes,
                          value: entry.notes!,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Attached Physical Items
              if (entry.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  color: cardBg,
                  child: Container(
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
                            Icon(Icons.card_giftcard, size: 20, color: primaryAccent),
                            const SizedBox(width: 8),
                            Text(
                              l10n.giftItemsWithCount(entry.items.length),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...entry.items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${it.itemName} (${it.quantity} ${it.unit ?? ""})',
                                    style: TextStyle(fontSize: 14, color: textPrimary),
                                  ),
                                  if (it.estimatedValuePaise != null)
                                    Text(
                                      '${l10n.estimated}: ${CurrencyUtils.formatPaiseToRupees(it.estimatedValuePaise!)}',
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                    ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],

              // Actions for Planned Transactions
              if (entry.isPlanned) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: AppColors.white),
                  label: Text(
                    l10n.markRecorded,
                    style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await entriesRepo.markPlannedEntryRecorded(entry.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.markedRecordedSuccess)),
                      );
                      context.pop();
                    }
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                    l10n.cancelPlan,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await entriesRepo.cancelPlannedEntry(entry.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.planCancelledSuccess)),
                      );
                      context.pop();
                    }
                  },
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
