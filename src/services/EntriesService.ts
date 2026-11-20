import { getDb, DEFAULT_HOUSEHOLD_ID, withTransaction } from '../database/db';
import { generateId } from '../utils/uuid';
import type { Entry, EntryItem, EntryStatus } from '../types';
import type { CreateEntryInput } from '../validation/schemas';

export class EntriesService {
  static getByEvent(eventId: string, options?: { status?: EntryStatus }): Entry[] {
    const db = getDb();
    let sql = `SELECT e.*,
        p.name as person_name,
        p.village as person_village,
        p.relationship as person_relationship,
        p.phone as person_phone,
        ev.title as event_title,
        ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.event_id = ? AND e.deleted_at IS NULL`;
    const params: (string | number)[] = [eventId];
    if (options?.status) {
      sql += ' AND e.status = ?';
      params.push(options.status);
    }
    sql += ' ORDER BY e.created_at DESC';
    return db.getAllSync<Entry>(sql, ...params);
  }

  static getByPerson(personId: string, options?: { status?: EntryStatus }): Entry[] {
    const db = getDb();
    let sql = `SELECT e.*,
        p.name as person_name,
        p.village as person_village,
        ev.title as event_title,
        ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.person_id = ? AND e.deleted_at IS NULL`;
    const params: (string | number)[] = [personId];
    if (options?.status) {
      sql += ' AND e.status = ?';
      params.push(options.status);
    }
    sql += ' ORDER BY e.created_at DESC';
    return db.getAllSync<Entry>(sql, ...params);
  }

  static getAll(filters?: { direction?: 'mila' | 'diya'; eventId?: string; status?: EntryStatus; startDate?: string; endDate?: string }): Entry[] {
    const db = getDb();
    let sql = `SELECT e.*,
        p.name as person_name,
        p.village as person_village,
        p.relationship as person_relationship,
        ev.title as event_title,
        ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.household_id = ? AND e.deleted_at IS NULL`;
    const params: (string | number)[] = [DEFAULT_HOUSEHOLD_ID];
    if (filters?.direction) { sql += ' AND e.direction = ?'; params.push(filters.direction); }
    if (filters?.eventId) { sql += ' AND e.event_id = ?'; params.push(filters.eventId); }
    if (filters?.status) {
      sql += ' AND e.status = ?';
      params.push(filters.status);
    } else {
      // By default, exclude cancelled entries from general listing unless explicitly requested
      sql += " AND e.status != 'cancelled'";
    }
    if (filters?.startDate) {
      sql += ' AND (e.expected_date >= ? OR ev.event_date >= ?)';
      params.push(filters.startDate, filters.startDate);
    }
    if (filters?.endDate) {
      sql += ' AND (e.expected_date <= ? OR ev.event_date <= ?)';
      params.push(filters.endDate, filters.endDate);
    }
    sql += ' ORDER BY e.created_at DESC';
    return db.getAllSync<Entry>(sql, ...params);
  }

  static getById(id: string): Entry | null {
    const db = getDb();
    const entry = db.getFirstSync<Entry>(
      `SELECT e.*,
        p.name as person_name,
        p.village as person_village,
        p.relationship as person_relationship,
        p.phone as person_phone,
        ev.title as event_title,
        ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.id = ? AND e.deleted_at IS NULL`,
      id
    );
    if (!entry) return null;
    entry.items = this.getItems(id);
    return entry;
  }

  static getItems(entryId: string): EntryItem[] {
    const db = getDb();
    return db.getAllSync<EntryItem>(
      'SELECT * FROM entry_items WHERE entry_id = ? ORDER BY created_at ASC',
      entryId
    );
  }

  static create(input: CreateEntryInput & { status?: EntryStatus; expected_date?: string }): Entry {
    const entryId = generateId();
    const now = new Date().toISOString();
    const status: EntryStatus = input.status || 'recorded';

    withTransaction(() => {
      const db = getDb();
      db.runSync(
        `INSERT INTO entries (id, household_id, event_id, person_id, direction, cash_amount_paise, status, expected_date, notes, created_at, updated_at, sync_status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'local')`,
        entryId,
        DEFAULT_HOUSEHOLD_ID,
        input.event_id,
        input.person_id,
        input.direction,
        input.cash_amount_paise,
        status,
        input.expected_date ?? null,
        input.notes ?? null,
        now,
        now
      );
      for (const item of input.items ?? []) {
        const itemId = generateId();
        db.runSync(
          `INSERT INTO entry_items (id, entry_id, item_name, quantity, unit, estimated_value_paise, condition, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          itemId,
          entryId,
          item.item_name,
          item.quantity,
          item.unit ?? 'संख्या',
          item.estimated_value_paise ?? null,
          item.condition ?? null,
          now
        );
      }
    });

    return this.getById(entryId)!;
  }

  static updateStatus(id: string, newStatus: EntryStatus): void {
    const db = getDb();
    const now = new Date().toISOString();
    db.runSync(
      'UPDATE entries SET status = ?, updated_at = ? WHERE id = ? AND household_id = ?',
      newStatus,
      now,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static softDelete(id: string): void {
    const db = getDb();
    const now = new Date().toISOString();
    db.runSync(
      'UPDATE entries SET deleted_at = ?, sync_status = ? WHERE id = ? AND household_id = ?',
      now,
      'local',
      id,
      DEFAULT_HOUSEHOLD_ID
    );
  }
}
