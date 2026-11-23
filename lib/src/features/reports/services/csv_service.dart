import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/entities.dart';

/// Service for generating Excel-compatible CSV exports with UTF-8 BOM
class CsvService {
  CsvService._();

  /// Alias for backward compatibility
  static Future<File> generateLedgerCsv({required List<TransactionEntry> entries, AppLocalizations? l10n}) =>
      exportEntriesCsv(entries, l10n: l10n);

  /// Export entries to CSV file
  static Future<File> exportEntriesCsv(List<TransactionEntry> entries, {AppLocalizations? l10n}) async {
    final rows = <List<dynamic>>[];

    // CSV Header
    rows.add([
      'Transaction ID',
      l10n?.transactionDate ?? 'Date',
      l10n?.personName ?? 'Person Name',
      l10n?.relationCategory ?? 'Relationship',
      l10n?.villageCity ?? 'Village / Address',
      l10n?.direction ?? 'Direction',
      '${l10n?.cashAmount ?? 'Cash Amount'} (Rupees)',
      '${l10n?.cashAmount ?? 'Cash Amount'} (Paise)',
      l10n?.type ?? 'Transaction Type',
      l10n?.status ?? 'Status',
      l10n?.eventName ?? 'Event Title',
      l10n?.giftItem ?? 'Physical Gifts / Items',
      l10n?.notes ?? 'Notes',
    ]);

    for (final e in entries) {
      final isRec = e.direction.value == 'received';
      final directionLabel = isRec ? (l10n?.received ?? 'Received') : (l10n?.given ?? 'Given');
      final giftSummary = e.items.map((i) => '${i.itemName} (x${i.quantity})').join('; ');

      rows.add([
        e.id,
        e.transactionDate,
        e.personName ?? '',
        e.personRelationship ?? '',
        e.personAddress ?? '',
        directionLabel,
        e.amountPaise != null ? (e.amountPaise! / 100.0).toStringAsFixed(2) : '0.00',
        e.amountPaise ?? 0,
        e.transactionType.value,
        e.status.value,
        e.eventTitle ?? '',
        giftSummary,
        e.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    // Prepend UTF-8 BOM so Excel opens UTF-8 text correctly without garbling
    final contentWithBom = '\uFEFF$csvString';

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/vyavahaar_entries_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(contentWithBom);
    return file;
  }

  /// Share CSV file via native share sheet
  static Future<void> shareCsv(File file, {String? shareText}) async {
    await Share.shareXFiles([XFile(file.path)], text: shareText ?? 'Vyavahaar CSV Ledger');
  }
}
