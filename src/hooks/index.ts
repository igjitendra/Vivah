import { useState, useEffect, useCallback } from 'react';
import { SummaryService, type DashboardSummary } from '../services/SummaryService';
import { PeopleService } from '../services/PeopleService';
import { FamiliesService } from '../services/FamiliesService';
import { EventsService } from '../services/EventsService';
import { EntriesService } from '../services/EntriesService';
import type { Person, Family, Event, Entry } from '../types';

export function useDashboard() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      const data = SummaryService.getDashboardSummary();
      setSummary(data);
      setError(null);
    } catch (e) {
      setError('डेटा लोड नहीं हो सका');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refresh(); }, [refresh]);
  return { summary, loading, error, refresh };
}

export function usePeople(query?: string) {
  const [people, setPeople] = useState<Person[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      const data = query && query.trim()
        ? PeopleService.search(query.trim())
        : PeopleService.getAll();
      setPeople(data);
      setError(null);
    } catch (e) {
      setError('व्यक्तियों की सूची लोड नहीं हो सकी');
    } finally {
      setLoading(false);
    }
  }, [query]);

  useEffect(() => { refresh(); }, [refresh]);
  return { people, loading, error, refresh };
}

export function useFamilies() {
  const [families, setFamilies] = useState<Family[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      setFamilies(FamiliesService.getAll());
      setError(null);
    } catch (e) {
      setError('परिवारों की सूची लोड नहीं हो सकी');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refresh(); }, [refresh]);
  return { families, loading, error, refresh };
}

export function useEvents() {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      setEvents(EventsService.getAll());
      setError(null);
    } catch (e) {
      setError('कार्यक्रमों की सूची लोड नहीं हो सकी');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { refresh(); }, [refresh]);
  return { events, loading, error, refresh };
}

export function useEntries(filters?: { direction?: 'mila' | 'diya'; eventId?: string }) {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      setEntries(EntriesService.getAll(filters));
      setError(null);
    } catch (e) {
      setError('व्यवहार की सूची लोड नहीं हो सकी');
    } finally {
      setLoading(false);
    }
  }, [filters?.direction, filters?.eventId]);

  useEffect(() => { refresh(); }, [refresh]);
  return { entries, loading, error, refresh };
}

export function useEntryDetail(id: string) {
  const [entry, setEntry] = useState<Entry | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      setEntry(EntriesService.getById(id));
      setError(null);
    } catch (e) {
      setError('व्यवहार का विवरण लोड नहीं हो सका');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { refresh(); }, [refresh]);
  return { entry, loading, error, refresh };
}

export function usePersonDetail(id: string) {
  const [data, setData] = useState<{ person: Person | null; totalMilaPaise: number; totalDiyaPaise: number; entryCount: number } | null>(null);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      const history = PeopleService.getWithHistory(id);
      const personEntries = EntriesService.getByPerson(id);
      setData(history);
      setEntries(personEntries);
      setError(null);
    } catch (e) {
      setError('व्यक्ति का विवरण लोड नहीं हो सका');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { refresh(); }, [refresh]);
  return { data, entries, loading, error, refresh };
}

export function useEventDetail(id: string) {
  const [event, setEvent] = useState<Event | null>(null);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(() => {
    try {
      setLoading(true);
      setEvent(EventsService.getById(id));
      setEntries(EntriesService.getByEvent(id));
      setError(null);
    } catch (e) {
      setError('कार्यक्रम का विवरण लोड नहीं हो सका');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { refresh(); }, [refresh]);
  return { event, entries, loading, error, refresh };
}
