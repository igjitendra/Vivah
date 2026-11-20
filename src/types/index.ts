export type Direction = 'mila' | 'diya'; // मिला (Received) or दिया (Given)

export type EventType = 'शादी' | 'तिलक' | 'मुंडन' | 'बरात' | 'सगाई' | 'वर्षगांठ' | 'गृह प्रवेश' | 'अन्य';

export type EntryStatus = 'planned' | 'recorded' | 'cancelled';

export interface Household {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface Family {
  id: string;
  household_id: string;
  name: string;
  village?: string;
  created_at: string;
}

export interface Person {
  id: string;
  household_id: string;
  family_id?: string;
  name: string;
  village?: string;
  relationship?: string;
  phone?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface Event {
  id: string;
  household_id: string;
  title: string;
  event_type: EventType;
  event_date: string; // YYYY-MM-DD
  person_id?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
  // Computed stats
  total_mila_paise?: number;
  total_diya_paise?: number;
  total_entries_count?: number;
}

export interface EntryItem {
  id: string;
  entry_id: string;
  item_name: string;
  quantity: number;
  unit: string; // 'संख्या', 'सेट', 'किलो', 'ग्राम', 'थान'
  estimated_value_paise?: number | null; // optional estimated value
  condition?: string;
  created_at: string;
}

export interface Entry {
  id: string;
  household_id: string;
  event_id: string;
  person_id: string;
  direction: Direction;
  cash_amount_paise: number; // e.g. 110000 = ₹1100
  status: EntryStatus; // 'planned' | 'recorded' | 'cancelled'
  expected_date?: string; // YYYY-MM-DD for planned vyavahaar
  notes?: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
  sync_status: 'local' | 'pending_sync' | 'synced';
  // Joined fields
  person_name?: string;
  person_village?: string;
  person_relationship?: string;
  person_phone?: string;
  event_title?: string;
  event_date?: string;
  items?: EntryItem[];
}

export interface Reminder {
  id: string;
  household_id: string;
  person_id: string;
  event_title: string;
  target_date: string;
  note?: string;
  is_completed: boolean;
  created_at: string;
  person_name?: string;
  person_village?: string;
}

export interface DashboardSummary {
  totalMilaPaise: number;
  totalDiyaPaise: number;
  totalEventsCount: number;
  totalPeopleCount: number;
  totalEntriesCount: number;
  recentEntries: Entry[];
}
