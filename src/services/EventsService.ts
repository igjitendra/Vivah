import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';
import { generateId } from '../utils/uuid';
import type { Event } from '../types';
import type { CreateEventInput } from '../validation/schemas';

export class EventsService {
  static getAll(): Event[] {
    const db = getDb();
    const events = db.getAllSync<Event>(
      `SELECT e.*,
        p.name as person_name,
        (SELECT COALESCE(SUM(cash_amount_paise), 0) FROM entries WHERE event_id = e.id AND direction = 'mila' AND deleted_at IS NULL) as total_mila_paise,
        (SELECT COALESCE(SUM(cash_amount_paise), 0) FROM entries WHERE event_id = e.id AND direction = 'diya' AND deleted_at IS NULL) as total_diya_paise,
        (SELECT COUNT(*) FROM entries WHERE event_id = e.id AND deleted_at IS NULL) as total_entries_count
       FROM events e
       LEFT JOIN people p ON e.person_id = p.id
       WHERE e.household_id = ?
       ORDER BY e.event_date DESC`,
      DEFAULT_HOUSEHOLD_ID
    );
    return events;
  }

  static getById(id: string): Event | null {
    const db = getDb();
    return db.getFirstSync<Event>(
      `SELECT e.*,
        p.name as person_name,
        (SELECT COALESCE(SUM(cash_amount_paise), 0) FROM entries WHERE event_id = e.id AND direction = 'mila' AND deleted_at IS NULL) as total_mila_paise,
        (SELECT COALESCE(SUM(cash_amount_paise), 0) FROM entries WHERE event_id = e.id AND direction = 'diya' AND deleted_at IS NULL) as total_diya_paise,
        (SELECT COUNT(*) FROM entries WHERE event_id = e.id AND deleted_at IS NULL) as total_entries_count
       FROM events e
       LEFT JOIN people p ON e.person_id = p.id
       WHERE e.id = ? AND e.household_id = ?`,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static create(input: CreateEventInput): Event {
    const db = getDb();
    const id = generateId();
    const now = new Date().toISOString();
    db.runSync(
      `INSERT INTO events (id, household_id, title, event_type, event_date, person_id, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      DEFAULT_HOUSEHOLD_ID,
      input.title,
      input.event_type,
      input.event_date,
      input.person_id ?? null,
      input.notes ?? null,
      now,
      now
    );
    return this.getById(id)!;
  }

  static update(id: string, input: Partial<CreateEventInput>): Event | null {
    const db = getDb();
    const now = new Date().toISOString();
    db.runSync(
      `UPDATE events SET
        title = COALESCE(?, title),
        event_type = COALESCE(?, event_type),
        event_date = COALESCE(?, event_date),
        person_id = COALESCE(?, person_id),
        notes = COALESCE(?, notes),
        updated_at = ?
       WHERE id = ? AND household_id = ?`,
      input.title ?? null,
      input.event_type ?? null,
      input.event_date ?? null,
      input.person_id ?? null,
      input.notes ?? null,
      now,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
    return this.getById(id);
  }

  static getUpcoming(): Event[] {
    const db = getDb();
    const today = new Date().toISOString().split('T')[0];
    return db.getAllSync<Event>(
      `SELECT * FROM events WHERE household_id = ? AND event_date >= ? ORDER BY event_date ASC LIMIT 5`,
      DEFAULT_HOUSEHOLD_ID,
      today
    );
  }
}
