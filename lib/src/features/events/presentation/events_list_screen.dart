import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';

/// Modern Material 3 Screen listing celebratory family events (विवाह, मुंडन, आदि)
/// Fully theme-adaptive with search and tactile spring interactions.
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final eventsAsync = ref.watch(activeEventsListProvider);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.eventsTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: ExpressSquish(
          scale: 0.94,
          onTap: widget.onNewEvent,
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
                  l10n.newEvent,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Box Pill
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.searchEventsHint,
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          // Events List
          Expanded(
            child: eventsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBorder),
                            ),
                            child: Icon(Icons.event_available_outlined, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noEventsFound,
                            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.md,
                    bottom: AppSpacing.floatingTabBottomPadding + 20,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ev = filtered[index];
                    final eventTypeName = l10n.isEnglish ? ev.eventType.name : ev.eventType.labelHindi;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ExpressCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        radius: 16,
                        color: cardBg,
                        borderColor: cardBorder,
                        elevation: 0,
                        onTap: () => widget.onOpenEventDetail?.call(ev.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ev.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    eventTypeName,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 13, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(ev.eventDate, style: TextStyle(color: textSecondary, fontSize: 12)),
                                if (ev.venue != null && ev.venue!.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.location_on_outlined, size: 13, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ev.venue!,
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
