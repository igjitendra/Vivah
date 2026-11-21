import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/entities.dart';

/// Service for generating Excel-compatible CSV exports with UTF-8 BOM
class CsvService {
  CsvService._();

  /// Export entries to CSV file
  static Future<File> exportEntriesCsv(List<TransactionEntry> entries) async {
    final rows = <List<dynamic>>[];

    // CSV Header
    rows.add([
      'Transaction ID',
      'Date',
      'Person Name',
      'Relationship',
      'Village / Address',
      'Direction (दिशा)',
      'Cash Amount (Rupees)',
      'Cash Amount (Paise)',
      'Transaction Type',
      'Status',
      'Event Title',
      'Physical Gifts / Items',
      'Notes',
    ]);

    for (final e in entries) {
      final directionLabel = e.direction.value == 'received' ? 'मिला (Received)' : 'दिया (Given)';
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
    // Prepend UTF-8 BOM so Excel opens Hindi Devanagari correctly without garbling
    final contentWithBom = '\uFEFF$csvString';

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File('${outputDir.path}/vyavahaar_entries_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(contentWithBom);
    return file;
  }

  /// Share CSV file via native share sheet
  static Future<void> shareCsv(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'व्यवहार CSV बही-खाता');
  }
}
