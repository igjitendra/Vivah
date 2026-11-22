import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/direction_badge.dart';
import '../../../shared/widgets/express_squish.dart';

/// Person Profile & Personal Ledger History Screen
/// Fully theme-adaptive with Mila/Diya balance passbook and transaction stream.
class PersonDetailScreen extends ConsumerWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final peopleRepo = ref.watch(peopleRepositoryProvider);
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
        title: Text(l10n.personDetails, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Person?>(
        future: peopleRepo.getPersonById(personId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryAccent));
          }
          final person = snapshot.data;
          if (person == null) {
            return Center(child: Text(l10n.personNotFound, style: TextStyle(color: textPrimary)));
          }

          return FutureBuilder<Map<String, int>>(
            future: entriesRepo.getPersonHistoryStats(personId),
            builder: (context, statsSnap) {
              final stats = statsSnap.data ?? {'received_paise': 0, 'given_paise': 0};
              final receivedPaise = stats['received_paise'] ?? 0;
              final givenPaise = stats['given_paise'] ?? 0;

              return Column(
                children: [
                  // Person Header Card
                  Container(
                    width: double.infinity,
                    color: headerBg,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${person.relationshipLabel ?? l10n.relativeDefault} • ${person.address ?? l10n.villageUnknown}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                        ),
                        if (person.phoneNumber != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                person.phoneNumber!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Balance Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.milaGreen.withValues(alpha: isDark ? 0.25 : 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.milaGreen.withValues(alpha: 0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.totalReceived, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyUtils.formatPaise(receivedPaise),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.diyaRed.withValues(alpha: isDark ? 0.25 : 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.diyaRed.withValues(alpha: 0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.totalGiven, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyUtils.formatPaise(givenPaise),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // History Heading
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18, color: primaryAccent),
                        const SizedBox(width: 8),
                        Text(l10n.personHistory, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
                      ],
                    ),
                  ),

                  // Entries Stream
                  Expanded(
                    child: StreamBuilder<List<TransactionEntry>>(
                      stream: entriesRepo.watchEntries(personId: personId),
                      builder: (context, entrySnap) {
                        if (entrySnap.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: primaryAccent));
                        }
                        final entries = entrySnap.data ?? [];
                        if (entries.isEmpty) {
                          return Center(child: Text(l10n.noTransactionsForPerson, style: TextStyle(color: textSecondary)));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: entries.length,
                          itemBuilder: (context, idx) {
                            final e = entries[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ExpressCard(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                radius: 14,
                                color: cardBg,
                                borderColor: cardBorder,
                                elevation: 0,
                                child: Row(
                                  children: [
                                    DirectionBadge(direction: e.direction),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.amountPaise != null ? CurrencyUtils.formatPaise(e.amountPaise!) : l10n.giftItem,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: e.direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${e.eventTitle ?? l10n.generalEvent} • ${e.transactionDate}',
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (e.items.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.card_giftcard, size: 15, color: textSecondary),
                                          const SizedBox(width: 4),
                                          Text('${e.items.length}', style: TextStyle(color: textSecondary, fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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
