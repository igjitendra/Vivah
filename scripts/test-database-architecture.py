#!/usr/bin/env python3
"""
व्यवहार (Vyavahaar) — Step 3: SQLite + Drift Database Architecture Verification
Tests tables, constraints, foreign keys, cascades, atomic transactions,
financial calculations, migrations, and performance on 31,700 records.
"""

import sqlite3
import time
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
    direction TEXT NOT NULL CHECK (direction IN ('given', 'received', 'diya', 'mila')),
    transaction_type TEXT NOT NULL DEFAULT 'cash' CHECK (transaction_type IN ('cash', 'item', 'cash_and_item')),
    status TEXT NOT NULL DEFAULT 'recorded' CHECK (status IN ('planned', 'recorded', 'cancelled')),
    amount_paise INTEGER,
    transaction_date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    recorded_at TEXT,
    cancelled_at TEXT,
    archived_at TEXT,
    FOREIGN KEY (person_id) REFERENCES people(id) ON DELETE RESTRICT,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS entry_items (
    id TEXT PRIMARY KEY NOT NULL,
    entry_id TEXT NOT NULL,
    item_name TEXT NOT NULL,
    quantity REAL NOT NULL DEFAULT 1.0,
    unit TEXT DEFAULT 'संख्या',
    estimated_value_paise INTEGER,
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reminders (
    id TEXT PRIMARY KEY NOT NULL,
    entry_id TEXT,
    reminder_date TEXT NOT NULL,
    title TEXT NOT NULL,
    notes TEXT,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_entries_person ON entries(person_id);
CREATE INDEX IF NOT EXISTS idx_entries_event ON entries(event_id);
CREATE INDEX IF NOT EXISTS idx_entries_direction ON entries(direction);
CREATE INDEX IF NOT EXISTS idx_entries_status ON entries(status);
CREATE INDEX IF NOT EXISTS idx_entries_date ON entries(transaction_date);
CREATE INDEX IF NOT EXISTS idx_entries_archived ON entries(archived_at);

CREATE INDEX IF NOT EXISTS idx_people_name ON people(full_name);
CREATE INDEX IF NOT EXISTS idx_people_phone ON people(phone_number);
CREATE INDEX IF NOT EXISTS idx_people_family ON people(family_id);
CREATE INDEX IF NOT EXISTS idx_people_archived ON people(archived_at);

CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_archived ON events(archived_at);

CREATE INDEX IF NOT EXISTS idx_entry_items_entry ON entry_items(entry_id);
CREATE INDEX IF NOT EXISTS idx_entry_items_name ON entry_items(item_name);

CREATE INDEX IF NOT EXISTS idx_reminders_date ON reminders(reminder_date);
CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(is_completed);
"""

def run_tests():
    print("=" * 60)
    print("🧪 VYAVHAAR STEP 3: DATABASE ARCHITECTURE VERIFICATION")
    print("=" * 60)

    # 1. Initialize In-Memory SQLite Database
    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.executescript(SCHEMA_V4_SQL)

    total_tests = 0
    passed_tests = 0

    def assert_test(desc, condition):
        nonlocal total_tests, passed_tests
        total_tests += 1
        if condition:
            passed_tests += 1
            print(f"  ✅ {desc}")
        else:
            print(f"  ❌ FAILED: {desc}")
            sys.exit(1)

    print("\n📦 1. Schema & Table Structure Verification:")
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = {r[0] for r in cursor.fetchall()}
    expected_tables = {'families', 'people', 'events', 'entries', 'entry_items', 'reminders', 'app_settings'}
    assert_test("All 7 required tables exist", expected_tables.issubset(tables))

    cursor.execute("SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%';")
    indexes = {r[0] for r in cursor.fetchall()}
    assert_test("All 14 performance indexes created", len(indexes) >= 14)

    print("\n🛡️ 2. Constraints & Data Integrity Verification:")
    # Foreign key restrict test
    conn.execute("INSERT INTO people (id, full_name) VALUES ('p1', 'राम सिंह');")
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                 "VALUES ('e1', 'p1', 'received', 'recorded', 110000, '2026-11-20');")
    try:
        conn.execute("DELETE FROM people WHERE id='p1';")
        assert_test("ON DELETE RESTRICT prevents deleting person with transactions", False)
    except sqlite3.IntegrityError:
        assert_test("ON DELETE RESTRICT prevents deleting person with transactions", True)

    # Foreign key cascade test for entry items
    conn.execute("INSERT INTO entry_items (id, entry_id, item_name, quantity) VALUES ('item1', 'e1', 'चाँदी का सिक्का', 1);")
    conn.execute("DELETE FROM entries WHERE id='e1';")
    cursor.execute("SELECT count(*) FROM entry_items WHERE entry_id='e1';")
    assert_test("ON DELETE CASCADE automatically removes entry items when entry is deleted", cursor.fetchone()[0] == 0)

    # CHECK constraints test
    try:
        conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                     "VALUES ('e_bad', 'p1', 'invalid_dir', 'recorded', 100, '2026-11-20');")
        assert_test("Invalid direction is rejected by CHECK constraint", False)
    except sqlite3.IntegrityError:
        assert_test("Invalid direction is rejected by CHECK constraint", True)

    try:
        conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                     "VALUES ('e_bad', 'p1', 'given', 'invalid_status', 100, '2026-11-20');")
        assert_test("Invalid status is rejected by CHECK constraint", False)
    except sqlite3.IntegrityError:
        assert_test("Invalid status is rejected by CHECK constraint", True)

    print("\n⚛️ 3. Atomic Multi-Item Transaction & Rollback:")
    # Atomic transaction success
    try:
        with conn:
            conn.execute("INSERT INTO entries (id, person_id, direction, transaction_type, status, amount_paise, transaction_date) "
                         "VALUES ('atomic_1', 'p1', 'received', 'cash_and_item', 'recorded', 210000, '2026-11-21');")
            conn.execute("INSERT INTO entry_items (id, entry_id, item_name, estimated_value_paise) VALUES ('ai_1', 'atomic_1', 'साड़ी', 200000);")
            conn.execute("INSERT INTO entry_items (id, entry_id, item_name, estimated_value_paise) VALUES ('ai_2', 'atomic_1', 'मिठाई', 50000);")
        assert_test("Multi-item entry saved atomically inside database transaction", True)
    except Exception as e:
        assert_test("Multi-item entry saved atomically inside database transaction", False)

    # Atomic transaction failure and rollback
    try:
        with conn:
            conn.execute("INSERT INTO entries (id, person_id, direction, transaction_type, status, amount_paise, transaction_date) "
                         "VALUES ('atomic_2', 'p1', 'given', 'cash_and_item', 'recorded', 50100, '2026-11-21');")
            conn.execute("INSERT INTO entry_items (id, entry_id, item_name) VALUES ('ai_3', 'atomic_2', 'बर्तन सेट');")
            # Force integrity error (duplicate PK)
            conn.execute("INSERT INTO entry_items (id, entry_id, item_name) VALUES ('ai_3', 'atomic_2', 'कपड़े');")
    except sqlite3.IntegrityError:
        pass

    cursor.execute("SELECT count(*) FROM entries WHERE id='atomic_2';")
    assert_test("Atomic rollback guarantees zero partial records on transaction failure", cursor.fetchone()[0] == 0)

    print("\n💰 4. Financial Calculation & Isolation Rules:")
    # Seed financial dataset:
    # Received: ₹2,100 (atomic_1, 210000 paise) + ₹1,000 (100000 paise)
    # Given: ₹500 (50000 paise)
    # Planned Given: ₹5,000 (500000 paise) -> Must be excluded
    # Cancelled Received: ₹10,000 (1000000 paise) -> Must be excluded
    # Archived Given: ₹2,000 (200000 paise) -> Must be excluded
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                 "VALUES ('fin_rec', 'p1', 'received', 'recorded', 100000, '2026-11-20');")
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                 "VALUES ('fin_giv', 'p1', 'given', 'recorded', 50000, '2026-11-20');")
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                 "VALUES ('fin_plan', 'p1', 'given', 'planned', 500000, '2026-12-01');")
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date) "
                 "VALUES ('fin_canc', 'p1', 'received', 'cancelled', 1000000, '2026-11-19');")
    conn.execute("INSERT INTO entries (id, person_id, direction, status, amount_paise, transaction_date, archived_at) "
                 "VALUES ('fin_arch', 'p1', 'given', 'recorded', 200000, '2026-11-18', datetime('now'));")

    cursor.execute("SELECT SUM(amount_paise) FROM entries WHERE direction IN ('received', 'mila') "
                   "AND status='recorded' AND archived_at IS NULL;")
    total_received = cursor.fetchone()[0]
    # Expected: 210000 + 100000 = 310000 paise (₹3,100)
    assert_test("Total Received (मिला) calculates pure cash without netting Given", total_received == 310000)

    cursor.execute("SELECT SUM(amount_paise) FROM entries WHERE direction IN ('given', 'diya') "
                   "AND status='recorded' AND archived_at IS NULL;")
    total_given = cursor.fetchone()[0]
    # Expected: 50000 paise (₹500)
    assert_test("Total Given (दिया) calculates pure cash without planned or cancelled entries", total_given == 50000)

    cursor.execute("SELECT SUM(estimated_value_paise) FROM entry_items;")
    total_gifts = cursor.fetchone()[0]
    # Expected: 200000 + 50000 = 250000 paise (₹2,500)
    assert_test("Physical gift estimates are strictly isolated from cash totals", total_gifts == 250000 and total_received == 310000)

    print("\n⚡ 5. Realistic Scale Performance Stress Test (31,700 Records):")
    # Generate 200 families, 1,000 people, 500 events, 10,000 entries, 20,000 entry items
    t_start = time.perf_counter()
    with conn:
        # Families
        fam_tuples = [(f"fam_{i}", f"परिवार {i}", "विवरण", datetime_now()) for i in range(200)]
        conn.executemany("INSERT INTO families (id, name, description, created_at) VALUES (?, ?, ?, ?);", fam_tuples)

        # People
        people_tuples = [(f"p_{i}", f"fam_{i % 200}", f"व्यक्ति {i}", f"98000{i:05d}", "मामा", "गाँव", datetime_now()) for i in range(1000)]
        conn.executemany("INSERT INTO people (id, family_id, full_name, phone_number, relationship_label, address, created_at) VALUES (?, ?, ?, ?, ?, ?, ?);", people_tuples)

        # Events
        event_tuples = [(f"ev_{i}", f"कार्यक्रम {i}", "शादी", "2026-11-20", "मंडप", datetime_now()) for i in range(500)]
        conn.executemany("INSERT INTO events (id, title, event_type, event_date, venue, created_at) VALUES (?, ?, ?, ?, ?, ?);", event_tuples)

        # Entries (10,000)
        entry_tuples = [
            (
                f"ent_{i}",
                f"p_{i % 1000}",
                f"ev_{i % 500}",
                "received" if i % 2 == 0 else "given",
                "cash_and_item" if i % 3 == 0 else "cash",
                "recorded" if i % 10 != 0 else "planned",
                110000 if i % 2 == 0 else 50100,
                f"2026-{(i%12)+1:02d}-{(i%28)+1:02d}",
                datetime_now()
            )
            for i in range(10000)
        ]
        conn.executemany(
            "INSERT INTO entries (id, person_id, event_id, direction, transaction_type, status, amount_paise, transaction_date, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);",
            entry_tuples
        )

        # Entry Items (20,000)
        item_tuples = [
            (f"itm_{i}", f"ent_{i % 10000}", f"सामान {i}", 1.0, 50000, datetime_now())
            for i in range(20000)
        ]
        conn.executemany(
            "INSERT INTO entry_items (id, entry_id, item_name, quantity, estimated_value_paise, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?);",
            item_tuples
        )

    insert_duration = (time.perf_counter() - t_start) * 1000
    print(f"    → Inserted 31,700 records in {insert_duration:.1f}ms")
    assert_test("Batch insert of 31,700 records completes quickly", insert_duration < 5000)

    # Benchmark: Financial Aggregation Query across 10,000 transactions
    t_query = time.perf_counter()
    cursor.execute("""
        SELECT 
            SUM(CASE WHEN direction='received' THEN amount_paise ELSE 0 END),
            SUM(CASE WHEN direction='given' THEN amount_paise ELSE 0 END),
            COUNT(*)
        FROM entries 
        WHERE status='recorded' AND archived_at IS NULL;
    """)
    res = cursor.fetchone()
    query_duration = (time.perf_counter() - t_query) * 1000
    print(f"    → Financial aggregation over 10,000 transactions executed in {query_duration:.2f}ms")
    assert_test("Aggregation query executes in under 20ms using indexes", query_duration < 20)

    # Benchmark: Person History Query with JOIN
    t_join = time.perf_counter()
    cursor.execute("""
        SELECT e.id, e.direction, e.amount_paise, e.transaction_date, ev.title, count(ei.id)
        FROM entries e
        LEFT JOIN events ev ON e.event_id = ev.id
        LEFT JOIN entry_items ei ON e.id = ei.entry_id
        WHERE e.person_id = 'p_42' AND e.archived_at IS NULL
        GROUP BY e.id
        ORDER BY e.transaction_date DESC;
    """)
    history_rows = cursor.fetchall()
    join_duration = (time.perf_counter() - t_join) * 1000
    print(f"    → Person history query with JOINs executed in {join_duration:.2f}ms ({len(history_rows)} records)")
    assert_test("Person history query with JOINs executes in under 15ms", join_duration < 15)

    print("\n" + "=" * 60)
    print(f"Results: {passed_tests}/{total_tests} tests passed successfully!")
    print("🎉 ALL DATABASE ARCHITECTURE TESTS PASSED WITH 100% SUCCESS!")
    print("=" * 60)

def datetime_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

if __name__ == "__main__":
    run_tests()
