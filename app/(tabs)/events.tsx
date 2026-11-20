import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Modal,
  TextInput,
  Alert,
  SafeAreaView,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { Event, EventType } from '../../src/types';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate, getTodayDateString } from '../../src/utils/date';

export default function EventsScreen() {
  const router = useRouter();
  const [events, setEvents] = useState<Event[]>([]);

  // Add Event Modal
  const [showModal, setShowModal] = useState(false);
  const [title, setTitle] = useState('');
  const [eventType, setEventType] = useState<EventType>('शादी');
  const [date, setDate] = useState(getTodayDateString());
  const [notes, setNotes] = useState('');

  const loadData = useCallback(async () => {
    const list = await db.getEvents();
    setEvents(list);
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const handleCreateEvent = async () => {
    if (!title.trim()) {
      Alert.alert('त्रुटि', 'कृपया कार्यक्रम का नाम दर्ज करें।');
      return;
    }
    await db.createEvent({
      title: title.trim(),
      event_type: eventType,
      event_date: date,
      notes: notes.trim() || undefined,
    });
    setTitle('');
    setNotes('');
    setShowModal(false);
    loadData();
  };

  const eventTypes: EventType[] = [
    'शादी',
    'तिलक',
    'मुंडन',
    'बरात',
    'सगाई',
    'वर्षगांठ',
    'गृह प्रवेश',
    'अन्य',
  ];

  return (
    <SafeAreaView style={styles.container}>
      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>{Strings.tabs.events}</Text>
          <Text style={styles.headerSubtitle}>पारिवारिक आयोजनों की सूची</Text>
        </View>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => setShowModal(true)}
        >
          <Text style={styles.addBtnText}>+ नया कार्यक्रम</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {events.map(ev => (
          <VyavahaarCard key={ev.id} style={styles.eventCard}>
            <View style={styles.rowBetween}>
              <View style={{ flex: 1 }}>
                <Text style={styles.eventTitle}>{ev.title}</Text>
                <Text style={styles.eventDate}>
                  📅 {formatHindiDate(ev.event_date)} • {ev.event_type}
                </Text>
              </View>
              <View style={styles.typeBadge}>
                <Text style={styles.typeBadgeText}>{ev.event_type}</Text>
              </View>
            </View>

            {/* Financial Totals for this event */}
            <View style={styles.totalsRow}>
              <View style={[styles.totalCol, { backgroundColor: Colors.milaBg }]}>
                <Text style={[styles.totalLabel, { color: Colors.mila }]}>कुल मिला</Text>
                <Text style={[styles.totalVal, { color: Colors.mila }]}>
                  {formatCurrency(ev.total_mila_paise || 0)}
                </Text>
              </View>

              <View style={[styles.totalCol, { backgroundColor: Colors.diyaBg }]}>
                <Text style={[styles.totalLabel, { color: Colors.diya }]}>कुल दिया</Text>
                <Text style={[styles.totalVal, { color: Colors.diya }]}>
                  {formatCurrency(ev.total_diya_paise || 0)}
                </Text>
              </View>

              <View style={[styles.totalCol, { backgroundColor: '#ECE7DE' }]}>
                <Text style={styles.totalLabel}>दर्ज एंट्री</Text>
                <Text style={[styles.totalVal, { color: Colors.primary }]}>
                  {ev.total_entries_count || 0}
                </Text>
              </View>
            </View>

            {ev.notes ? (
              <Text style={styles.notesText}>📝 {ev.notes}</Text>
            ) : null}

            {/* Actions for this event */}
            <View style={styles.cardActionsRow}>
              <TouchableOpacity
                style={styles.actionBtnSecondary}
                onPress={() => router.push('/bahi')}
              >
                <Text style={styles.actionBtnSecondaryText}>इस कार्यक्रम की बही →</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.actionBtnPrimary}
                onPress={() => router.push('/entry/new')}
              >
                <Text style={styles.actionBtnPrimaryText}>+ व्यवहार जोड़ें</Text>
              </TouchableOpacity>
            </View>
          </VyavahaarCard>
        ))}

        {events.length === 0 && (
          <View style={styles.emptyBox}>
            <Text style={styles.emptyText}>{Strings.noEventsYet}</Text>
          </View>
        )}
      </ScrollView>

      {/* Modal to add event */}
      <Modal visible={showModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>नया कार्यक्रम जोड़ें</Text>

            <Text style={styles.fieldLabel}>कार्यक्रम का नाम *</Text>
            <TextInput
              style={styles.input}
              placeholder="उदा. राहुल की शादी / तिलक"
              value={title}
              onChangeText={setTitle}
            />

            <Text style={styles.fieldLabel}>कार्यक्रम का प्रकार</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
              {eventTypes.map(t => (
                <TouchableOpacity
                  key={t}
                  style={[
                    styles.typeChip,
                    eventType === t && styles.typeChipActive,
                  ]}
                  onPress={() => setEventType(t)}
                >
                  <Text
                    style={[
                      styles.typeChipText,
                      eventType === t && styles.typeChipTextActive,
                    ]}
                  >
                    {t}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            <Text style={styles.fieldLabel}>तारीख (YYYY-MM-DD)</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
            />

            <Text style={styles.fieldLabel}>विवरण / टिप्पणी (वैकल्पिक)</Text>
            <TextInput
              style={[styles.input, { minHeight: 60 }]}
              multiline
              placeholder="स्थान, समय या अन्य विवरण..."
              value={notes}
              onChangeText={setNotes}
            />

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setShowModal(false)}
              >
                <Text style={styles.cancelText}>रद्द करें</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.saveBtn} onPress={handleCreateEvent}>
                <Text style={styles.saveText}>सुरक्षित करें</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    backgroundColor: Colors.primary,
    paddingHorizontal: 20,
    paddingTop: 18,
    paddingBottom: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: Colors.white,
  },
  headerSubtitle: {
    fontSize: 12,
    color: '#D8CFC4',
    marginTop: 2,
  },
  addBtn: {
    backgroundColor: Colors.accent,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  addBtnText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 13,
  },
  scroll: {
    padding: 16,
    paddingBottom: 30,
  },
  eventCard: {
    paddingVertical: 14,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  eventTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.text,
  },
  eventDate: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 3,
  },
  typeBadge: {
    backgroundColor: '#EBE5D8',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
  },
  typeBadgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.primary,
  },
  totalsRow: {
    flexDirection: 'row',
    marginTop: 12,
  },
  totalCol: {
    flex: 1,
    padding: 8,
    borderRadius: 8,
    marginRight: 6,
    alignItems: 'center',
  },
  totalLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.textMuted,
  },
  totalVal: {
    fontSize: 15,
    fontWeight: '800',
    marginTop: 2,
  },
  notesText: {
    fontSize: 12,
    color: Colors.textMuted,
    fontStyle: 'italic',
    marginTop: 10,
  },
  cardActionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 14,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#ECE7DE',
  },
  actionBtnSecondary: {
    paddingVertical: 6,
  },
  actionBtnSecondaryText: {
    fontSize: 13,
    color: Colors.primary,
    fontWeight: '700',
  },
  actionBtnPrimary: {
    backgroundColor: Colors.accent,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 6,
  },
  actionBtnPrimaryText: {
    color: Colors.white,
    fontSize: 12,
    fontWeight: '700',
  },
  emptyBox: {
    padding: 30,
    alignItems: 'center',
  },
  emptyText: {
    color: Colors.textMuted,
    fontSize: 14,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    padding: 20,
  },
  modalContent: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    padding: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.primary,
    marginBottom: 14,
  },
  fieldLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.primary,
    marginTop: 8,
  },
  input: {
    backgroundColor: '#FAF8F5',
    borderWidth: 1,
    borderColor: '#D8CFC4',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
    fontSize: 14,
    color: Colors.text,
    marginTop: 4,
  },
  typeChip: {
    backgroundColor: '#FAF8F5',
    borderWidth: 1,
    borderColor: '#D8CFC4',
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 16,
    marginRight: 6,
  },
  typeChipActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  typeChipText: {
    fontSize: 12,
    color: Colors.text,
    fontWeight: '600',
  },
  typeChipTextActive: {
    color: Colors.white,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 18,
  },
  cancelBtn: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginRight: 8,
  },
  cancelText: {
    color: Colors.textMuted,
    fontWeight: '700',
    fontSize: 14,
  },
  saveBtn: {
    backgroundColor: Colors.accent,
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  saveText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 14,
  },
});
