import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';
import { generateId } from '../utils/uuid';
import type { Person } from '../types';
import type { CreatePersonInput } from '../validation/schemas';

export class PeopleService {
  static getAll(): Person[] {
    const db = getDb();
    return db.getAllSync<Person>(
      `SELECT p.*, f.name as family_name
       FROM people p
       LEFT JOIN families f ON p.family_id = f.id
       WHERE p.household_id = ?
       ORDER BY p.name ASC`,
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static getById(id: string): Person | null {
    const db = getDb();
    return db.getFirstSync<Person>(
      `SELECT p.*, f.name as family_name
       FROM people p
       LEFT JOIN families f ON p.family_id = f.id
       WHERE p.id = ? AND p.household_id = ?`,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static search(query: string): Person[] {
    const db = getDb();
    const like = `%${query}%`;
    return db.getAllSync<Person>(
      `SELECT * FROM people
       WHERE household_id = ? AND (name LIKE ? OR village LIKE ? OR relationship LIKE ?)
       ORDER BY name ASC`,
      DEFAULT_HOUSEHOLD_ID,
      like,
      like,
      like
    );
  }

  static create(input: CreatePersonInput): Person {
    const db = getDb();
    const id = generateId();
    const now = new Date().toISOString();
    db.runSync(
      `INSERT INTO people (id, household_id, family_id, name, village, relationship, phone, notes, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      DEFAULT_HOUSEHOLD_ID,
      input.family_id ?? null,
      input.name,
      input.village ?? null,
      input.relationship ?? null,
      input.phone ?? null,
      input.notes ?? null,
      now,
      now
    );
    return this.getById(id)!;
  }

  static update(id: string, input: Partial<CreatePersonInput>): Person | null {
    const db = getDb();
    const now = new Date().toISOString();
    db.runSync(
      `UPDATE people SET
        name = COALESCE(?, name),
        family_id = COALESCE(?, family_id),
        village = COALESCE(?, village),
        relationship = COALESCE(?, relationship),
        phone = COALESCE(?, phone),
        notes = COALESCE(?, notes),
        updated_at = ?
       WHERE id = ? AND household_id = ?`,
      input.name ?? null,
      input.family_id ?? null,
      input.village ?? null,
      input.relationship ?? null,
      input.phone ?? null,
      input.notes ?? null,
      now,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
    return this.getById(id);
  }

  static getWithHistory(id: string): { person: Person | null; totalMilaPaise: number; totalDiyaPaise: number; entryCount: number } {
    const db = getDb();
    const person = this.getById(id);
    if (!person) return { person: null, totalMilaPaise: 0, totalDiyaPaise: 0, entryCount: 0 };

    const milaStat = db.getFirstSync<{ total: number; count: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total, COUNT(*) as count
       FROM entries WHERE person_id = ? AND direction = 'mila' AND deleted_at IS NULL`,
      id
    );
    const diyaStat = db.getFirstSync<{ total: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total
       FROM entries WHERE person_id = ? AND direction = 'diya' AND deleted_at IS NULL`,
      id
    );
    return {
      person,
      totalMilaPaise: milaStat?.total ?? 0,
      totalDiyaPaise: diyaStat?.total ?? 0,
      entryCount: milaStat?.count ?? 0,
    };
  }
}
