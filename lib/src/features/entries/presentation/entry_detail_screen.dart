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
class EntryDetailScreen extends ConsumerWidget {
  final String entryId;

  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesRepo = ref.watch(entriesRepositoryProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.transactionDetails,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            tooltip: l10n.deleteTransaction,
            onPressed: () => _confirmArchiveEntry(context, ref, l10n),
          ),
        ],
      ),
      body: FutureBuilder<TransactionEntry?>(
        future: entriesRepo.getEntryById(entryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
          }
          final entry = snapshot.data;
          if (entry == null) {
            return Center(child: Text(l10n.noTransactionsFound));
          }

          final isReceived = entry.direction == TransactionDirection.received;
          final accentColor = isReceived ? AppColors.forestGreen : AppColors.terracotta;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Amount & Direction Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: accentColor, width: 6)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DirectionBadge(direction: entry.direction),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: entry.isCompleted
                                  ? AppColors.forestGreen.withValues(alpha: 0.1)
                                  : (entry.isPlanned ? Colors.amber.shade100 : Colors.red.shade100),
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
                                    : (entry.isPlanned ? Colors.amber.shade900 : Colors.red.shade800),
                              ),
                            ),
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
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReceived ? l10n.received : l10n.given,
                        style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Relative & Event Association Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.sand,
                          child: Icon(Icons.person, color: AppColors.deepNavy),
                        ),
                        title: Text(
                          entry.personName ?? l10n.unknownPerson,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          entry.personRelationship ?? l10n.relativeDefault,
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                        onTap: () => context.push('/person/${entry.personId}'),
                      ),
                      if (entry.eventId != null) ...[
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.sand,
                            child: Icon(Icons.event, color: AppColors.deepNavy),
                          ),
                          title: Text(
                            entry.eventTitle ?? l10n.eventsTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(l10n.familyEvent, style: const TextStyle(color: AppColors.mutedText)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                          onTap: () => context.push('/event/${entry.eventId}'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date & Mode Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: l10n.transactionDate,
                        value: VyavahaarDateUtils.formatIsoDate(entry.transactionDate),
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        icon: Icons.category,
                        label: l10n.type,
                        value: entry.transactionType == TransactionType.cash
                            ? l10n.cash
                            : (entry.transactionType == TransactionType.item
                                ? l10n.itemOnly
                                : l10n.cashAndItem),
                      ),
                      if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                        const Divider(height: 20),
                        _DetailRow(
                          icon: Icons.note_outlined,
                          label: l10n.notes,
                          value: entry.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Physical Gift Items List (if any)
              if (entry.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard, size: 20, color: AppColors.deepNavy),
                            const SizedBox(width: 8),
                            Text(
                              l10n.giftItemsWithCount(entry.items.length),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...entry.items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${it.itemName} (${it.quantity.toInt()} ${it.unit ?? ''})',
                                      style: const TextStyle(fontSize: 14)),
                                  if (it.estimatedValuePaise != null)
                                    Text(
                                      '${l10n.estimated}: ${CurrencyUtils.formatPaiseToRupees(it.estimatedValuePaise!)}',
                                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
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

  void _confirmArchiveEntry(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTransactionTitle),
        content: Text(l10n.confirmDeleteTransaction),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(entriesRepositoryProvider).archiveEntry(entryId);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.mutedText),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkSlate),
            ),
          ],
        ),
      ],
    );
  }
}
