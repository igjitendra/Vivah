import * as FileSystem from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';
import { paiseToRupees } from '../utils/currency';
import type { Entry, EntryItem, Person, Event } from '../types';

export class CsvService {
  /**
   * Properly escapes a CSV field (RFC 4180)
   */
  private static escapeCsv(value: string | number | null | undefined): string {
    if (value === null || value === undefined) return '""';
    const str = String(value).replace(/"/g, '""');
    return `"${str}"`;
  }

  /**
   * Prepends UTF-8 BOM so Excel on Android/Windows parses Devanagari without gibberish
   */
  private static wrapUtf8Bom(csvContent: string): string {
    return '\uFEFF' + csvContent;
  }

  /**
   * Writes CSV file and triggers native Android share
   */
  private static async writeAndShareCsv(filename: string, content: string): Promise<string> {
    const targetDir = (FileSystem as any).documentDirectory || (FileSystem as any).cacheDirectory || '';
    const fileUri = `${targetDir}${filename}`;

    await FileSystem.writeAsStringAsync(fileUri, this.wrapUtf8Bom(content), {
      encoding: (FileSystem as any).EncodingType?.UTF8 || 'utf8',
    });

    if (await Sharing.isAvailableAsync()) {
      await Sharing.shareAsync(fileUri, {
        mimeType: 'text/csv',
        dialogTitle: `${filename} — CSV फाइल साझा करें`,
        UTI: 'public.comma-separated-values-text',
      });
    }

    return fileUri;
  }

  /**
   * 1. Export all Transactions CSV
   */
  static async exportAllEntries(): Promise<string> {
    const db = getDb();
    const entries = db.getAllSync<Entry>(
      `SELECT e.*, p.name as person_name, p.village as person_village, p.relationship as person_relationship, ev.title as event_title, ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL
       ORDER BY e.created_at DESC`,
      DEFAULT_HOUSEHOLD_ID
    );

    const headers = [
      'क्रमांक',
      'प्रकार',
      'स्थिति',
      'व्यक्ति_नाम',
      'गाँव',
      'रिश्ता',
      'कार्यक्रम',
      'कार्यक्रम_तारीख',
      'नकद_राशि_रुपए',
      'अपेक्षित_तारीख',
      'टिप्पणी_नोट',
      'प्रविष्टि_दिनांक',
    ];

    const rows = entries.map((e, idx) => [
      idx + 1,
      e.direction === 'mila' ? 'मिला' : 'दिया',
      e.status === 'recorded' ? 'पूर्ण' : e.status === 'planned' ? 'नियोजित' : 'रद्द',
      this.escapeCsv(e.person_name),
      this.escapeCsv(e.person_village),
      this.escapeCsv(e.person_relationship),
      this.escapeCsv(e.event_title),
      this.escapeCsv(e.event_date),
      paiseToRupees(e.cash_amount_paise),
      this.escapeCsv(e.expected_date),
      this.escapeCsv(e.notes),
      this.escapeCsv(e.created_at),
    ].join(','));

    const csvContent = headers.join(',') + '\n' + rows.join('\n');
    return this.writeAndShareCsv(`vyavahaar_entries_${new Date().toISOString().split('T')[0]}.csv`, csvContent);
  }

  /**
   * 2. Export People Directory CSV
   */
  static async exportPeople(): Promise<string> {
    const db = getDb();
    const people = db.getAllSync<Person & { family_name?: string }>(
      `SELECT p.*, f.name as family_name
       FROM people p
       LEFT JOIN families f ON p.family_id = f.id
       WHERE p.household_id = ?
       ORDER BY p.name ASC`,
      DEFAULT_HOUSEHOLD_ID
    );

    const headers = ['क्रमांक', 'नाम', 'परिवार', 'गाँव_शहर', 'रिश्ता', 'मोबाइल', 'नोट'];
    const rows = people.map((p, idx) => [
      idx + 1,
      this.escapeCsv(p.name),
      this.escapeCsv(p.family_name),
      this.escapeCsv(p.village),
      this.escapeCsv(p.relationship),
      this.escapeCsv(p.phone),
      this.escapeCsv(p.notes),
    ].join(','));

    const csvContent = headers.join(',') + '\n' + rows.join('\n');
    return this.writeAndShareCsv(`vyavahaar_people_${new Date().toISOString().split('T')[0]}.csv`, csvContent);
  }

  /**
   * 3. Export Gifts and Items CSV
   */
  static async exportItems(): Promise<string> {
    const db = getDb();
    const items = db.getAllSync<EntryItem & { person_name: string; event_title: string; direction: string }>(
      `SELECT i.*, p.name as person_name, ev.title as event_title, e.direction
       FROM entry_items i
       JOIN entries e ON i.entry_id = e.id
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL
       ORDER BY i.created_at DESC`,
      DEFAULT_HOUSEHOLD_ID
    );

    const headers = ['क्रमांक', 'वस्तु_नाम', 'मात्रा', 'इकाई', 'अनुमानित_मूल्य_रुपए', 'प्रकार', 'व्यक्ति', 'कार्यक्रम'];
    const rows = items.map((it, idx) => [
      idx + 1,
      this.escapeCsv(it.item_name),
      it.quantity,
      this.escapeCsv(it.unit),
      it.estimated_value_paise ? paiseToRupees(it.estimated_value_paise) : '',
      it.direction === 'mila' ? 'मिला' : 'दिया',
      this.escapeCsv(it.person_name),
      this.escapeCsv(it.event_title),
    ].join(','));

    const csvContent = headers.join(',') + '\n' + rows.join('\n');
    return this.writeAndShareCsv(`vyavahaar_gifts_${new Date().toISOString().split('T')[0]}.csv`, csvContent);
  }
}
