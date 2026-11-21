import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';

/// Service for generating offline printable PDF reports in Hindi & English
class PdfService {
  PdfService._();

  /// Generates and shares a complete Ledger PDF report
  static Future<File> generateLedgerPdf({
    required List<TransactionEntry> entries,
    required String title,
    String? subtitle,
    AppLocalizations? l10n,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final boldFont = await PdfGoogleFonts.notoSansDevanagariBold();

    final totalReceived = entries
        .where((e) => e.direction.value == 'received' && e.status.value == 'recorded' && e.archivedAt == null)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));

    final totalGiven = entries
        .where((e) => e.direction.value == 'given' && e.status.value == 'recorded' && e.archivedAt == null)
        .fold(0, (sum, e) => sum + (e.amountPaise ?? 0));

    final appName = l10n?.appName ?? 'Vyavahaar';
    final appTagline = l10n?.appTagline ?? 'Remembering family relations, forever.';
    final totalRecText = '${l10n?.totalReceived ?? 'Total Received'}: ${CurrencyUtils.formatPaise(totalReceived)}';
    final totalGivText = '${l10n?.totalGiven ?? 'Total Given'}: ${CurrencyUtils.formatPaise(totalGiven)}';
    final totalCountText = '${l10n?.all ?? 'Total'}: ${entries.length}';
    final headers = [
      l10n?.transactionDate ?? 'Date',
      l10n?.personName ?? 'Person',
      l10n?.direction ?? 'Direction',
      l10n?.cashAmount ?? 'Amount',
      l10n?.tabEvents ?? 'Event',
      l10n?.giftItem ?? 'Gift',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  appName,
                  style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColor.fromHex('#1F3352')),
                ),
                pw.Text(
                  AppDateUtils.getTodayIsoString(),
                  style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('#6B7280')),
                ),
              ],
            ),
            pw.Text(
              appTagline,
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('#C05A2B')),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              title,
              style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColor.fromHex('#111827')),
            ),
            if (subtitle != null) ...[
              pw.Text(
                subtitle,
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColor.fromHex('#4B5563')),
              ),
            ],
            pw.SizedBox(height: 12),
            // Financial Summary Bar
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F4EFE7'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text(
                    totalRecText,
                    style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColor.fromHex('#15803D')),
                  ),
                  pw.Text(
                    totalGivText,
                    style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColor.fromHex('#B91C1C')),
                  ),
                  pw.Text(
                    totalCountText,
                    style: pw.TextStyle(font: font, fontSize: 11, color: PdfColor.fromHex('#1F3352')),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: entries.map((e) {
              final isRec = e.direction.value == 'received';
              final dirText = isRec ? (l10n?.received ?? 'Received') : (l10n?.given ?? 'Given');
              final giftSummary = e.items.isNotEmpty
                  ? e.items.map((i) => i.itemName).join(', ')
                  : '-';
              return [
                e.transactionDate,
                e.personName ?? e.personId,
                dirText,
                e.amountPaise != null ? CurrencyUtils.formatPaise(e.amountPaise!) : '-',
                e.eventTitle ?? '-',
                giftSummary,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColor.fromHex('#FFFFFF')),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1F3352')),
            cellStyle: pw.TextStyle(font: font, fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            '$appName • ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColor.fromHex('#9CA3AF')),
          ),
        ),
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/vyavahaar_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Print or share PDF directly from mobile/desktop
  static Future<void> printOrSharePdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.sharePdf(bytes: bytes, filename: 'vyavahaar_report.pdf');
  }
}
