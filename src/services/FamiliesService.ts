import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';
import { generateId } from '../utils/uuid';
import type { Family } from '../types';
import type { CreateFamilyInput } from '../validation/schemas';

export class FamiliesService {
  static getAll(): Family[] {
    const db = getDb();
    return db.getAllSync<Family>(
      'SELECT * FROM families WHERE household_id = ? ORDER BY name ASC',
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static getById(id: string): Family | null {
    const db = getDb();
    return db.getFirstSync<Family>(
      'SELECT * FROM families WHERE id = ? AND household_id = ?',
      id,
      DEFAULT_HOUSEHOLD_ID
    );
  }

  static create(input: CreateFamilyInput): Family {
    const db = getDb();
    const id = generateId();
    const now = new Date().toISOString();
    db.runSync(
      'INSERT INTO families (id, household_id, name, village, created_at) VALUES (?, ?, ?, ?, ?)',
      id,
      DEFAULT_HOUSEHOLD_ID,
      input.name,
      input.village ?? null,
      now
    );
    return this.getById(id)!;
  }

  static update(id: string, input: Partial<CreateFamilyInput>): Family | null {
    const db = getDb();
    db.runSync(
      `UPDATE families SET
        name = COALESCE(?, name),
        village = COALESCE(?, village)
       WHERE id = ? AND household_id = ?`,
      input.name ?? null,
      input.village ?? null,
      id,
      DEFAULT_HOUSEHOLD_ID
    );
    return this.getById(id);
  }

  static getMembersCount(familyId: string): number {
    const db = getDb();
    const result = db.getFirstSync<{ count: number }>(
      'SELECT COUNT(*) as count FROM people WHERE family_id = ? AND household_id = ?',
      familyId,
      DEFAULT_HOUSEHOLD_ID
    );
    return result?.count ?? 0;
  }
}
