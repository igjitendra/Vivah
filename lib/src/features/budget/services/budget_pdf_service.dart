import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/budget_models.dart';

/// Generates offline printable A4 PDF statements for Event Budget, Payees,
/// and Returnable Fund Arrangements.
class BudgetPdfService {
  BudgetPdfService._();

  static Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    try {
      final reg =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final bold =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      return (regular: pw.Font.ttf(reg), bold: pw.Font.ttf(bold));
    } catch (_) {
      try {
        return (
          regular: await PdfGoogleFonts.notoSansDevanagariRegular(),
          bold: await PdfGoogleFonts.notoSansDevanagariBold(),
        );
      } catch (_) {
        return (regular: pw.Font.helvetica(), bold: pw.Font.helveticaBold());
      }
    }
  }

  static Future<File> generateBudgetPdf({
    required String eventTitle,
    required BudgetOverviewStats stats,
    required List<BudgetExpense> expenses,
    required List<FundArrangement> arrangements,
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final font = fonts.regular;
    final boldFont = fonts.bold;
    final appName = l10n.appName;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$appName — ${l10n.budgetPlannerTitle}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: PdfColor.fromHex('#1F3352'),
                  ),
                ),
                pw.Text(
                  AppDateUtils.getTodayIsoString(),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 9.5,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              eventTitle,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                color: PdfColor.fromHex('#C05A2B'),
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (ctx) => [
          // Top Summary Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _statCol(
                  l10n.plannedBudgetLabel,
                  CurrencyUtils.formatPaise(stats.plannedBudgetPaise),
                  font,
                  boldFont,
                ),
                _statCol(
                  l10n.totalPaidOutLabel,
                  CurrencyUtils.formatPaise(stats.totalPaidPaise),
                  font,
                  boldFont,
                ),
                _statCol(
                  l10n.vendorPendingLabel,
                  CurrencyUtils.formatPaise(stats.totalVendorPendingPaise),
                  font,
                  boldFont,
                ),
                _statCol(
                  l10n.returnRemainingLabel,
                  CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                  font,
                  boldFont,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          if (expenses.isNotEmpty) ...[
            pw.Text(
              l10n.budgetTabPayees,
              style: pw.TextStyle(font: boldFont, fontSize: 11.5),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.transactionDate,
                l10n.payeeVendorLabel,
                l10n.expenseItemLabel,
                l10n.agreedDealLabel,
                l10n.paidNowLabel,
                l10n.balanceRemainingLabel,
              ],
              data: expenses
                  .map((e) => [
                        e.expenseDate,
                        e.vendorName,
                        e.categoryName.isNotEmpty
                            ? '${e.title} (${e.categoryName})'
                            : e.title,
                        CurrencyUtils.formatPaise(e.effectiveTotalPaise),
                        CurrencyUtils.formatPaise(e.paidAmountPaise),
                        CurrencyUtils.formatPaise(e.remainingPaise),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: PdfColor.fromHex('#FFFFFF'),
              ),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#1F3352')),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            ),
            pw.SizedBox(height: 16),
          ],
          if (arrangements.isNotEmpty) ...[
            pw.Text(
              l10n.budgetTabBorrowed,
              style: pw.TextStyle(font: boldFont, fontSize: 11.5),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: [
                l10n.takenDateLabel,
                l10n.lenderNameLabel,
                l10n.takenAmountLabel,
                l10n.returnedAmountLabel,
                l10n.returnRemainingLabel,
                l10n.returnTargetDateLabel,
              ],
              data: arrangements
                  .map((a) => [
                        a.takenDate,
                        a.lenderName,
                        CurrencyUtils.formatPaise(a.totalReturnablePaise),
                        CurrencyUtils.formatPaise(a.returnedPaise),
                        CurrencyUtils.formatPaise(a.remainingPaise),
                        a.returnTargetDate ?? '-',
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                font: boldFont,
                fontSize: 8.5,
                color: PdfColor.fromHex('#FFFFFF'),
              ),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#92400E')),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            ),
          ],
        ],
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            '$appName • ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColor.fromHex('#9CA3AF'),
            ),
          ),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/vyavahaar_budget_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _statCol(
    String label,
    String value,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 7.5,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 10,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
      ],
    );
  }

  static Future<void> printOrSharePdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'vyavahaar_budget_statement.pdf',
    );
  }
}
