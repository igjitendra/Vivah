import 'package:drift/drift.dart';

/// Database schema migration runner for Vyavahaar
/// Implements sequential, non-destructive migrations preserving 100% of historical data.
class SchemaMigrations {
  SchemaMigrations._();

  static const int currentSchemaVersion = 9;

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

    // Migration v4 -> v5: Advanced Event Management Schema
    if (from < 5) {
      await _migrateToV5(m, db);
    }

    // Migration v5 -> v6: Advanced People & Phone Contacts Import Schema
    if (from < 6) {
      await _migrateToV6(m, db);
    }

    // Migration v6 -> v7: Attachments table for entry proof images
    if (from < 7) {
      await _migrateToV7(m, db);
    }

    // Migration v7 -> v8: Self-heal extended people/event columns and auxiliary tables
    if (from < 8) {
      await ensureAllTablesAndColumns(db, m);
    }

    // Migration v8 -> v9: Two-Type Events (Own Family vs Relative Invited Event) & empty archived_at cleanup
    if (from < 9) {
      await _migrateToV9(m, db);
    }

    // Ensure foreign key integrity verification after migration
    await db.customStatement('PRAGMA foreign_key_check;');
  }

  /// Ensures all tables, extended columns, and performance indexes exist across all versions.
  /// Fully idempotent and safe to call on fresh install, after migration, or on beforeOpen.
  static Future<void> ensureAllTablesAndColumns(GeneratedDatabase db, [Migrator? m]) async {
    final migrator = m ?? Migrator(db);
    await _migrateToV2(migrator, db);
    await _migrateToV3(migrator, db);
    await _migrateToV4(migrator, db);
    await _migrateToV5(migrator, db);
    await _migrateToV6(migrator, db);
    await _migrateToV7(migrator, db);
    await _migrateToV9(migrator, db);
    await createAllIndexes(db);
    try {
      await db.customStatement('PRAGMA foreign_key_check;');
    } catch (_) {}
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

  static Future<void> _migrateToV5(Migrator m, GeneratedDatabase db) async {
    // 1. Extend events table with advanced planning & location columns
    final eventCols = [
      "ALTER TABLE events ADD COLUMN category TEXT;",
      "ALTER TABLE events ADD COLUMN end_date TEXT;",
      "ALTER TABLE events ADD COLUMN start_time TEXT;",
      "ALTER TABLE events ADD COLUMN end_time TEXT;",
      "ALTER TABLE events ADD COLUMN is_all_day INTEGER NOT NULL DEFAULT 0;",
      "ALTER TABLE events ADD COLUMN status TEXT NOT NULL DEFAULT 'planned';",
      "ALTER TABLE events ADD COLUMN priority TEXT NOT NULL DEFAULT 'normal';",
      "ALTER TABLE events ADD COLUMN budget_estimated_paise INTEGER;",
      "ALTER TABLE events ADD COLUMN address TEXT;",
      "ALTER TABLE events ADD COLUMN village_city TEXT;",
      "ALTER TABLE events ADD COLUMN landmark TEXT;",
      "ALTER TABLE events ADD COLUMN map_link TEXT;",
      "ALTER TABLE events ADD COLUMN description TEXT;",
    ];
    for (final sql in eventCols) {
      try {
        await db.customStatement(sql);
      } catch (_) {}
    }

    // 2. Event Functions (Multiple ceremonies/functions under a parent event)
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_functions (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        title TEXT NOT NULL,
        function_date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        venue TEXT,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'planned',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 3. Event Participants & Roles
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_participants (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        person_id TEXT,
        family_id TEXT,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'other',
        phone TEXT,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL,
        FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL
      );
    ''');

    // 4. Event Guests & RSVP Invitations
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_guests (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        person_id TEXT,
        name TEXT NOT NULL,
        family_or_group TEXT,
        phone_number TEXT,
        invitation_status TEXT NOT NULL DEFAULT 'not_sent',
        attendance_status TEXT NOT NULL DEFAULT 'not_confirmed',
        accompanying_count INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        invitation_date TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL
      );
    ''');

    // 5. Event Tasks & Checklist
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_tasks (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        assigned_person_name TEXT,
        due_date TEXT,
        priority TEXT NOT NULL DEFAULT 'normal',
        status TEXT NOT NULL DEFAULT 'pending',
        completed_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 6. Event Schedule Chronological Items
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_schedule_items (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        function_id TEXT,
        title TEXT NOT NULL,
        activity_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL DEFAULT 60,
        venue TEXT,
        responsible_person TEXT,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (function_id) REFERENCES event_functions(id) ON DELETE SET NULL
      );
    ''');

    // 7. Event Budget Categories
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_budget_categories (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        estimated_amount_paise INTEGER NOT NULL DEFAULT 0,
        actual_amount_paise INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 8. Event Notes
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_notes (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 9. Event Attachments
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_attachments (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_type TEXT,
        file_size_bytes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 10. Event Activity Logs
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_activity_logs (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 11. Event Reminders
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS event_reminders (
        id TEXT PRIMARY KEY NOT NULL,
        event_id TEXT NOT NULL,
        title TEXT NOT NULL,
        reminder_date TEXT NOT NULL,
        reminder_time TEXT,
        preset TEXT,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
      );
    ''');

    // 12. Create Performance Indexes for Advanced Events
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

    // Advanced Events Sub-table indexes
    try {
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_functions_event ON event_functions(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_guests_event ON event_guests(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_tasks_event ON event_tasks(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_schedule_event ON event_schedule_items(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_budget_event ON event_budget_categories(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_notes_event ON event_notes(event_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_event_reminders_event ON event_reminders(event_id);');
    } catch (_) {}

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

  /// Migration v5 -> v6: Advanced People, Relatives & Phone Contacts Import System
  static Future<void> _migrateToV6(Migrator m, GeneratedDatabase db) async {
    // 1. Extend people table with advanced profile and import columns
    final peopleColumns = [
      "ALTER TABLE people ADD COLUMN first_name TEXT;",
      "ALTER TABLE people ADD COLUMN middle_name TEXT;",
      "ALTER TABLE people ADD COLUMN last_name TEXT;",
      "ALTER TABLE people ADD COLUMN nickname TEXT;",
      "ALTER TABLE people ADD COLUMN gender TEXT;",
      "ALTER TABLE people ADD COLUMN date_of_birth TEXT;",
      "ALTER TABLE people ADD COLUMN photo_path TEXT;",
      "ALTER TABLE people ADD COLUMN whatsapp_number TEXT;",
      "ALTER TABLE people ADD COLUMN village TEXT;",
      "ALTER TABLE people ADD COLUMN city TEXT;",
      "ALTER TABLE people ADD COLUMN district TEXT;",
      "ALTER TABLE people ADD COLUMN state TEXT;",
      "ALTER TABLE people ADD COLUMN pin_code TEXT;",
      "ALTER TABLE people ADD COLUMN relationship_notes TEXT;",
      "ALTER TABLE people ADD COLUMN occupation TEXT;",
      "ALTER TABLE people ADD COLUMN company TEXT;",
      "ALTER TABLE people ADD COLUMN tags TEXT;",
      "ALTER TABLE people ADD COLUMN contact_source TEXT NOT NULL DEFAULT 'manual';",
      "ALTER TABLE people ADD COLUMN external_contact_id TEXT;",
      "ALTER TABLE people ADD COLUMN imported_at TEXT;",
      "ALTER TABLE people ADD COLUMN is_app_edited_after_import INTEGER NOT NULL DEFAULT 0;",
    ];

    for (final colSql in peopleColumns) {
      try {
        await db.customStatement(colSql);
      } catch (_) {}
    }

    // 2. Normalized Person Secondary Phone Numbers table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS person_phones (
        id TEXT PRIMARY KEY NOT NULL,
        person_id TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        label TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE
      );
    ''');

    // 3. Normalized Person Email Addresses table
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS person_emails (
        id TEXT PRIMARY KEY NOT NULL,
        person_id TEXT NOT NULL,
        email TEXT NOT NULL,
        label TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE
      );
    ''');

    // 4. Performance Indexes for fast phone search, external ID lookup, and relations
    try {
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_people_phone ON people(phone_number);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_people_ext_id ON people(external_contact_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_person_phones_person ON person_phones(person_id);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_person_phones_num ON person_phones(phone_number);');
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_person_emails_person ON person_emails(person_id);');
    } catch (_) {}
  }

  /// Migration v6 -> v7: Attachments table for entry proof images
  static Future<void> _migrateToV7(Migrator m, GeneratedDatabase db) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY NOT NULL,
        entry_id TEXT NOT NULL,
        local_path TEXT NOT NULL,
        note TEXT,
        remote_path TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
      );
    ''');
    try {
      await db.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_attachments_entry ON attachments(entry_id);');
    } catch (_) {}
  }

  /// Migration v8 -> v9: Event Scope (Own Family vs Relative Invited Event) & archived_at cleanup
  static Future<void> _migrateToV9(Migrator m, GeneratedDatabase db) async {
    final cols = [
      "ALTER TABLE events ADD COLUMN event_scope TEXT NOT NULL DEFAULT 'own_family';",
      "ALTER TABLE events ADD COLUMN host_person_id TEXT;",
      "ALTER TABLE events ADD COLUMN host_person_name TEXT;",
      "ALTER TABLE events ADD COLUMN attending_family_note TEXT;",
    ];
    for (final sql in cols) {
      try {
        await db.customStatement(sql);
      } catch (_) {}
    }

    // Repair any existing events saved with empty string '' in archived_at (which hid them from active queries)
    try {
      await db.customStatement("UPDATE events SET archived_at = NULL WHERE archived_at = '';");
      await db.customStatement("UPDATE people SET archived_at = NULL WHERE archived_at = '';");
      await db.customStatement("UPDATE entries SET archived_at = NULL WHERE archived_at = '';");
      await db.customStatement('CREATE INDEX IF NOT EXISTS idx_events_scope ON events(event_scope);');
      await db.customStatement('CREATE INDEX IF NOT EXISTS idx_events_host ON events(host_person_id);');
    } catch (_) {}
  }
}
