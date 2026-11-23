import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../services/pdf_service.dart';
import '../services/csv_service.dart';

/// Screen offering Visual Insights & Analytics, PDF Ledger Printing (A4), and Excel/CSV Export
/// Fully theme-adaptive with tactile ExpressCard design.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entriesAsync = ref.watch(entriesListProvider(null));
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
        title: Text(l10n.insightsTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isGenerating
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : entriesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: primaryAccent)),
              error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err', style: const TextStyle(color: Colors.red))),
              data: (entries) {
                // 1. Calculate Analytics
                final recordedEntries = entries.where((e) => e.status == TransactionStatus.recorded && e.archivedAt == null).toList();
                final receivedEntries = recordedEntries.where((e) => e.direction == TransactionDirection.received || e.direction == TransactionDirection.mila).toList();
                final givenEntries = recordedEntries.where((e) => e.direction == TransactionDirection.given || e.direction == TransactionDirection.diya).toList();

                final totalReceived = receivedEntries.fold<int>(0, (sum, e) => sum + (e.amountPaise ?? 0));
                final totalGiven = givenEntries.fold<int>(0, (sum, e) => sum + (e.amountPaise ?? 0));

                // Top 3 Transactions
                final topReceived = List<TransactionEntry>.from(receivedEntries)
                  ..sort((a, b) => (b.amountPaise ?? 0).compareTo(a.amountPaise ?? 0));
                final topGiven = List<TransactionEntry>.from(givenEntries)
                  ..sort((a, b) => (b.amountPaise ?? 0).compareTo(a.amountPaise ?? 0));

                // Event Breakdown
                final Map<String, List<TransactionEntry>> eventMap = {};
                for (final e in recordedEntries) {
                  final key = e.eventTitle != null && e.eventTitle!.isNotEmpty ? e.eventTitle! : 'सामान्य (General)';
                  eventMap.putIfAbsent(key, () => []).add(e);
                }

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // A. Summary Analytics Section
                    Row(
                      children: [
                        // Received Summary
                        Expanded(
                          child: ExpressCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            radius: 16,
                            color: isDark ? const Color(0xFF132A1C) : AppColors.milaGreenSoft,
                            borderColor: isDark ? const Color(0xFF1B4D2E) : const Color(0xFFB7E4C7),
                            elevation: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward, size: 16, color: AppColors.milaGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.totalReceived,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.milaGreen),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyUtils.formatPaise(totalReceived),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.milaGreen),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${receivedEntries.length} ${l10n.items}',
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2D6A4F)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Given Summary
                        Expanded(
                          child: ExpressCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            radius: 16,
                            color: isDark ? const Color(0xFF331616) : AppColors.diyaRedSoft,
                            borderColor: isDark ? const Color(0xFF5C2424) : const Color(0xFFF7C5C0),
                            elevation: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, size: 16, color: AppColors.diyaRed),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.totalGiven,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.diyaRed),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyUtils.formatPaise(totalGiven),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.diyaRed),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${givenEntries.length} ${l10n.items}',
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // B. Top Shagun Transactions Card
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
                              Icon(Icons.workspace_premium, size: 18, color: primaryAccent),
                              const SizedBox(width: 6),
                              Text(
                                l10n.topTransactions,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          // Top Received Item
                          if (topReceived.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.milaGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('↓ ${l10n.topReceived}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.milaGreen)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${topReceived.first.personName ?? ""}${topReceived.first.eventTitle != null ? " (${topReceived.first.eventTitle})" : ""}',
                                    style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.formatPaise(topReceived.first.amountPaise ?? 0),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.milaGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Top Given Item
                          if (topGiven.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.diyaRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('↑ ${l10n.topGiven}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.diyaRed)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${topGiven.first.personName ?? ""}${topGiven.first.eventTitle != null ? " (${topGiven.first.eventTitle})" : ""}',
                                    style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  CurrencyUtils.formatPaise(topGiven.first.amountPaise ?? 0),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.diyaRed),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // C. Event Breakdown Card
                    if (eventMap.isNotEmpty) ...[
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
                                const Icon(Icons.celebration_outlined, size: 18, color: AppColors.terracotta),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.eventBreakdown,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            ...eventMap.entries.take(4).map((entry) {
                              final eventEntries = entry.value;
                              final eMila = eventEntries.where((e) => e.direction == TransactionDirection.received || e.direction == TransactionDirection.mila).fold<int>(0, (s, e) => s + (e.amountPaise ?? 0));
                              final eDiya = eventEntries.where((e) => e.direction == TransactionDirection.given || e.direction == TransactionDirection.diya).fold<int>(0, (s, e) => s + (e.amountPaise ?? 0));

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                                          Text('${eventEntries.length} ${l10n.items}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (eMila > 0)
                                          Text('↓ ${CurrencyUtils.formatPaise(eMila)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.milaGreen)),
                                        if (eDiya > 0)
                                          Text('↑ ${CurrencyUtils.formatPaise(eDiya)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.diyaRed)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Section Title: Export Reports
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        l10n.reports,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                      ),
                    ),

                    // D. Complete Ledger PDF
                    _buildReportTile(
                      title: l10n.completeLedgerPdf,
                      icon: Icons.picture_as_pdf,
                      iconColor: primaryAccent,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final file = await PdfService.generateLedgerPdf(
                            entries: entries,
                            title: l10n.completeLedgerPdf,
                            l10n: l10n,
                          );
                          await PdfService.printOrSharePdf(file);
                        } finally {
                          if (mounted) setState(() => _isGenerating = false);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // E. Received Only PDF
                    _buildReportTile(
                      title: l10n.receivedOnlyPdf,
                      icon: Icons.arrow_downward,
                      iconColor: AppColors.milaGreen,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final receivedEntries = entries.where((e) => e.direction.value == 'received').toList();
                          final file = await PdfService.generateLedgerPdf(
                            entries: receivedEntries,
                            title: l10n.receivedOnlyPdf,
                            l10n: l10n,
                          );
                          await PdfService.printOrSharePdf(file);
                        } finally {
                          if (mounted) setState(() => _isGenerating = false);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // F. Given Only PDF
                    _buildReportTile(
                      title: l10n.givenOnlyPdf,
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.diyaRed,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final givenEntries = entries.where((e) => e.direction.value == 'given').toList();
                          final file = await PdfService.generateLedgerPdf(
                            entries: givenEntries,
                            title: l10n.givenOnlyPdf,
                            l10n: l10n,
                          );
                          await PdfService.printOrSharePdf(file);
                        } finally {
                          if (mounted) setState(() => _isGenerating = false);
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // G. CSV Section
                    _buildReportTile(
                      title: l10n.csvExport,
                      icon: Icons.table_chart_outlined,
                      iconColor: isDark ? const Color(0xFF38BDF8) : headerBg,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final file = await CsvService.exportEntriesCsv(entries, l10n: l10n);
                          await CsvService.shareCsv(file, shareText: l10n.csvExport);
                        } finally {
                          if (mounted) setState(() => _isGenerating = false);
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildReportTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return ExpressCard(
      padding: EdgeInsets.zero,
      radius: 16,
      color: cardBg,
      borderColor: cardBorder,
      elevation: 0,
      onTap: onTap,
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
        trailing: Icon(Icons.share, color: textSecondary, size: 20),
      ),
    );
  }
}
