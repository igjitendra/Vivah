import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../app/app_providers.dart';

/// Modern Material 3 Card-Based Ledger / Bahi-Khata Screen
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
  final TextEditingController _searchController = TextEditingController();
  TransactionDirection? _selectedDirection;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entriesAsync = ref.watch(entriesListProvider(_selectedDirection));

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.ledgerTitle,
          style: const TextStyle(
            color: AppColors.surfaceWhite,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: FloatingActionButton.extended(
          onPressed: widget.onNewEntry,
          backgroundColor: AppColors.terracotta,
          elevation: 3,
          icon: const Icon(Icons.add_card, color: AppColors.surfaceWhite, size: 20),
          label: Text(
            l10n.newTransaction,
            style: const TextStyle(color: AppColors.surfaceWhite, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips & Search Bar Header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
            ),
            child: Column(
              children: [
                // 1. Material 3 Search Bar Pill
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmCream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l10n.searchLedgerHint,
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.deepNavy, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Filter Segment Chips Row
                Row(
                  children: [
                    _buildFilterChip(
                      label: l10n.all,
                      isSelected: _selectedDirection == null,
                      onTap: () => setState(() => _selectedDirection = null),
                      icon: Icons.filter_list,
                      activeColor: AppColors.deepNavy,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.received,
                      isSelected: _selectedDirection == TransactionDirection.received,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.received),
                      icon: Icons.arrow_downward,
                      activeColor: AppColors.milaGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.given,
                      isSelected: _selectedDirection == TransactionDirection.given,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.given),
                      icon: Icons.arrow_upward,
                      activeColor: AppColors.diyaRed,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entries List View
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
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noTransactionsFound,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracotta,
                              foregroundColor: AppColors.surfaceWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            onPressed: widget.onNewEntry,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.newTransaction),
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
                    bottom: AppSpacing.floatingTabBottomPadding,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _buildTransactionCard(context, entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color activeColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.borderLight,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppColors.surfaceWhite : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.surfaceWhite : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionEntry entry) {
    final l10n = context.l10n;
    final isReceived = entry.direction == TransactionDirection.received;
    final themeColor = isReceived ? AppColors.milaGreen : AppColors.diyaRed;
    final themeSoftColor = isReceived ? AppColors.milaGreenSoft : AppColors.diyaRedSoft;

    final personName = entry.personName ?? l10n.unknownPerson;
    final initial = personName.isNotEmpty ? personName.characters.first : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 0,
      color: AppColors.surfaceWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onOpenEntryDetail?.call(entry.id),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Direction Avatar with initials & arrow badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: themeSoftColor,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.md),

              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.personRelationship ?? l10n.relativeDefault}${entry.personAddress != null && entry.personAddress!.isNotEmpty ? ' • ${entry.personAddress}' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.eventTitle != null && entry.eventTitle!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.warmCream,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration_outlined, size: 10, color: AppColors.terracotta),
                                const SizedBox(width: 3),
                                Text(
                                  entry.eventTitle!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          VyavahaarDateUtils.formatIsoDate(entry.transactionDate),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Amount & Items Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.amountPaise != null
                        ? CurrencyUtils.formatPaise(entry.amountPaise!)
                        : l10n.giftItem,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: themeColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (entry.items.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.warmCream,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard, size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            '${entry.items.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (entry.isPlanned) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.plannedAmberSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.statusPlanned,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.plannedAmber),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
