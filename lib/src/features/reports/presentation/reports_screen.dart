import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../app/app_providers.dart';
import '../services/pdf_service.dart';
import '../services/csv_service.dart';

/// Reports & Data Export Screen
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesListProvider(null));
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(l10n.reports, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              error: (err, stack) => Center(child: Text('${l10n.errorGeneric}: $err')),
              data: (entries) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // A. PDF Section
                    _buildReportTile(
                      title: l10n.completeLedgerPdf,
                      subtitle: l10n.completeLedgerPdfSubtitle,
                      icon: Icons.picture_as_pdf,
                      iconColor: AppColors.terracotta,
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
                      iconColor: AppColors.deepNavy,
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
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 0,
      color: AppColors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        trailing: const Icon(Icons.share, color: AppColors.mutedText),
        onTap: onTap,
      ),
    );
  }
}
