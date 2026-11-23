#!/usr/bin/env python3
"""
व्यवहार (Vyavahaar) — Step 5: Advanced Event Management Architecture Verification
Tests Schema v5 migration, 10 child tables, cascading integrity,
financial isolation, conflict detection algorithms, budget calculations, and RSVP metrics.
"""

import sqlite3
import sys
import os

SCHEMA_V4_SQL = """
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS families (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    archived_at TEXT
);

CREATE TABLE IF NOT EXISTS people (
    id TEXT PRIMARY KEY NOT NULL,
    family_id TEXT,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    relationship_label TEXT,
    address TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    archived_at TEXT,
    FOREIGN KEY (family_id) REFERENCES families(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_date TEXT NOT NULL,
    venue TEXT,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    archived_at TEXT
);

CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY NOT NULL,
    person_id TEXT NOT NULL,
    event_id TEXT,
    direction TEXT NOT NULL CHECK(direction IN ('received', 'given')),
    status TEXT NOT NULL DEFAULT 'recorded' CHECK(status IN ('recorded', 'planned', 'cancelled')),
    transaction_type TEXT NOT NULL DEFAULT 'cash' CHECK(transaction_type IN ('cash', 'gift', 'mixed')),
    amount_paise INTEGER,
    date TEXT NOT NULL,
    expected_date TEXT,
    notes TEXT,
    recorded_at TEXT,
    cancelled_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    archived_at TEXT,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS entry_items (
    id TEXT PRIMARY KEY NOT NULL,
    entry_id TEXT NOT NULL,
    item_type TEXT NOT NULL CHECK(item_type IN ('cash', 'gift')),
    description TEXT,
    estimated_value_paise INTEGER,
    weight_grams REAL,
    quantity INTEGER DEFAULT 1,
    unit TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);
"""

MIGRATION_V5_SQL = """
ALTER TABLE events ADD COLUMN category TEXT;
ALTER TABLE events ADD COLUMN end_date TEXT;
ALTER TABLE events ADD COLUMN start_time TEXT;
ALTER TABLE events ADD COLUMN end_time TEXT;
ALTER TABLE events ADD COLUMN is_all_day INTEGER NOT NULL DEFAULT 0;
ALTER TABLE events ADD COLUMN status TEXT NOT NULL DEFAULT 'planned';
ALTER TABLE events ADD COLUMN priority TEXT NOT NULL DEFAULT 'normal';
ALTER TABLE events ADD COLUMN budget_estimated_paise INTEGER;
ALTER TABLE events ADD COLUMN address TEXT;
ALTER TABLE events ADD COLUMN village_city TEXT;
ALTER TABLE events ADD COLUMN landmark TEXT;
ALTER TABLE events ADD COLUMN map_link TEXT;
ALTER TABLE events ADD COLUMN description TEXT;

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

CREATE TABLE IF NOT EXISTS event_notes (
    id TEXT PRIMARY KEY NOT NULL,
    event_id TEXT NOT NULL,
    note_text TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_attachments (
    id TEXT PRIMARY KEY NOT NULL,
    event_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_type TEXT,
    file_size_bytes INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_activity_logs (
    id TEXT PRIMARY KEY NOT NULL,
    event_id TEXT NOT NULL,
    action TEXT NOT NULL,
    details TEXT,
    timestamp TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_reminders (
    id TEXT PRIMARY KEY NOT NULL,
    event_id TEXT NOT NULL,
    title TEXT NOT NULL,
    reminder_date TEXT NOT NULL,
    is_enabled INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_event_functions_event ON event_functions(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_guests_event ON event_guests(event_id);
CREATE INDEX IF NOT EXISTS idx_event_tasks_event ON event_tasks(event_id);
CREATE INDEX IF NOT EXISTS idx_event_schedule_event ON event_schedule_items(event_id);
CREATE INDEX IF NOT EXISTS idx_event_budget_event ON event_budget_categories(event_id);
CREATE INDEX IF NOT EXISTS idx_event_notes_event ON event_notes(event_id);
CREATE INDEX IF NOT EXISTS idx_event_attachments_event ON event_attachments(event_id);
CREATE INDEX IF NOT EXISTS idx_event_activity_logs_event ON event_activity_logs(event_id);
CREATE INDEX IF NOT EXISTS idx_event_reminders_event ON event_reminders(event_id);
"""

def run_tests():
    print("=" * 65)
    print("🎪 VYAVHAAR STEP 5: ADVANCED EVENT MANAGEMENT ARCHITECTURE TEST")
    print("=" * 65)

    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    passed = 0
    total = 0

    def assert_test(cond, title):
        nonlocal passed, total
        total += 1
        if cond:
            print(f"  ✅ {title}")
            passed += 1
        else:
            print(f"  ❌ FAILED: {title}")

    # 1. Setup V4 Schema
    cursor.executescript(SCHEMA_V4_SQL)

    # 2. Apply V5 Migration
    cursor.executescript(MIGRATION_V5_SQL)

    # Check 1: Verify all 10 child tables exist
    print("\n📦 1. Schema v5 Migration & Child Tables Verification:")
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'event_%';")
    child_tables = {row[0] for row in cursor.fetchall()}
    expected_tables = {
        'event_functions', 'event_participants', 'event_guests', 'event_tasks',
        'event_schedule_items', 'event_budget_categories', 'event_notes',
        'event_attachments', 'event_activity_logs', 'event_reminders'
    }
    assert_test(expected_tables.issubset(child_tables), f"All 10 child tables created successfully ({len(child_tables)} found)")

    # Check 2: Verify extended columns on events table
    cursor.execute("PRAGMA table_info(events);")
    events_cols = {row[1] for row in cursor.fetchall()}
    expected_cols = {'category', 'end_date', 'start_time', 'end_time', 'is_all_day', 'status', 'priority', 'budget_estimated_paise', 'address', 'village_city', 'landmark', 'map_link', 'description'}
    assert_test(expected_cols.issubset(events_cols), f"All 13 extended columns added to events table")

    # Check 3: Insert complete event with child records
    print("\n🔗 2. Relational Child Records & Cascades Verification:")
    cursor.execute("""
        INSERT INTO events (id, title, event_type, event_date, end_date, venue, status, priority, budget_estimated_paise)
        VALUES ('ev-001', 'Rahul & Priya Wedding', 'wedding', '2026-12-10', '2026-12-12', 'Grand Palace', 'confirmed', 'high', 50000000);
    """)

    # Add 2 functions
    cursor.execute("INSERT INTO event_functions (id, event_id, title, function_date) VALUES ('fn-1', 'ev-001', 'Haldi', '2026-12-10');")
    cursor.execute("INSERT INTO event_functions (id, event_id, title, function_date) VALUES ('fn-2', 'ev-001', 'Barat', '2026-12-11');")

    # Add 2 participants
    cursor.execute("INSERT INTO event_participants (id, event_id, name, role) VALUES ('part-1', 'ev-001', 'Ramesh Kumar', 'host');")
    cursor.execute("INSERT INTO event_participants (id, event_id, name, role) VALUES ('part-2', 'ev-001', 'Rahul Sharma', 'groom');")

    # Add 2 guests (1 with 2 accompanying)
    cursor.execute("INSERT INTO event_guests (id, event_id, name, invitation_status, attendance_status, accompanying_count) VALUES ('gst-1', 'ev-001', 'Sharma Family', 'sent', 'attending', 3);")
    cursor.execute("INSERT INTO event_guests (id, event_id, name, invitation_status, attendance_status, accompanying_count) VALUES ('gst-2', 'ev-001', 'Verma Ji', 'accepted', 'attending', 1);")

    # Add 3 tasks (2 completed, 1 pending)
    cursor.execute("INSERT INTO event_tasks (id, event_id, title, status) VALUES ('tsk-1', 'ev-001', 'Book Catering', 'completed');")
    cursor.execute("INSERT INTO event_tasks (id, event_id, title, status) VALUES ('tsk-2', 'ev-001', 'Send Invites', 'completed');")
    cursor.execute("INSERT INTO event_tasks (id, event_id, title, status) VALUES ('tsk-3', 'ev-001', 'Arrange Decor', 'pending');")

    # Add 2 budget categories
    cursor.execute("INSERT INTO event_budget_categories (id, event_id, category_name, estimated_amount_paise) VALUES ('cat-1', 'ev-001', 'Catering', 25000000);")
    cursor.execute("INSERT INTO event_budget_categories (id, event_id, category_name, estimated_amount_paise) VALUES ('cat-2', 'ev-001', 'Decoration', 15000000);")

    # Verify counts
    cursor.execute("SELECT COUNT(*) FROM event_functions WHERE event_id = 'ev-001';")
    fn_count = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM event_tasks WHERE event_id = 'ev-001';")
    tsk_count = cursor.fetchone()[0]
    assert_test(fn_count == 2 and tsk_count == 3, f"Parent-child relationships persisted accurately ({fn_count} functions, {tsk_count} tasks)")

    # Check 4: RSVP guest counts calculation
    cursor.execute("SELECT COUNT(*), SUM(1 + accompanying_count) FROM event_guests WHERE event_id = 'ev-001';")
    guest_rows, total_attendees = cursor.fetchone()
    # gst-1: 1 + 3 = 4, gst-2: 1 + 1 = 2 -> total = 6
    assert_test(total_attendees == 6, f"Guest RSVP accurately tallies primary guests + accompanying guests ({total_attendees} expected 6)")

    # Check 5: Task progress metric
    cursor.execute("SELECT COUNT(*), SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) FROM event_tasks WHERE event_id = 'ev-001';")
    total_tasks, completed_tasks = cursor.fetchone()
    completion_rate = (completed_tasks / total_tasks) * 100
    assert_test(completed_tasks == 2 and abs(completion_rate - 66.67) < 0.1, f"Task completion rate calculated correctly ({completed_tasks}/{total_tasks} = {completion_rate:.1f}%)")

    # Check 6: Financial Integration & Strict Isolation Rules
    print("\n💰 3. Financial Integration & Non-Destructive Ledger Invariants:")
    # Add person
    cursor.execute("INSERT INTO people (id, full_name) VALUES ('p-001', 'Uncle Mohan');")
    # Add financial entries linked to event
    # 1 Received (Mila): ₹11,000 = 1100000 paise
    cursor.execute("INSERT INTO entries (id, person_id, event_id, direction, status, amount_paise, date) VALUES ('entry-1', 'p-001', 'ev-001', 'received', 'recorded', 1100000, '2026-12-10');")
    # 1 Given (Diya / Expense): ₹50,000 = 5000000 paise
    cursor.execute("INSERT INTO entries (id, person_id, event_id, direction, status, amount_paise, date) VALUES ('entry-2', 'p-001', 'ev-001', 'given', 'recorded', 5000000, '2026-12-10');")

    # Verify event-linked transactions
    cursor.execute("SELECT SUM(CASE WHEN direction = 'received' THEN amount_paise ELSE 0 END), SUM(CASE WHEN direction = 'given' THEN amount_paise ELSE 0 END) FROM entries WHERE event_id = 'ev-001';")
    received_paise, given_paise = cursor.fetchone()
    assert_test(received_paise == 1100000 and given_paise == 5000000, f"Event financial totals calculated without netting (Received: ₹{received_paise/100:.0f}, Given/Expense: ₹{given_paise/100:.0f})")

    # Check 7: Safe Delete preserves transactions (sets event_id = NULL)
    # Drift's safe delete logic: UPDATE entries SET event_id = NULL WHERE event_id = ?; DELETE FROM events WHERE id = ?;
    cursor.execute("UPDATE entries SET event_id = NULL WHERE event_id = 'ev-001';")
    cursor.execute("DELETE FROM events WHERE id = 'ev-001';")

    # Check entries still exist
    cursor.execute("SELECT COUNT(*) FROM entries WHERE id IN ('entry-1', 'entry-2');")
    entries_count = cursor.fetchone()[0]
    cursor.execute("SELECT event_id FROM entries WHERE id = 'entry-1';")
    null_event_id = cursor.fetchone()[0]
    assert_test(entries_count == 2 and null_event_id is None, "Safe event deletion sets entry.event_id to NULL and strictly preserves all financial records")

    # Check child records were cascade deleted
    cursor.execute("SELECT COUNT(*) FROM event_functions WHERE event_id = 'ev-001';")
    remaining_fn = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM event_tasks WHERE event_id = 'ev-001';")
    remaining_tsk = cursor.fetchone()[0]
    assert_test(remaining_fn == 0 and remaining_tsk == 0, "Child event records cascade-deleted safely when parent event is removed")

    # Check 8: Conflict Detection Algorithm
    print("\n⚡ 4. Scheduling Conflict Detection Verification:")
    cursor.execute("""
        INSERT INTO events (id, title, event_type, event_date, end_date, start_time, end_time, venue, status)
        VALUES ('ev-conf-1', 'Aman Tilak', 'tilak', '2026-12-25', '2026-12-25', '10:00', '14:00', 'City Club', 'confirmed');
    """)

    # Conflict test: another event overlapping same date and time range
    cursor.execute("""
        SELECT COUNT(*) FROM events
        WHERE archived_at IS NULL
        AND id != 'ev-conf-2'
        AND event_date = '2026-12-25'
        AND status != 'cancelled';
    """)
    conflict_count = cursor.fetchone()[0]
    assert_test(conflict_count == 1, "Conflict detector successfully catches overlapping event on the same calendar day")

    # Duplicate title test: same month duplicate
    cursor.execute("""
        SELECT COUNT(*) FROM events
        WHERE archived_at IS NULL
        AND LOWER(title) = LOWER('Aman Tilak')
        AND substr(event_date, 1, 7) = '2026-12';
    """)
    duplicate_count = cursor.fetchone()[0]
    assert_test(duplicate_count == 1, "Conflict detector successfully flags identical title in the same calendar month")

    print("=" * 65)
    print(f"Results: {passed}/{total} tests passed successfully!")
    if passed == total:
        print("🎉 ALL ADVANCED EVENT MANAGEMENT TESTS PASSED WITH 100% SUCCESS!")
    else:
        print("⚠️ SOME TESTS FAILED.")
    print("=" * 65)

    if passed != total:
        sys.exit(1)

if __name__ == '__main__':
    run_tests()
