import { getDb, DEFAULT_HOUSEHOLD_ID } from '../database/db';

export interface DashboardSummary {
  totalMilaPaise: number;      // Total received (recorded only)
  totalDiyaPaise: number;      // Total given (recorded only)
  totalEntries: number;        // Total non-deleted recorded entries
  totalPlannedEntries: number; // Total planned entries
  totalEvents: number;         // Total events
  totalPeople: number;         // Total people
  recentEventId: string | null;
  recentEventTitle: string | null;
  recentEventDate: string | null;
}

export interface EventSummary {
  eventId: string;
  eventTitle: string;
  totalMilaPaise: number;
  totalDiyaPaise: number;
  entryCount: number;
}

export interface PersonSummary {
  personId: string;
  personName: string;
  totalMilaPaise: number;
  totalDiyaPaise: number;
  entryCount: number;
  plannedCount: number;
}

export class SummaryService {
  static getDashboardSummary(): DashboardSummary {
    const db = getDb();

    // Financial totals ONLY include 'recorded' entries
    const milaStat = db.getFirstSync<{ total: number; count: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total, COUNT(*) as count
       FROM entries WHERE household_id = ? AND direction = 'mila' AND status = 'recorded' AND deleted_at IS NULL`,
      DEFAULT_HOUSEHOLD_ID
    );
    const diyaStat = db.getFirstSync<{ total: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total
       FROM entries WHERE household_id = ? AND direction = 'diya' AND status = 'recorded' AND deleted_at IS NULL`,
      DEFAULT_HOUSEHOLD_ID
    );
    const plannedStat = db.getFirstSync<{ count: number }>(
      `SELECT COUNT(*) as count
       FROM entries WHERE household_id = ? AND status = 'planned' AND deleted_at IS NULL`,
      DEFAULT_HOUSEHOLD_ID
    );
    const eventStat = db.getFirstSync<{ count: number }>(
      'SELECT COUNT(*) as count FROM events WHERE household_id = ?',
      DEFAULT_HOUSEHOLD_ID
    );
    const peopleStat = db.getFirstSync<{ count: number }>(
      'SELECT COUNT(*) as count FROM people WHERE household_id = ?',
      DEFAULT_HOUSEHOLD_ID
    );
    const recentEvent = db.getFirstSync<{ id: string; title: string; event_date: string }>(
      `SELECT id, title, event_date FROM events WHERE household_id = ? ORDER BY event_date DESC LIMIT 1`,
      DEFAULT_HOUSEHOLD_ID
    );

    return {
      totalMilaPaise: milaStat?.total ?? 0,
      totalDiyaPaise: diyaStat?.total ?? 0,
      totalEntries: milaStat?.count ?? 0,
      totalPlannedEntries: plannedStat?.count ?? 0,
      totalEvents: eventStat?.count ?? 0,
      totalPeople: peopleStat?.count ?? 0,
      recentEventId: recentEvent?.id ?? null,
      recentEventTitle: recentEvent?.title ?? null,
      recentEventDate: recentEvent?.event_date ?? null,
    };
  }

  static getEventSummary(eventId: string): EventSummary | null {
    const db = getDb();
    const event = db.getFirstSync<{ id: string; title: string }>(
      'SELECT id, title FROM events WHERE id = ?',
      eventId
    );
    if (!event) return null;

    const milaStat = db.getFirstSync<{ total: number; count: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total, COUNT(*) as count
       FROM entries WHERE event_id = ? AND direction = 'mila' AND status = 'recorded' AND deleted_at IS NULL`,
      eventId
    );
    const diyaStat = db.getFirstSync<{ total: number }>(
      `SELECT COALESCE(SUM(cash_amount_paise), 0) as total
       FROM entries WHERE event_id = ? AND direction = 'diya' AND status = 'recorded' AND deleted_at IS NULL`,
      eventId
    );

    return {
      eventId: event.id,
      eventTitle: event.title,
      totalMilaPaise: milaStat?.total ?? 0,
      totalDiyaPaise: diyaStat?.total ?? 0,
      entryCount: milaStat?.count ?? 0,
    };
  }

  static getPersonSummaries(): PersonSummary[] {
    const db = getDb();
    return db.getAllSync<PersonSummary>(
      `SELECT
        p.id as personId,
        p.name as personName,
        COALESCE(SUM(CASE WHEN e.direction = 'mila' AND e.status = 'recorded' THEN e.cash_amount_paise ELSE 0 END), 0) as totalMilaPaise,
        COALESCE(SUM(CASE WHEN e.direction = 'diya' AND e.status = 'recorded' THEN e.cash_amount_paise ELSE 0 END), 0) as totalDiyaPaise,
        COUNT(CASE WHEN e.status = 'recorded' THEN e.id ELSE NULL END) as entryCount,
        COUNT(CASE WHEN e.status = 'planned' THEN e.id ELSE NULL END) as plannedCount
       FROM people p
       LEFT JOIN entries e ON p.id = e.person_id AND e.deleted_at IS NULL
       WHERE p.household_id = ?
       GROUP BY p.id
       ORDER BY p.name ASC`,
      DEFAULT_HOUSEHOLD_ID
    );
  }
}
