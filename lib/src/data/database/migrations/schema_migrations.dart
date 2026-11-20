import 'package:drift/drift.dart';

/// Database schema migration runner for Vyavahaar
/// Implements sequential, non-destructive migrations preserving 100% of historical data.
class SchemaMigrations {
  SchemaMigrations._();

  static const int currentSchemaVersion = 4;

  /// Executes all required migrations sequentially from `from` to `to`.
  static Future<void> migrate(
    Migrator m,
    GeneratedDatabase db,
    int from,
    int to,
  ) async {
    // Migration v1 -> v2: Add status and expected_date to entries
    if (from < 2) {
      await _migrateToV2(m, db);
    }

    // Migration v2 -> v3: Add transaction_type, archived_at, recorded_at, cancelled_at
    if (from < 3) {
      await _migrateToV3(m, db);
    }

    // Migration v3 -> v4: Create app_settings table and ensure all performance indexes
    if (from < 4) {
      await _migrateToV4(m, db);
    }

    // Ensure foreign key integrity verification after migration
    await db.customStatement('PRAGMA foreign_key_check;');
  }

  static Future<void> _migrateToV2(Migrator m, GeneratedDatabase db) async {
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN status TEXT NOT NULL DEFAULT 'recorded';");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN expected_date TEXT;");
    } catch (_) {}
  }

  static Future<void> _migrateToV3(Migrator m, GeneratedDatabase db) async {
    // Add transaction_type to entries
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN transaction_type TEXT NOT NULL DEFAULT 'cash';");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN recorded_at TEXT;");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN cancelled_at TEXT;");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE entries ADD COLUMN archived_at TEXT;");
    } catch (_) {}

    // Add archived_at to people, events, families
    try {
      await db.customStatement(
          "ALTER TABLE people ADD COLUMN archived_at TEXT;");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE events ADD COLUMN archived_at TEXT;");
    } catch (_) {}
    try {
      await db.customStatement(
          "ALTER TABLE families ADD COLUMN archived_at TEXT;");
    } catch (_) {}
  }

  static Future<void> _migrateToV4(Migrator m, GeneratedDatabase db) async {
    // Ensure app_settings table exists
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
    ''');

    // Create all performance indexes
    await createAllIndexes(db);
  }

  /// Creates all required indexes for search and aggregation performance
  static Future<void> createAllIndexes(GeneratedDatabase db) async {
    // Entries indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_person ON entries(person_id);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_event ON entries(event_id);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_direction ON entries(direction);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_date ON entries(transaction_date);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entries_archived ON entries(archived_at);');

    // People indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_people_name ON people(full_name);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_people_phone ON people(phone_number);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_people_family ON people(family_id);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_people_archived ON people(archived_at);');

    // Events indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_archived ON events(archived_at);');

    // Families indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_families_name ON families(name);');

    // Entry Items indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entry_items_entry ON entry_items(entry_id);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_entry_items_name ON entry_items(item_name);');

    // Reminders indexes
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reminders_date ON reminders(reminder_date);');
    await db.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(is_completed);');
  }
}
