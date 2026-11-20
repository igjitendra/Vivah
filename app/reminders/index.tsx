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
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../src/constants/Colors';
import { db } from '../../src/db/database';
import { Reminder, Person } from '../../src/types';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { formatHindiDate, getTodayDateString } from '../../src/utils/date';

export default function RemindersScreen() {
  const router = useRouter();
  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [people, setPeople] = useState<Person[]>([]);

  // Add reminder modal
  const [showModal, setShowModal] = useState(false);
  const [selectedPersonId, setSelectedPersonId] = useState('');
  const [eventTitle, setEventTitle] = useState('');
  const [targetDate, setTargetDate] = useState(getTodayDateString());
  const [note, setNote] = useState('');

  const loadData = useCallback(async () => {
    const rList = await db.getReminders();
    const pList = await db.getPeople();
    setReminders(rList);
    setPeople(pList);
    if (pList.length > 0 && !selectedPersonId) {
      setSelectedPersonId(pList[0].id);
    }
  }, [selectedPersonId]);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const handleCreateReminder = async () => {
    if (!selectedPersonId || !eventTitle.trim()) {
      Alert.alert('त्रुटि', 'कृपया व्यक्ति और कार्यक्रम का नाम दर्ज करें।');
      return;
    }
    await db.createReminder({
      person_id: selectedPersonId,
      event_title: eventTitle.trim(),
      target_date: targetDate,
      note: note.trim() || undefined,
      is_completed: false,
    });
    setEventTitle('');
    setNote('');
    setShowModal(false);
    loadData();
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← वापस</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>आगामी व्यवहार व याद दिलाना</Text>
        <View style={{ width: 50 }} />
      </View>

      <View style={styles.banner}>
        <Ionicons name="information-circle-outline" size={18} color="#92400E" style={{ marginRight: 6 }} />
        <Text style={[styles.bannerText, { flex: 1 }]}>
          यह फीचर आपको रिश्तेदारों के आने वाले कार्यक्रमों की याद दिलाएगा, ताकि आप समय पर पुराना रिकॉर्ड देखकर व्यवहार तय कर सकें।
        </Text>
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {reminders.map(r => (
          <VyavahaarCard key={r.id} style={styles.card}>
            <View style={styles.rowBetween}>
              <View style={{ flex: 1 }}>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <Ionicons name="person-outline" size={14} color={Colors.text} style={{ marginRight: 4 }} />
                  <Text style={styles.personName}>
                    {r.person_name} {r.person_village ? `(${r.person_village})` : ''}
                  </Text>
                </View>
                <View style={{ flexDirection: 'row', alignItems: 'center', marginTop: 4 }}>
                  <Ionicons name="calendar-outline" size={14} color={Colors.primary} style={{ marginRight: 4 }} />
                  <Text style={styles.eventTitle}>{r.event_title}</Text>
                </View>
                <Text style={styles.dateText}>
                  तारीख: {formatHindiDate(r.target_date)}
                </Text>
              </View>
              <View style={[styles.bellBadge, { flexDirection: 'row', alignItems: 'center' }]}>
                <Ionicons name="notifications-outline" size={12} color="#854D0E" style={{ marginRight: 3 }} />
                <Text style={styles.bellText}>आगामी</Text>
              </View>
            </View>

            {r.note ? (
              <View style={styles.noteBox}>
                <Text style={styles.noteText}>"{r.note}"</Text>
              </View>
            ) : null}

            <View style={styles.actionsRow}>
              <TouchableOpacity
                style={styles.historyBtn}
                onPress={() => router.push('/people')}
              >
                <Text style={styles.historyBtnText}>इनका पुराना व्यवहार देखें →</Text>
              </TouchableOpacity>
            </View>
          </VyavahaarCard>
        ))}

        <TouchableOpacity
          style={styles.addReminderBtn}
          onPress={() => setShowModal(true)}
        >
          <Text style={styles.addReminderBtnText}>+ नई याद / आगामी कार्यक्रम जोड़ें</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Modal */}
      <Modal visible={showModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>आगामी कार्यक्रम याद जोड़ें</Text>

            <Text style={styles.label}>व्यक्ति / रिश्तेदार चुनें</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
              {people.map(p => (
                <TouchableOpacity
                  key={p.id}
                  style={[
                    styles.chip,
                    selectedPersonId === p.id && styles.chipActive,
                  ]}
                  onPress={() => setSelectedPersonId(p.id)}
                >
                  <Text
                    style={[
                      styles.chipText,
                      selectedPersonId === p.id && styles.chipTextActive,
                    ]}
                  >
                    {p.name}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            <Text style={styles.label}>कार्यक्रम (उदा. लड़के की शादी, तिलक)</Text>
            <TextInput
              style={styles.input}
              placeholder="कार्यक्रम का नाम"
              value={eventTitle}
              onChangeText={setEventTitle}
            />

            <Text style={styles.label}>तारीख (YYYY-MM-DD)</Text>
            <TextInput
              style={styles.input}
              value={targetDate}
              onChangeText={setTargetDate}
            />

            <Text style={styles.label}>निजी टिप्पणी / नोट</Text>
            <TextInput
              style={[styles.input, { minHeight: 60 }]}
              multiline
              placeholder="कोई विशेष बात..."
              value={note}
              onChangeText={setNote}
            />

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setShowModal(false)}
              >
                <Text style={styles.cancelText}>रद्द करें</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.saveBtn} onPress={handleCreateReminder}>
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  backBtn: {
    padding: 6,
  },
  backBtnText: {
    color: Colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
  headerTitle: {
    color: Colors.white,
    fontSize: 18,
    fontWeight: '800',
  },
  banner: {
    backgroundColor: '#FEF3C7',
    padding: 12,
    margin: 16,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#FDE68A',
  },
  bannerText: {
    fontSize: 12,
    color: '#92400E',
    lineHeight: 18,
  },
  scroll: {
    paddingHorizontal: 16,
    paddingBottom: 30,
  },
  card: {
    paddingVertical: 14,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  personName: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text,
  },
  eventTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.primary,
    marginTop: 4,
  },
  dateText: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 3,
  },
  bellBadge: {
    backgroundColor: '#FEF9C3',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  bellText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#854D0E',
  },
  noteBox: {
    backgroundColor: '#FAF8F5',
    padding: 8,
    borderRadius: 6,
    marginTop: 8,
  },
  noteText: {
    fontSize: 12,
    fontStyle: 'italic',
    color: Colors.textMuted,
  },
  actionsRow: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#ECE7DE',
  },
  historyBtn: {
    alignSelf: 'flex-start',
  },
  historyBtnText: {
    fontSize: 13,
    color: Colors.accent,
    fontWeight: '700',
  },
  addReminderBtn: {
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.accent,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 10,
  },
  addReminderBtnText: {
    color: Colors.accent,
    fontSize: 15,
    fontWeight: '700',
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
  label: {
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
  chip: {
    backgroundColor: '#FAF8F5',
    borderWidth: 1,
    borderColor: '#D8CFC4',
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 16,
    marginRight: 6,
  },
  chipActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  chipText: {
    fontSize: 12,
    color: Colors.text,
    fontWeight: '600',
  },
  chipTextActive: {
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
