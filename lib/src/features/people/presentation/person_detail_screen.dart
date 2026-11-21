import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/direction_badge.dart';

/// Person Profile & Personal Ledger History Screen
class PersonDetailScreen extends ConsumerWidget {
  final String personId;

  const PersonDetailScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleRepo = ref.watch(peopleRepositoryProvider);
    final entriesRepo = ref.watch(entriesRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('व्यक्ति विवरण व हिसाब', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      body: FutureBuilder<Person?>(
        future: peopleRepo.getPersonById(personId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
          }
          final person = snapshot.data;
          if (person == null) {
            return const Center(child: Text('व्यक्ति नहीं मिला'));
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
                    color: AppColors.deepNavy,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${person.relationshipLabel ?? 'रिश्तेदार'} • ${person.address ?? 'गाँव अज्ञात'}',
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                        ),
                        if (person.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📞 ${person.phoneNumber}',
                            style: const TextStyle(color: AppColors.white, fontSize: 13),
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
                                  color: AppColors.milaGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.milaGreen),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('कुल मिला (Received)', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                                  color: AppColors.diyaRed.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.diyaRed),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('कुल दिया (Given)', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                      children: const [
                        Icon(Icons.history, size: 18, color: AppColors.deepNavy),
                        SizedBox(width: 8),
                        Text('लेन-देन का इतिहास (Transaction History)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),

                  // Entries Stream
                  Expanded(
                    child: StreamBuilder<List<TransactionEntry>>(
                      stream: entriesRepo.watchEntries(personId: personId),
                      builder: (context, entrySnap) {
                        if (entrySnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
                        }
                        final entries = entrySnap.data ?? [];
                        if (entries.isEmpty) {
                          return const Center(child: Text('इस व्यक्ति के साथ अभी कोई व्यवहार दर्ज नहीं है'));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: entries.length,
                          itemBuilder: (context, idx) {
                            final e = entries[idx];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: DirectionBadge(direction: e.direction),
                                title: Text(
                                  e.amountPaise != null ? CurrencyUtils.formatPaise(e.amountPaise!) : 'भेंट',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: e.direction == TransactionDirection.received ? AppColors.milaGreen : AppColors.diyaRed,
                                  ),
                                ),
                                subtitle: Text('${e.eventTitle ?? 'सामान्य'} • ${e.transactionDate}'),
                                trailing: e.items.isNotEmpty ? Text('🎁 ${e.items.length}') : null,
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
