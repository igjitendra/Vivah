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

/// Bahi Khata / Ledger Screen (Fully Localized, Zero Hardcoded Strings)
class LedgerScreen extends ConsumerStatefulWidget {
  final VoidCallback onNewEntry;
  final ValueChanged<String>? onOpenEntryDetail;

  const LedgerScreen({
    super.key,
    required this.onNewEntry,
    this.onOpenEntryDetail,
  });

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  TransactionDirection? _selectedDirection;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entriesAsync = ref.watch(entriesListProvider(_selectedDirection));

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.ledgerTitle,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: widget.onNewEntry,
          backgroundColor: AppColors.terracotta,
          icon: const Icon(Icons.add, color: AppColors.white),
          label: Text(l10n.newTransaction, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.white,
            child: Row(
              children: [
                _buildFilterChip(l10n.all, _selectedDirection == null, () {
                  setState(() => _selectedDirection = null);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('↓ ${l10n.received}', _selectedDirection == TransactionDirection.received, () {
                  setState(() => _selectedDirection = TransactionDirection.received);
                }, activeColor: AppColors.milaGreen),
                const SizedBox(width: 8),
                _buildFilterChip('↑ ${l10n.given}', _selectedDirection == TransactionDirection.given, () {
                  setState(() => _selectedDirection = TransactionDirection.given);
                }, activeColor: AppColors.diyaRed),
              ],
            ),
          ),

          // Search Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.searchLedgerHint,
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

          // Entries List
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err')),
              data: (entries) {
                final filtered = entries.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  final matchName = (e.personName ?? '').toLowerCase().contains(_searchQuery);
                  final matchVillage = (e.personAddress ?? '').toLowerCase().contains(_searchQuery);
                  final matchEvent = (e.eventTitle ?? '').toLowerCase().contains(_searchQuery);
                  return matchName || matchVillage || matchEvent;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noTransactionsFound,
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 16),
                    ),
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
                    final entry = filtered[index];
                    return _buildEntryCard(context, entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? AppColors.terracotta;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardBorder,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, TransactionEntry entry) {
    final l10n = context.l10n;
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
        onTap: () => widget.onOpenEntryDetail?.call(entry.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.personName ?? l10n.unknownPerson,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                  ),
                  DirectionBadge(direction: entry.direction),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.personRelationship ?? ''} • ${entry.personAddress ?? ''}',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
                  Text(
                    entry.amountPaise != null ? CurrencyUtils.formatPaise(entry.amountPaise!) : l10n.giftItem,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: entry.direction.value == 'received' ? AppColors.milaGreen : AppColors.diyaRed,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.celebration_outlined, size: 14, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        entry.eventTitle ?? l10n.generalEvent,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.mutedText),
                      const SizedBox(width: 4),
                      Text(
                        entry.transactionDate,
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
              if (entry.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: entry.items.map((i) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warmCream,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard, size: 12, color: AppColors.terracotta),
                          const SizedBox(width: 4),
                          Text(
                            i.itemName,
                            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
