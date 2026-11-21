import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';
import '../../../app/app_providers.dart';

/// Events Management Screen (Fully Localized, Zero Hardcoding)
class EventsListScreen extends ConsumerStatefulWidget {
  final VoidCallback onNewEvent;
  final ValueChanged<String>? onOpenEventDetail;

  const EventsListScreen({
    super.key,
    required this.onNewEvent,
    this.onOpenEventDetail,
  });

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eventsAsync = ref.watch(activeEventsListProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.eventsTitle,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: widget.onNewEvent,
          backgroundColor: AppColors.terracotta,
          icon: const Icon(Icons.add, color: AppColors.white),
          label: Text(l10n.newEvent, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.searchEventsHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
                filled: true,
                fillColor: AppColors.warmCream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Events List
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err')),
              data: (events) {
                final filtered = events.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  final typeLabel = l10n.isEnglish ? e.eventType.name : e.eventType.labelHindi;
                  return e.title.toLowerCase().contains(_searchQuery) ||
                      (e.venue ?? '').toLowerCase().contains(_searchQuery) ||
                      typeLabel.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(l10n.noEventsFound, style: const TextStyle(color: AppColors.mutedText, fontSize: 16)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: AppSpacing.floatingTabBottomPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ev = filtered[index];
                    final eventTypeName = l10n.isEnglish ? ev.eventType.name : ev.eventType.labelHindi;

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      elevation: 0,
                      color: AppColors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => widget.onOpenEventDetail?.call(ev.id),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ev.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warmCream,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      eventTypeName,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mutedText),
                                  const SizedBox(width: 4),
                                  Text(ev.eventDate, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                                  if (ev.venue != null && ev.venue!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.mutedText),
                                    const SizedBox(width: 4),
                                    Text(ev.venue!, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
