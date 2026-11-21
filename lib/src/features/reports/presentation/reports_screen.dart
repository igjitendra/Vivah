import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text('रिपोर्ट्स और एक्सपोर्ट', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      body: _isGenerating
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
              error: (err, stack) => Center(child: Text('त्रुटि: $err')),
              data: (entries) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // A. PDF Section
                    _buildReportTile(
                      title: 'सम्पूर्ण बही-खाता (Complete Ledger PDF)',
                      subtitle: 'सभी मिला व दिया व्यवहार, दिनांक व कार्यक्रम के साथ A4 प्रिंट',
                      icon: Icons.picture_as_pdf,
                      iconColor: AppColors.terracotta,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final file = await PdfService.generateLedgerPdf(
                            entries: entries,
                            title: 'सम्पूर्ण पारिवारिक बही-खाता',
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
                      title: 'कुल मिला रिपोर्ट (Received Only PDF)',
                      subtitle: 'केवल प्राप्त हुए नकद व उपहारों का विवरण',
                      icon: Icons.arrow_downward,
                      iconColor: AppColors.milaGreen,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final receivedEntries = entries.where((e) => e.direction.value == 'received').toList();
                          final file = await PdfService.generateLedgerPdf(
                            entries: receivedEntries,
                            title: 'कुल मिला व्यवहार (Received Report)',
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
                      title: 'कुल दिया रिपोर्ट (Given Only PDF)',
                      subtitle: 'केवल दिए गए नकद व उपहारों का विवरण',
                      icon: Icons.arrow_upward,
                      iconColor: AppColors.diyaRed,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final givenEntries = entries.where((e) => e.direction.value == 'given').toList();
                          final file = await PdfService.generateLedgerPdf(
                            entries: givenEntries,
                            title: 'कुल दिया व्यवहार (Given Report)',
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
                      title: 'Excel / CSV डेटा एक्सपोर्ट',
                      subtitle: 'माइक्रोसॉफ्ट एक्सेल संगत (UTF-8 BOM), सभी पंक्तियां और कॉलम',
                      icon: Icons.table_chart_outlined,
                      iconColor: AppColors.deepNavy,
                      onTap: () async {
                        setState(() => _isGenerating = true);
                        try {
                          final file = await CsvService.exportEntriesCsv(entries);
                          await CsvService.shareCsv(file);
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
