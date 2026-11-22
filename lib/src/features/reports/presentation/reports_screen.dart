import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../services/pdf_service.dart';
import '../services/csv_service.dart';

/// Screen offering PDF Ledger Printing (A4) and Excel/CSV Export
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
        title: Text(l10n.reports, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // A. Complete Ledger PDF
                    _buildReportTile(
                      title: l10n.completeLedgerPdf,
                      subtitle: l10n.completeLedgerPdfSubtitle,
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

                    // B. Received Only PDF
                    _buildReportTile(
                      title: l10n.receivedOnlyPdf,
                      subtitle: l10n.receivedOnlyPdfSubtitle,
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

                    // C. Given Only PDF
                    _buildReportTile(
                      title: l10n.givenOnlyPdf,
                      subtitle: l10n.givenOnlyPdfSubtitle,
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

                    const SizedBox(height: AppSpacing.md),

                    // D. CSV Section
                    _buildReportTile(
                      title: l10n.csvExport,
                      subtitle: l10n.csvExportSubtitle,
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
                  ],
                );
              },
            ),
    );
  }

  Widget _buildReportTile({
    required String title,
    required String subtitle,
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
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: Icon(Icons.share, color: textSecondary),
      ),
    );
  }
}
