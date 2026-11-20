import { 
  Household, Person, Event, Entry, EntryItem, Reminder, DashboardSummary, Direction 
} from '../types';
import { CREATE_TABLES_SQL } from './schema';

let SQLite: any = null;
try {
  SQLite = require('expo-sqlite');
} catch (e) {
  // SQLite will be loaded if available in native runtime
}

const DEFAULT_HOUSEHOLD_ID = 'household_primary_01';

// In-Memory store for fast local operations and fallback
class LocalVyavahaarDB {
  private db: any = null;
  private memoryHouseholds: Map<string, Household> = new Map();
  private memoryPeople: Map<string, Person> = new Map();
  private memoryEvents: Map<string, Event> = new Map();
  private memoryEntries: Map<string, Entry> = new Map();
  private memoryItems: Map<string, EntryItem[]> = new Map();
  private memoryReminders: Map<string, Reminder> = new Map();
  private isInitialized = false;

  async init(): Promise<void> {
    if (this.isInitialized) return;

    if (SQLite && SQLite.openDatabaseSync) {
      try {
        this.db = SQLite.openDatabaseSync('vyavahaar.db');
        this.db.execSync(CREATE_TABLES_SQL);
      } catch (err) {
        console.warn('SQLite init fallback to in-memory store:', err);
      }
    }

    // Seed default household
    this.memoryHouseholds.set(DEFAULT_HOUSEHOLD_ID, {
      id: DEFAULT_HOUSEHOLD_ID,
      name: 'हमारा परिवार',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    // Seed initial realistic data matching PRD example if empty
    if (this.memoryEvents.size === 0) {
      await this.seedInitialData();
    }

    this.isInitialized = true;
  }

  private async seedInitialData() {
    const p1: Person = {
      id: 'person_01',
      household_id: DEFAULT_HOUSEHOLD_ID,
      name: 'रामकिशोर शर्मा',
      village: 'रामपुर',
      relationship: 'चाचा',
      phone: '9876543210',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    const p2: Person = {
      id: 'person_02',
      household_id: DEFAULT_HOUSEHOLD_ID,
      name: 'सुरेश वर्मा',
      village: 'लखनऊ',
      relationship: 'मामा',
      phone: '9812345678',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    const p3: Person = {
      id: 'person_03',
      household_id: DEFAULT_HOUSEHOLD_ID,
      name: 'दिनेश यादव',
      village: 'कानपुर',
      relationship: 'मित्र',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    this.memoryPeople.set(p1.id, p1);
    this.memoryPeople.set(p2.id, p2);
    this.memoryPeople.set(p3.id, p3);

    const ev1: Event = {
      id: 'event_01',
      household_id: DEFAULT_HOUSEHOLD_ID,
      title: 'राहुल की शादी',
      event_type: 'शादी',
      event_date: '2026-02-18',
      notes: 'मुख्य विवाह समारोह',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    const ev2: Event = {
      id: 'event_02',
      household_id: DEFAULT_HOUSEHOLD_ID,
      title: 'अमित का तिलक',
      event_type: 'तिलक',
      event_date: '2026-03-05',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    this.memoryEvents.set(ev1.id, ev1);
    this.memoryEvents.set(ev2.id, ev2);

    // Entry 1: Ramkishore Sharma gave ₹1100 + Steel Bartan Set (Mila)
    const entry1: Entry = {
      id: 'entry_01',
      household_id: DEFAULT_HOUSEHOLD_ID,
      event_id: ev1.id,
      person_id: p1.id,
      direction: 'mila',
      cash_amount_paise: 110000, // ₹1,100
      notes: 'चाचा जी का व्यवहार',
      created_at: '2026-02-18T10:00:00Z',
      updated_at: '2026-02-18T10:00:00Z',
      sync_status: 'local',
      person_name: p1.name,
      person_village: p1.village,
      person_relationship: p1.relationship,
      event_title: ev1.title,
      event_date: ev1.event_date,
    };
    const items1: EntryItem[] = [
      {
        id: 'item_01',
        entry_id: entry1.id,
        item_name: 'स्टील बर्तन सेट',
        quantity: 1,
        unit: 'सेट',
        estimated_value_paise: 150000, // ₹1,500
        created_at: '2026-02-18T10:00:00Z',
      }
    ];
    entry1.items = items1;
    this.memoryEntries.set(entry1.id, entry1);
    this.memoryItems.set(entry1.id, items1);

    // Entry 2: Suresh Verma gave ₹2,100 (Mila)
    const entry2: Entry = {
      id: 'entry_02',
      household_id: DEFAULT_HOUSEHOLD_ID,
      event_id: ev1.id,
      person_id: p2.id,
      direction: 'mila',
      cash_amount_paise: 210000, // ₹2,100
      notes: 'मामा जी द्वारा शगुन',
      created_at: '2026-02-18T11:30:00Z',
      updated_at: '2026-02-18T11:30:00Z',
      sync_status: 'local',
      person_name: p2.name,
      person_village: p2.village,
      person_relationship: p2.relationship,
      event_title: ev1.title,
      event_date: ev1.event_date,
      items: [],
    };
    this.memoryEntries.set(entry2.id, entry2);
    this.memoryItems.set(entry2.id, []);

    // Entry 3: Diya ₹501 to Dinesh Yadav (Diya)
    const entry3: Entry = {
      id: 'entry_03',
      household_id: DEFAULT_HOUSEHOLD_ID,
      event_id: ev2.id,
      person_id: p3.id,
      direction: 'diya',
      cash_amount_paise: 50100, // ₹501
      notes: 'तिलक पर न्योता दिया',
      created_at: '2026-03-05T14:00:00Z',
      updated_at: '2026-03-05T14:00:00Z',
      sync_status: 'local',
      person_name: p3.name,
      person_village: p3.village,
      person_relationship: p3.relationship,
      event_title: ev2.title,
      event_date: ev2.event_date,
      items: [],
    };
    this.memoryEntries.set(entry3.id, entry3);
    this.memoryItems.set(entry3.id, []);

    // Reminder 1
    const rem1: Reminder = {
      id: 'rem_01',
      household_id: DEFAULT_HOUSEHOLD_ID,
      person_id: p1.id,
      event_title: 'चाचा जी के लड़के की शादी',
      target_date: '2026-11-25',
      note: 'पुरानी बही देख कर व्यवहार तय करें',
      is_completed: false,
      created_at: new Date().toISOString(),
      person_name: p1.name,
      person_village: p1.village,
    };
    this.memoryReminders.set(rem1.id, rem1);
  }

  // --- PEOPLE ---
  async getPeople(): Promise<Person[]> {
    await this.init();
    return Array.from(this.memoryPeople.values()).sort((a, b) => a.name.localeCompare(b.name));
  }

  async getPersonById(id: string): Promise<Person | null> {
    await this.init();
    return this.memoryPeople.get(id) || null;
  }

  async createPerson(person: Omit<Person, 'id' | 'household_id' | 'created_at' | 'updated_at'>): Promise<Person> {
    await this.init();
    const id = 'person_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
    const newPerson: Person = {
      ...person,
      id,
      household_id: DEFAULT_HOUSEHOLD_ID,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    this.memoryPeople.set(id, newPerson);
    return newPerson;
  }

  // --- EVENTS ---
  async getEvents(): Promise<Event[]> {
    await this.init();
    const list = Array.from(this.memoryEvents.values());
    return list.map(ev => {
      let mila = 0;
      let diya = 0;
      let count = 0;
      for (const entry of this.memoryEntries.values()) {
        if (entry.event_id === ev.id && !entry.deleted_at) {
          count++;
          if (entry.direction === 'mila') mila += entry.cash_amount_paise;
          else if (entry.direction === 'diya') diya += entry.cash_amount_paise;
        }
      }
      return {
        ...ev,
        total_mila_paise: mila,
        total_diya_paise: diya,
        total_entries_count: count,
      };
    }).sort((a, b) => b.event_date.localeCompare(a.event_date));
  }

  async getEventById(id: string): Promise<Event | null> {
    const events = await this.getEvents();
    return events.find(e => e.id === id) || null;
  }

  async createEvent(event: Omit<Event, 'id' | 'household_id' | 'created_at' | 'updated_at'>): Promise<Event> {
    await this.init();
    const id = 'event_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
    const newEvent: Event = {
      ...event,
      id,
      household_id: DEFAULT_HOUSEHOLD_ID,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      total_mila_paise: 0,
      total_diya_paise: 0,
      total_entries_count: 0,
    };
    this.memoryEvents.set(id, newEvent);
    return newEvent;
  }

  // --- ENTRIES & ITEMS ---
  async getEntries(filters?: {
    personId?: string;
    eventId?: string;
    direction?: Direction;
    searchQuery?: string;
  }): Promise<Entry[]> {
    await this.init();
    let entries = Array.from(this.memoryEntries.values()).filter(e => !e.deleted_at);

    if (filters?.personId) {
      entries = entries.filter(e => e.person_id === filters.personId);
    }
    if (filters?.eventId) {
      entries = entries.filter(e => e.event_id === filters.eventId);
    }
    if (filters?.direction) {
      entries = entries.filter(e => e.direction === filters.direction);
    }
    if (filters?.searchQuery) {
      const q = filters.searchQuery.toLowerCase().trim();
      entries = entries.filter(e => 
        (e.person_name && e.person_name.toLowerCase().includes(q)) ||
        (e.person_village && e.person_village.toLowerCase().includes(q)) ||
        (e.event_title && e.event_title.toLowerCase().includes(q)) ||
        (e.notes && e.notes.toLowerCase().includes(q))
      );
    }

    return entries.sort((a, b) => b.created_at.localeCompare(a.created_at));
  }

  async getEntryById(id: string): Promise<Entry | null> {
    await this.init();
    return this.memoryEntries.get(id) || null;
  }

  async createEntry(
    entry: Omit<Entry, 'id' | 'household_id' | 'created_at' | 'updated_at' | 'sync_status'>,
    items: Omit<EntryItem, 'id' | 'entry_id' | 'created_at'>[] = []
  ): Promise<Entry> {
    await this.init();
    const id = 'entry_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
    const person = this.memoryPeople.get(entry.person_id);
    const event = this.memoryEvents.get(entry.event_id);

    const fullItems: EntryItem[] = items.map((item, idx) => ({
      ...item,
      id: `item_${id}_${idx}`,
      entry_id: id,
      created_at: new Date().toISOString(),
    }));

    const newEntry: Entry = {
      ...entry,
      id,
      household_id: DEFAULT_HOUSEHOLD_ID,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      sync_status: 'local',
      person_name: person?.name || 'अज्ञात',
      person_village: person?.village || '',
      person_relationship: person?.relationship || '',
      event_title: event?.title || '',
      event_date: event?.event_date || '',
      items: fullItems,
    };

    this.memoryEntries.set(id, newEntry);
    this.memoryItems.set(id, fullItems);
    return newEntry;
  }

  async deleteEntry(id: string): Promise<boolean> {
    await this.init();
    const entry = this.memoryEntries.get(id);
    if (!entry) return false;
    entry.deleted_at = new Date().toISOString();
    return true;
  }

  // --- REMINDERS ---
  async getReminders(): Promise<Reminder[]> {
    await this.init();
    return Array.from(this.memoryReminders.values()).sort((a, b) => a.target_date.localeCompare(b.target_date));
  }

  async createReminder(reminder: Omit<Reminder, 'id' | 'household_id' | 'created_at'>): Promise<Reminder> {
    await this.init();
    const id = 'rem_' + Date.now();
    const person = this.memoryPeople.get(reminder.person_id);
    const newRem: Reminder = {
      ...reminder,
      id,
      household_id: DEFAULT_HOUSEHOLD_ID,
      created_at: new Date().toISOString(),
      person_name: person?.name,
      person_village: person?.village,
    };
    this.memoryReminders.set(id, newRem);
    return newRem;
  }

  // --- DASHBOARD SUMMARY ---
  async getDashboardSummary(): Promise<DashboardSummary> {
    await this.init();
    const allEntries = await this.getEntries();
    let totalMila = 0;
    let totalDiya = 0;

    for (const e of allEntries) {
      if (e.direction === 'mila') {
        totalMila += e.cash_amount_paise;
      } else if (e.direction === 'diya') {
        totalDiya += e.cash_amount_paise;
      }
    }

    return {
      totalMilaPaise: totalMila,
      totalDiyaPaise: totalDiya,
      totalEventsCount: this.memoryEvents.size,
      totalPeopleCount: this.memoryPeople.size,
      totalEntriesCount: allEntries.length,
      recentEntries: allEntries.slice(0, 10),
    };
  }

  // --- BACKUP & EXPORT ---
  async exportBackupJson(): Promise<string> {
    await this.init();
    const data = {
      version: '1.0',
      exported_at: new Date().toISOString(),
      households: Array.from(this.memoryHouseholds.values()),
      people: Array.from(this.memoryPeople.values()),
      events: Array.from(this.memoryEvents.values()),
      entries: Array.from(this.memoryEntries.values()),
      items: Array.from(this.memoryItems.values()).flat(),
      reminders: Array.from(this.memoryReminders.values()),
    };
    return JSON.stringify(data, null, 2);
  }

  async restoreBackupJson(jsonString: string): Promise<boolean> {
    try {
      const data = JSON.parse(jsonString);
      if (!data.people || !data.events || !data.entries) return false;
      this.memoryPeople.clear();
      this.memoryEvents.clear();
      this.memoryEntries.clear();
      this.memoryItems.clear();
      this.memoryReminders.clear();

      data.people.forEach((p: Person) => this.memoryPeople.set(p.id, p));
      data.events.forEach((ev: Event) => this.memoryEvents.set(ev.id, ev));
      data.entries.forEach((e: Entry) => this.memoryEntries.set(e.id, e));
      data.reminders?.forEach((r: Reminder) => this.memoryReminders.set(r.id, r));
      return true;
    } catch {
      return false;
    }
  }
}

export const db = new LocalVyavahaarDB();
