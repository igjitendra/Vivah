import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';
import '../../../shared/widgets/direction_badge.dart';

/// Event Details Screen (कार्यक्रम विवरण एवं लेन-देन सूची)
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsRepo = ref.watch(eventsRepositoryProvider);
    final entriesRepo = ref.watch(entriesRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'कार्यक्रम विवरण',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            tooltip: 'कार्यक्रम हटाएं',
            onPressed: () => _confirmArchiveEvent(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/entry/new?eventId=$eventId'),
        backgroundColor: AppColors.terracotta,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text(
          'व्यवहार दर्ज करें',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Event?>(
        future: eventsRepo.getEventById(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            );
          }
          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('कार्यक्रम नहीं मिला'));
          }

          return StreamBuilder<List<TransactionEntry>>(
            stream: entriesRepo.watchEntries(eventId: eventId),
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
                    color: AppColors.deepNavy,
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold, width: 1),
                              ),
                              child: Text(
                                event.eventType.displayName,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              VyavahaarDateUtils.formatIsoDate(event.eventDate),
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (event.venue != null && event.venue!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.mutedText),
                              const SizedBox(width: 4),
                              Text(
                                event.venue!,
                                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        if (event.notes != null && event.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            event.notes!,
                            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Event Stats Cards (Received vs Given - Never Netted)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryBox(
                            title: 'कुल मिला (Received)',
                            amountPaise: receivedPaise,
                            accentColor: AppColors.forestGreen,
                            icon: Icons.south_west,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryBox(
                            title: 'कुल दिया (Given)',
                            amountPaise: givenPaise,
                            accentColor: AppColors.terracotta,
                            icon: Icons.north_east,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'व्यवहार प्रविष्टियां (Transactions)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkSlate),
                        ),
                        Text(
                          'कुल: ${entries.length}',
                          style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Transactions List
                  Expanded(
                    child: entries.isEmpty
                        ? const Center(
                            child: Text(
                              'इस कार्यक्रम में कोई प्रविष्टि नहीं है।',
                              style: TextStyle(color: AppColors.mutedText),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, 80),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = entries[index];
                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 1,
                                child: ListTile(
                                  onTap: () => context.push('/entry/${item.id}'),
                                  leading: DirectionBadge(direction: item.direction),
                                  title: Text(
                                    item.personName ?? 'अज्ञात व्यक्ति',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${VyavahaarDateUtils.formatIsoDate(item.transactionDate)}${item.items.isNotEmpty ? ' • ${item.items.length} सामान' : ''}',
                                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                                  ),
                                  trailing: Text(
                                    item.amountPaise != null
                                        ? CurrencyUtils.formatPaiseToRupees(item.amountPaise!)
                                        : 'भेंट / सामान',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: item.direction == TransactionDirection.received
                                          ? AppColors.forestGreen
                                          : AppColors.terracotta,
                                    ),
                                  ),
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

  void _confirmArchiveEvent(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('कार्यक्रम हटाएं?'),
        content: const Text('क्या आप वाकई इस कार्यक्रम को हटाना चाहते हैं? इसके लेन-देन सुरक्षित रहेंगे।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(eventsRepositoryProvider).archiveEvent(eventId);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('हटाएं', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final int amountPaise;
  final Color accentColor;
  final IconData icon;

  const _SummaryBox({
    required this.title,
    required this.amountPaise,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w600),
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
