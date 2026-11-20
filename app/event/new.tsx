import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { EventsService } from '../../src/services/EventsService';
import { VInput, VButton } from '../../src/components/ui';
import type { EventType } from '../../src/types';

const EVENT_TYPES: EventType[] = ['शादी', 'तिलक', 'मुंडन', 'बरात', 'सगाई', 'वर्षगांठ', 'गृह प्रवेश', 'अन्य'];

function getTodayDate(): string {
  return new Date().toISOString().split('T')[0];
}

export default function NewEventScreen() {
  const [title, setTitle] = useState('');
  const [eventType, setEventType] = useState<EventType>('शादी');
  const [eventDate, setEventDate] = useState(getTodayDate());
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSave = () => {
    if (!title.trim()) { Alert.alert('नाम आवश्यक', 'कार्यक्रम का नाम डालें।'); return; }
    if (!eventDate.match(/^\d{4}-\d{2}-\d{2}$/)) { Alert.alert('तारीख गलत', 'YYYY-MM-DD format में डालें।'); return; }
    setLoading(true);
    try {
      EventsService.create({ title: title.trim(), event_type: eventType, event_date: eventDate, notes: notes.trim() || undefined });
      Alert.alert('सफल!', 'कार्यक्रम बन गया।', [{ text: 'ठीक है', onPress: () => router.back() }]);
    } catch (e) {
      Alert.alert('त्रुटि', 'कार्यक्रम नहीं बन सका।');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <VInput label="कार्यक्रम का नाम" value={title} onChangeText={setTitle} placeholder="जैसे: रमेश की शादी" required />

        <Text style={styles.label}>प्रकार *</Text>
        <View style={styles.typeGrid}>
          {EVENT_TYPES.map(et => (
            <TouchableOpacity
              key={et}
              style={[styles.typeBtn, eventType === et && styles.typeBtnActive]}
              onPress={() => setEventType(et)}
            >
              <Text style={[styles.typeText, eventType === et && styles.typeTextActive]}>{et}</Text>
            </TouchableOpacity>
          ))}
        </View>

        <VInput label="तारीख (YYYY-MM-DD)" value={eventDate} onChangeText={setEventDate} placeholder="2025-01-01" required />
        <VInput label="नोट (वैकल्पिक)" value={notes} onChangeText={setNotes} placeholder="विशेष जानकारी..." multiline />

        <VButton title="कार्यक्रम बनाएं" onPress={handleSave} loading={loading} style={{ marginTop: 8 }} />
        <VButton title="रद्द करें" onPress={() => router.back()} variant="ghost" style={{ marginTop: 8 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  scroll: { flex: 1 },
  content: { padding: 20, paddingBottom: 40 },
  label: { fontSize: 14, fontWeight: '600', color: '#1F3352', marginBottom: 8, marginTop: 8 },
  typeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginBottom: 16 },
  typeBtn: { paddingVertical: 10, paddingHorizontal: 16, borderRadius: 8, backgroundColor: '#FFFFFF', borderWidth: 1, borderColor: '#E5E7EB' },
  typeBtnActive: { backgroundColor: '#1F3352', borderColor: '#1F3352' },
  typeText: { fontSize: 14, color: '#6B7280', fontWeight: '600' },
  typeTextActive: { color: '#F4EFE7' },
});
