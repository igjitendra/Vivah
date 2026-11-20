import { getDb, DEFAULT_HOUSEHOLD_ID, withTransaction } from '../database/db';
import { generateId } from '../utils/uuid';
import type { Entry, EntryItem } from '../types';
import type { CreateEntryInput } from '../validation/schemas';

export class EntriesService {
  static getByEvent(eventId: string): Entry[] {
    const db = getDb();
    return db.getAllSync<Entry>(
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
       WHERE e.event_id = ? AND e.deleted_at IS NULL
       ORDER BY e.created_at DESC`,
      eventId
    );
  }

  static getByPerson(personId: string): Entry[] {
    const db = getDb();
    return db.getAllSync<Entry>(
      `SELECT e.*,
        p.name as person_name,
        p.village as person_village,
        ev.title as event_title,
        ev.event_date as event_date
       FROM entries e
       JOIN people p ON e.person_id = p.id
       JOIN events ev ON e.event_id = ev.id
       WHERE e.person_id = ? AND e.deleted_at IS NULL
       ORDER BY e.created_at DESC`,
      personId
    );
  }

  static getAll(filters?: { direction?: 'mila' | 'diya'; eventId?: string }): Entry[] {
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

  static create(input: CreateEntryInput): Entry {
    const entryId = generateId();
    const now = new Date().toISOString();

    withTransaction(() => {
      const db = getDb();
      db.runSync(
        `INSERT INTO entries (id, household_id, event_id, person_id, direction, cash_amount_paise, notes, created_at, updated_at, sync_status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'local')`,
        entryId,
        DEFAULT_HOUSEHOLD_ID,
        input.event_id,
        input.person_id,
        input.direction,
        input.cash_amount_paise,
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
