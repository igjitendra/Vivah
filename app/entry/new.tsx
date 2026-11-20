import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { EntriesService } from '../../src/services/EntriesService';
import { EventsService } from '../../src/services/EventsService';
import { PeopleService } from '../../src/services/PeopleService';
import { VInput, AmountInput, VButton } from '../../src/components/ui';
import type { Event, Person } from '../../src/types';
import type { CreateEntryInput } from '../../src/validation/schemas';

export default function NewEntryScreen() {
  const [direction, setDirection] = useState<'mila' | 'diya'>('mila');
  const [cashAmountPaise, setCashAmountPaise] = useState(0);
  const [notes, setNotes] = useState('');
  const [selectedEventId, setSelectedEventId] = useState('');
  const [selectedPersonId, setSelectedPersonId] = useState('');
  const [loading, setLoading] = useState(false);
  const [showEventPicker, setShowEventPicker] = useState(false);
  const [showPersonPicker, setShowPersonPicker] = useState(false);
  const [events] = useState<Event[]>(() => { try { return EventsService.getAll(); } catch { return []; } });
  const [people] = useState<Person[]>(() => { try { return PeopleService.getAll(); } catch { return []; } });

  const selectedEvent = events.find(e => e.id === selectedEventId);
  const selectedPerson = people.find(p => p.id === selectedPersonId);

  const handleSave = async () => {
    if (!selectedEventId) { Alert.alert('कार्यक्रम चुनें', 'पहले कार्यक्रम चुनें।'); return; }
    if (!selectedPersonId) { Alert.alert('व्यक्ति चुनें', 'पहले व्यक्ति चुनें।'); return; }
    if (cashAmountPaise <= 0) { Alert.alert('राशि डालें', 'नकद राशि 0 से अधिक होनी चाहिए।'); return; }

    setLoading(true);
    try {
      const input: CreateEntryInput = {
        event_id: selectedEventId,
        person_id: selectedPersonId,
        direction,
        cash_amount_paise: cashAmountPaise,
        notes: notes.trim() || undefined,
        items: [],
      };
      EntriesService.create(input);
      Alert.alert('सफल!', 'व्यवहार दर्ज हो गया।', [{ text: 'ठीक है', onPress: () => router.back() }]);
    } catch (e) {
      Alert.alert('त्रुटि', 'व्यवहार दर्ज नहीं हो सका। फिर से कोशिश करें।');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">

        {/* Direction selector */}
        <Text style={styles.label}>व्यवहार का प्रकार *</Text>
        <View style={styles.dirRow}>
          <TouchableOpacity style={[styles.dirBtn, direction === 'mila' && styles.dirMila]} onPress={() => setDirection('mila')}>
            <Text style={[styles.dirText, direction === 'mila' && { color: '#16A34A' }]}>↓ मिला (Received)</Text>
          </TouchableOpacity>
          <TouchableOpacity style={[styles.dirBtn, direction === 'diya' && styles.dirDiya]} onPress={() => setDirection('diya')}>
            <Text style={[styles.dirText, direction === 'diya' && { color: '#DC2626' }]}>↑ दिया (Given)</Text>
          </TouchableOpacity>
        </View>

        {/* Event picker */}
        <Text style={styles.label}>कार्यक्रम *</Text>
        <TouchableOpacity style={styles.picker} onPress={() => setShowEventPicker(true)}>
          <Text style={selectedEvent ? styles.pickerValue : styles.pickerPlaceholder}>
            {selectedEvent ? selectedEvent.title : 'कार्यक्रम चुनें...'}
          </Text>
          <Text style={styles.pickerArrow}>›</Text>
        </TouchableOpacity>
        {showEventPicker && (
          <View style={styles.pickerList}>
            {events.map(e => (
              <TouchableOpacity key={e.id} style={styles.pickerItem} onPress={() => { setSelectedEventId(e.id); setShowEventPicker(false); }}>
                <Text style={styles.pickerItemText}>{e.title}</Text>
                <Text style={styles.pickerItemMeta}>{e.event_type} · {e.event_date}</Text>
              </TouchableOpacity>
            ))}
            {events.length === 0 && <Text style={styles.pickerEmpty}>कोई कार्यक्रम नहीं। पहले कार्यक्रम बनाएं।</Text>}
          </View>
        )}

        {/* Person picker */}
        <Text style={styles.label}>व्यक्ति *</Text>
        <TouchableOpacity style={styles.picker} onPress={() => setShowPersonPicker(true)}>
          <Text style={selectedPerson ? styles.pickerValue : styles.pickerPlaceholder}>
            {selectedPerson ? selectedPerson.name : 'व्यक्ति चुनें...'}
          </Text>
          <Text style={styles.pickerArrow}>›</Text>
        </TouchableOpacity>
        {showPersonPicker && (
          <View style={styles.pickerList}>
            {people.map(p => (
              <TouchableOpacity key={p.id} style={styles.pickerItem} onPress={() => { setSelectedPersonId(p.id); setShowPersonPicker(false); }}>
                <Text style={styles.pickerItemText}>{p.name}</Text>
                {p.village && <Text style={styles.pickerItemMeta}>{p.village}</Text>}
              </TouchableOpacity>
            ))}
            {people.length === 0 && <Text style={styles.pickerEmpty}>कोई व्यक्ति नहीं। पहले व्यक्ति जोड़ें।</Text>}
          </View>
        )}

        {/* Amount */}
        <AmountInput
          label="नकद राशि (₹) *"
          amountPaise={cashAmountPaise}
          onChangePaise={setCashAmountPaise}
        />

        {/* Notes */}
        <VInput
          label="नोट (वैकल्पिक)"
          value={notes}
          onChangeText={setNotes}
          placeholder="कोई विशेष बात..."
          multiline
        />

        <VButton title="व्यवहार दर्ज करें" onPress={handleSave} loading={loading} style={{ marginTop: 8 }} />
        <VButton title="रद्द करें" onPress={() => router.back()} variant="ghost" style={{ marginTop: 8 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  scroll: { flex: 1 },
  content: { padding: 20, paddingBottom: 40 },
  label: { fontSize: 14, fontWeight: '600', color: '#1F3352', marginBottom: 8, marginTop: 16 },
  dirRow: { flexDirection: 'row', gap: 10, marginBottom: 4 },
  dirBtn: {
    flex: 1,
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
  },
  dirMila: { borderColor: '#16A34A', backgroundColor: '#D1FAE5' },
  dirDiya: { borderColor: '#DC2626', backgroundColor: '#FEE2E2' },
  dirText: { fontWeight: '600', fontSize: 14, color: '#6B7280' },
  picker: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 4,
  },
  pickerValue: { flex: 1, fontSize: 15, color: '#1F2937' },
  pickerPlaceholder: { flex: 1, fontSize: 15, color: '#9CA3AF' },
  pickerArrow: { fontSize: 20, color: '#C05A2B' },
  pickerList: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E5E7EB',
    marginBottom: 8,
    maxHeight: 200,
    overflow: 'hidden',
  },
  pickerItem: { padding: 12, borderBottomWidth: 1, borderBottomColor: '#F3F4F6' },
  pickerItemText: { fontSize: 15, color: '#1F2937', fontWeight: '500' },
  pickerItemMeta: { fontSize: 12, color: '#6B7280', marginTop: 2 },
  pickerEmpty: { padding: 16, color: '#6B7280', textAlign: 'center', fontSize: 14 },
});
