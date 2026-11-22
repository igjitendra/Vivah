import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_squish.dart';
import '../providers/ledger_providers.dart';

/// Modern Material 3 Ledger (बही) Screen
/// Fully theme-adaptive with search pill, direction segment filters, and tactile cards.
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
    final entriesAsync = ref.watch(entriesListProvider(_selectedDirection));

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.ledgerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: headerBg,
        elevation: 0,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75),
        child: ExpressSquish(
          scale: 0.94,
          onTap: widget.onNewEntry,
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
                const Icon(Icons.add_card, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.newTransaction,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips & Search Bar Header
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Column(
              children: [
                // 1. Material 3 Search Bar Pill
                Container(
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
                      hintText: l10n.searchLedgerHint,
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

                const SizedBox(height: 8),

                // 2. Filter Segment Chips Row
                Row(
                  children: [
                    _buildFilterChip(
                      label: l10n.all,
                      isSelected: _selectedDirection == null,
                      onTap: () => setState(() => _selectedDirection = null),
                      icon: Icons.filter_list,
                      activeColor: isDark ? const Color(0xFF38BDF8) : headerBg,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.received,
                      isSelected: _selectedDirection == TransactionDirection.received,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.received),
                      icon: Icons.arrow_downward,
                      activeColor: AppColors.milaGreen,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: l10n.given,
                      isSelected: _selectedDirection == TransactionDirection.given,
                      onTap: () => setState(() => _selectedDirection = TransactionDirection.given),
                      icon: Icons.arrow_upward,
                      activeColor: AppColors.diyaRed,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Transactions List View
          Expanded(
            child: entriesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    '${l10n.errorGeneric}: $err',
                    style: const TextStyle(color: AppColors.diyaRed),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (entries) {
                // Apply Search Query filter
                final filtered = entries.where((e) {
                  if (_searchQuery.isEmpty) return true;
                  final name = e.personName?.toLowerCase() ?? '';
                  final village = e.personAddress?.toLowerCase() ?? '';
                  final event = e.eventTitle?.toLowerCase() ?? '';
                  final notes = e.notes?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      village.contains(_searchQuery) ||
                      event.contains(_searchQuery) ||
                      notes.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: cardBorder),
                            ),
                            child: Icon(Icons.receipt_long_outlined, size: 48, color: textSecondary.withValues(alpha: 0.6)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? l10n.noResultsFound : l10n.noEntriesYet,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty ? l10n.tryDifferentSearch : l10n.recordFirstTransaction,
                            style: TextStyle(fontSize: 13, color: textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 16),
                            ExpressSquish(
                              scale: 0.95,
                              onTap: widget.onNewEntry,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: primaryAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.newTransaction,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.floatingTabBottomPadding + 20,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _buildTransactionCard(
                      context,
                      entry,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      searchBg: searchBg,
                      isDark: isDark,
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color activeColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Expanded(
      child: ExpressSquish(
        scale: 0.94,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionEntry entry, {
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color searchBg,
    required bool isDark,
  }) {
    final l10n = context.l10n;
    final isReceived = entry.direction == TransactionDirection.received;
    final themeColor = isReceived ? AppColors.milaGreen : AppColors.diyaRed;
    final themeSoftColor = isReceived
        ? (isDark ? const Color(0xFF1B3D27) : AppColors.milaGreenSoft)
        : (isDark ? const Color(0xFF451E22) : AppColors.diyaRedSoft);

    final personName = entry.personName ?? l10n.unknownPerson;
    final initial = personName.isNotEmpty ? personName.characters.first : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: ExpressCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        radius: 16,
        color: cardBg,
        borderColor: cardBorder,
        elevation: 0,
        onTap: () => widget.onOpenEntryDetail?.call(entry.id),
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
                      border: Border.all(color: cardBg, width: 1.5),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.personRelationship ?? l10n.relativeDefault}${entry.personAddress != null && entry.personAddress!.isNotEmpty ? ' • ${entry.personAddress}' : ''}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
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
                            color: searchBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration_outlined, size: 10, color: themeColor),
                              const SizedBox(width: 3),
                              Text(
                                entry.eventTitle!,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        VyavahaarDateUtils.formatIsoDate(entry.transactionDate, l10n.locale.languageCode),
                        style: TextStyle(fontSize: 11, color: textSecondary),
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
                      color: searchBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard, size: 11, color: textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${entry.items.length}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
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
                      color: isDark ? const Color(0xFF3B2912) : AppColors.plannedAmberSoft,
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
    );
  }
}
