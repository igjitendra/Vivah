import * as SQLite from 'expo-sqlite';

const DB_NAME = 'vyavahaar.db';
export const DEFAULT_HOUSEHOLD_ID = 'household_primary_01';
export const DEFAULT_HOUSEHOLD_NAME = 'हमारा परिवार';

let _db: SQLite.SQLiteDatabase | null = null;

export function getDb(): SQLite.SQLiteDatabase {
  if (!_db) {
    _db = SQLite.openDatabaseSync(DB_NAME);
  }
  return _db;
}

export function withTransaction<T>(fn: () => T): T {
  const db = getDb();
  let result: T;
  db.withTransactionSync(() => {
    result = fn();
  });
  return result!;
}

const CREATE_TABLES_SQL = `
CREATE TABLE IF NOT EXISTS households (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS families (
    id TEXT PRIMARY KEY NOT NULL,
    household_id TEXT NOT NULL,
    name TEXT NOT NULL,
    village TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS people (
    id TEXT PRIMARY KEY NOT NULL,
    household_id TEXT NOT NULL,
    family_id TEXT,
    name TEXT NOT NULL,
    village TEXT,
    relationship TEXT,
    phone TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY NOT NULL,
    household_id TEXT NOT NULL,
    title TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_date TEXT NOT NULL,
    person_id TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY NOT NULL,
    household_id TEXT NOT NULL,
    event_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    direction TEXT NOT NULL CHECK (direction IN ('mila', 'diya')),
    cash_amount_paise INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'recorded' CHECK (status IN ('planned', 'recorded', 'cancelled')),
    expected_date TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    deleted_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'local',
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS entry_items (
    id TEXT PRIMARY KEY NOT NULL,
    entry_id TEXT NOT NULL,
    item_name TEXT NOT NULL,
    quantity REAL NOT NULL DEFAULT 1.0,
    unit TEXT DEFAULT 'संख्या',
    estimated_value_paise INTEGER DEFAULT NULL,
    condition TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reminders (
    id TEXT PRIMARY KEY NOT NULL,
    household_id TEXT NOT NULL,
    person_id TEXT NOT NULL,
    event_title TEXT NOT NULL,
    target_date TEXT NOT NULL,
    note TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attachments (
    id TEXT PRIMARY KEY NOT NULL,
    entry_id TEXT NOT NULL,
    local_path TEXT NOT NULL,
    remote_path TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_entries_event ON entries(event_id);
CREATE INDEX IF NOT EXISTS idx_entries_person ON entries(person_id);
CREATE INDEX IF NOT EXISTS idx_entries_direction ON entries(direction);
CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);
CREATE INDEX IF NOT EXISTS idx_people_name ON people(name);
CREATE INDEX IF NOT EXISTS idx_people_village ON people(village);
CREATE INDEX IF NOT EXISTS idx_entry_items_entry ON entry_items(entry_id);
`;

export function initDatabase(): void {
  const db = getDb();
  // Enable WAL mode and foreign keys
  db.execSync('PRAGMA journal_mode=WAL;');
  db.execSync('PRAGMA foreign_keys=ON;');
  // Create all tables
  db.execSync(CREATE_TABLES_SQL);

  // Migration v3: Ensure status and expected_date exist in entries table
  try {
    const tableInfo = db.getAllSync<{ name: string }>('PRAGMA table_info(entries)');
    const columnNames = tableInfo.map(c => c.name);

    if (!columnNames.includes('status')) {
      db.execSync("ALTER TABLE entries ADD COLUMN status TEXT NOT NULL DEFAULT 'recorded'");
      db.execSync("UPDATE entries SET status = 'recorded' WHERE status IS NULL OR status = ''");
    }

    if (!columnNames.includes('expected_date')) {
      db.execSync('ALTER TABLE entries ADD COLUMN expected_date TEXT');
    }
  } catch (e) {
    console.warn('Migration v3 check note:', e);
  }
}

export function ensureDefaultHousehold(): void {
  const db = getDb();
  const existing = db.getFirstSync<{ id: string }>(
    'SELECT id FROM households WHERE id = ? LIMIT 1',
    DEFAULT_HOUSEHOLD_ID
  );
  if (!existing) {
    const now = new Date().toISOString();
    db.runSync(
      'INSERT INTO households (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)',
      DEFAULT_HOUSEHOLD_ID,
      DEFAULT_HOUSEHOLD_NAME,
      now,
      now
    );
  }
}

export function getDatabaseStats(): { tableCount: number; entryCount: number; plannedCount: number } {
  const db = getDb();
  const tables = db.getAllSync<{ name: string }>(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
  );
  const entries = db.getFirstSync<{ count: number }>(
    "SELECT COUNT(*) as count FROM entries WHERE deleted_at IS NULL AND status = 'recorded'"
  );
  const planned = db.getFirstSync<{ count: number }>(
    "SELECT COUNT(*) as count FROM entries WHERE deleted_at IS NULL AND status = 'planned'"
  );
  return {
    tableCount: tables.length,
    entryCount: entries?.count ?? 0,
    plannedCount: planned?.count ?? 0,
  };
}

export function exportDatabaseAsJSON(): string {
  const db = getDb();
  const households = db.getAllSync('SELECT * FROM households');
  const families = db.getAllSync('SELECT * FROM families');
  const people = db.getAllSync('SELECT * FROM people');
  const events = db.getAllSync('SELECT * FROM events');
  const entries = db.getAllSync('SELECT * FROM entries WHERE deleted_at IS NULL');
  const entry_items = db.getAllSync('SELECT * FROM entry_items');
  const reminders = db.getAllSync('SELECT * FROM reminders');
  return JSON.stringify(
    { households, families, people, events, entries, entry_items, reminders, exported_at: new Date().toISOString() },
    null,
    2
  );
}
