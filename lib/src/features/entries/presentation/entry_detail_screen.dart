import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/direction_badge.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Screen displaying complete details for a single transaction entry.
/// Fully theme-adaptive with Material 3 cards and tactile feedback.
class EntryDetailScreen extends ConsumerWidget {
  final String entryId;

  const EntryDetailScreen({
    super.key,
    required this.entryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.transactionDetails,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: l10n.deleteTransaction,
            onPressed: () => _confirmArchiveEntry(context, ref, l10n, cardBg, textPrimary, primaryAccent),
          ),
        ],
      ),
      body: FutureBuilder<TransactionEntry?>(
        future: entriesRepo.getEntryById(entryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final entry = snapshot.data;
          if (entry == null) {
            return Center(child: Text(l10n.noTransactionsFound, style: TextStyle(color: textPrimary)));
          }

          final isReceived = entry.direction == TransactionDirection.received;
          final accentColor = isReceived ? AppColors.milaGreen : AppColors.diyaRed;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Amount & Direction Card
              ExpressCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                radius: 18,
                color: cardBg,
                borderColor: cardBorder,
                elevation: 1,
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
                                ? AppColors.milaGreen.withValues(alpha: 0.15)
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
                                  ? AppColors.milaGreen
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
                      style: TextStyle(fontSize: 14, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Relative & Event Association Card
              ExpressCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                radius: 16,
                color: cardBg,
                borderColor: cardBorder,
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: primaryAccent.withValues(alpha: 0.18),
                        child: Icon(Icons.person, color: primaryAccent),
                      ),
                      title: Text(
                        entry.personName ?? l10n.unknownPerson,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                      ),
                      subtitle: Text(
                        entry.personRelationship ?? l10n.relativeDefault,
                        style: TextStyle(color: textSecondary),
                      ),
                      trailing: Icon(Icons.chevron_right, color: textSecondary),
                      onTap: () => context.push('/person/${entry.personId}'),
                    ),
                    if (entry.eventId != null) ...[
                      Divider(color: cardBorder),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: primaryAccent.withValues(alpha: 0.18),
                          child: Icon(Icons.event, color: primaryAccent),
                        ),
                        title: Text(
                          entry.eventTitle ?? l10n.eventsTitle,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                        ),
                        subtitle: Text(l10n.familyEvent, style: TextStyle(color: textSecondary)),
                        trailing: Icon(Icons.chevron_right, color: textSecondary),
                        onTap: () => context.push('/event/${entry.eventId}'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date & Mode Card
              ExpressCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                radius: 16,
                color: cardBg,
                borderColor: cardBorder,
                elevation: 0,
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: l10n.transactionDate,
                      value: VyavahaarDateUtils.formatIsoDate(entry.transactionDate, l10n.locale.languageCode),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    Divider(height: 20, color: cardBorder),
                    _DetailRow(
                      icon: Icons.category,
                      label: l10n.type,
                      value: entry.transactionType == TransactionType.cash
                          ? l10n.cash
                          : (entry.transactionType == TransactionType.item
                              ? l10n.itemOnly
                              : l10n.cashAndItem),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      Divider(height: 20, color: cardBorder),
                      _DetailRow(
                        icon: Icons.note_outlined,
                        label: l10n.notes,
                        value: entry.notes!,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),

              // Physical Gift Items List (if any)
              if (entry.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
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
                          Icon(Icons.card_giftcard, size: 20, color: primaryAccent),
                          const SizedBox(width: 8),
                          Text(
                            l10n.giftItemsWithCount(entry.items.length),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
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
                                    style: TextStyle(fontSize: 14, color: textPrimary)),
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
              ],

              // Actions for Planned Transactions
              if (entry.isPlanned) ...[
                const SizedBox(height: AppSpacing.lg),
                ExpressSquish(
                  scale: 0.96,
                  onTap: () async {
                    await entriesRepo.markPlannedEntryRecorded(entry.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.markedRecordedSuccess), backgroundColor: AppColors.milaGreen),
                      );
                      context.pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.milaGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          l10n.markRecorded,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ExpressSquish(
                  scale: 0.96,
                  onTap: () async {
                    await entriesRepo.cancelPlannedEntry(entry.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.planCancelledSuccess)),
                      );
                      context.pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          l10n.cancelPlan,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
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
              await ref.read(entriesRepositoryProvider).archiveEntry(entryId);
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: textSecondary),
        const SizedBox(width: 12),
        Column(
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
      ],
    );
  }
}
