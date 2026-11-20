import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  Modal,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { Direction, Person, Event, EntryItem } from '../../src/types';
import { rupeesToPaise } from '../../src/utils/currency';
import { getTodayDateString } from '../../src/utils/date';

export default function NewEntryScreen() {
  const router = useRouter();

  // Form State
  const [direction, setDirection] = useState<Direction>('mila');
  const [selectedPersonId, setSelectedPersonId] = useState<string>('');
  const [selectedEventId, setSelectedEventId] = useState<string>('');
  const [cashRupees, setCashRupees] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  
  // Multi-item gifts
  const [items, setItems] = useState<Array<{
    item_name: string;
    quantity: number;
    unit: string;
    estimated_value_rupees?: string;
  }>>([]);

  // Data lists
  const [people, setPeople] = useState<Person[]>([]);
  const [events, setEvents] = useState<Event[]>([]);

  // Modals for quick adding
  const [showPersonModal, setShowPersonModal] = useState(false);
  const [newPersonName, setNewPersonName] = useState('');
  const [newPersonVillage, setNewPersonVillage] = useState('');
  const [newPersonRelationship, setNewPersonRelationship] = useState('');
  const [newPersonPhone, setNewPersonPhone] = useState('');

  const [showEventModal, setShowEventModal] = useState(false);
  const [newEventTitle, setNewEventTitle] = useState('');
  const [newEventType, setNewEventType] = useState('शादी');
  const [newEventDate, setNewEventDate] = useState(getTodayDateString());

  useEffect(() => {
    loadLists();
  }, []);

  const loadLists = async () => {
    const pList = await db.getPeople();
    const eList = await db.getEvents();
    setPeople(pList);
    setEvents(eList);
    if (pList.length > 0 && !selectedPersonId) setSelectedPersonId(pList[0].id);
    if (eList.length > 0 && !selectedEventId) setSelectedEventId(eList[0].id);
  };

  const handleAddItem = () => {
    setItems([
      ...items,
      { item_name: '', quantity: 1, unit: 'संख्या', estimated_value_rupees: '' },
    ]);
  };

  const handleUpdateItem = (index: number, field: string, value: any) => {
    const updated = [...items];
    updated[index] = { ...updated[index], [field]: value };
    setItems(updated);
  };

  const handleRemoveItem = (index: number) => {
    const updated = items.filter((_, i) => i !== index);
    setItems(updated);
  };

  const handleCreateQuickPerson = async () => {
    if (!newPersonName.trim()) {
      Alert.alert('त्रुटि', 'कृपया व्यक्ति का नाम दर्ज करें।');
      return;
    }
    const created = await db.createPerson({
      name: newPersonName.trim(),
      village: newPersonVillage.trim() || undefined,
      relationship: newPersonRelationship.trim() || undefined,
      phone: newPersonPhone.trim() || undefined,
    });
    setPeople(prev => [...prev, created]);
    setSelectedPersonId(created.id);
    setShowPersonModal(false);
    setNewPersonName('');
    setNewPersonVillage('');
    setNewPersonRelationship('');
    setNewPersonPhone('');
  };

  const handleCreateQuickEvent = async () => {
    if (!newEventTitle.trim()) {
      Alert.alert('त्रुटि', 'कृपया कार्यक्रम का नाम दर्ज करें।');
      return;
    }
    const created = await db.createEvent({
      title: newEventTitle.trim(),
      event_type: newEventType as any,
      event_date: newEventDate,
    });
    setEvents(prev => [...prev, created]);
    setSelectedEventId(created.id);
    setShowEventModal(false);
    setNewEventTitle('');
  };

  const validateAndSave = async (isSaveAndAddNext = false) => {
    if (!selectedPersonId) {
      Alert.alert('अपूर्ण जानकारी', 'कृपया व्यक्ति या रिश्तेदार का चयन करें।');
      return false;
    }
    if (!selectedEventId) {
      Alert.alert('अपूर्ण जानकारी', 'कृपया कार्यक्रम का चयन करें।');
      return false;
    }

    const cashAmountPaise = rupeesToPaise(cashRupees);

    // Filter valid items
    const validItems = items
      .filter(it => it.item_name.trim().length > 0)
      .map(it => ({
        item_name: it.item_name.trim(),
        quantity: Number(it.quantity) || 1,
        unit: it.unit || 'संख्या',
        estimated_value_paise: it.estimated_value_rupees
          ? rupeesToPaise(it.estimated_value_rupees)
          : null,
      }));

    if (cashAmountPaise === 0 && validItems.length === 0) {
      Alert.alert('अपूर्ण प्रविष्टि', 'कृपया नकद राशि या कम से कम एक सामान का नाम अवश्य दर्ज करें।');
      return false;
    }

    await db.createEntry(
      {
        event_id: selectedEventId,
        person_id: selectedPersonId,
        direction,
        cash_amount_paise: cashAmountPaise,
        notes: notes.trim() || undefined,
      },
      validItems
    );

    if (isSaveAndAddNext) {
      // Clear for next entry (keep same event, reset person and amounts)
      setCashRupees('');
      setItems([]);
      setNotes('');
      Alert.alert('सफल', 'व्यवहार सुरक्षित हो गया। अगला दर्ज करें।');
    } else {
      router.back();
    }
    return true;
  };

  const selectedPerson = people.find(p => p.id === selectedPersonId);
  const selectedEvent = events.find(e => e.id === selectedEventId);

  return (
    <SafeAreaView style={styles.safeArea}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={{ flex: 1 }}
      >
        <View style={styles.topHeader}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
            <Text style={styles.backBtnText}>← वापस</Text>
          </TouchableOpacity>
          <Text style={styles.topHeaderTitle}>नया व्यवहार दर्ज करें</Text>
          <View style={{ width: 50 }} />
        </View>

        <ScrollView contentContainerStyle={styles.scroll}>
          {/* 1. Direction Toggle */}
          <Text style={styles.sectionLabel}>व्यवहार का प्रकार (दिशा)</Text>
          <View style={styles.directionToggleContainer}>
            <TouchableOpacity
              style={[
                styles.directionButton,
                direction === 'mila' && styles.directionMilaActive,
              ]}
              onPress={() => setDirection('mila')}
            >
              <Text
                style={[
                  styles.directionText,
                  direction === 'mila' && styles.directionTextActive,
                ]}
              >
                ↓ व्यवहार मिला (प्राप्त)
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.directionButton,
                direction === 'diya' && styles.directionDiyaActive,
              ]}
              onPress={() => setDirection('diya')}
            >
              <Text
                style={[
                  styles.directionText,
                  direction === 'diya' && styles.directionTextActive,
                ]}
              >
                ↑ व्यवहार दिया (शगुन/न्योता)
              </Text>
            </TouchableOpacity>
          </View>

          {/* 2. Select Event */}
          <View style={styles.rowBetween}>
            <Text style={styles.sectionLabel}>{Strings.eventLabel}</Text>
            <TouchableOpacity onPress={() => setShowEventModal(true)}>
              <Text style={styles.quickAddLink}>+ नया कार्यक्रम</Text>
            </TouchableOpacity>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipsScroll}>
            {events.map(ev => (
              <TouchableOpacity
                key={ev.id}
                style={[
                  styles.chip,
                  selectedEventId === ev.id && styles.chipActive,
                ]}
                onPress={() => setSelectedEventId(ev.id)}
              >
                <Text
                  style={[
                    styles.chipText,
                    selectedEventId === ev.id && styles.chipTextActive,
                  ]}
                >
                  🎉 {ev.title}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* 3. Select Person */}
          <View style={[styles.rowBetween, { marginTop: 14 }]}>
            <Text style={styles.sectionLabel}>{Strings.personLabel}</Text>
            <TouchableOpacity onPress={() => setShowPersonModal(true)}>
              <Text style={styles.quickAddLink}>+ नया व्यक्ति/रिश्तेदार</Text>
            </TouchableOpacity>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipsScroll}>
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
                  👤 {p.name} {p.village ? `(${p.village})` : ''}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {selectedPerson && (
            <View style={styles.personPreviewBox}>
              <Text style={styles.personPreviewName}>
                चयनित: {selectedPerson.name}
              </Text>
              <Text style={styles.personPreviewDetail}>
                रिश्ता: {selectedPerson.relationship || '—'} | गांव/शहर:{' '}
                {selectedPerson.village || '—'}
                {selectedPerson.phone ? ` | 📞 ${selectedPerson.phone}` : ''}
              </Text>
            </View>
          )}

          {/* 4. Cash Amount */}
          <Text style={[styles.sectionLabel, { marginTop: 16 }]}>
            {Strings.cashAmountLabel}
          </Text>
          <View style={styles.amountInputRow}>
            <Text style={styles.rupeeSymbol}>₹</Text>
            <TextInput
              style={styles.amountInput}
              keyboardType="numeric"
              placeholder={Strings.cashAmountPlaceholder}
              placeholderTextColor={Colors.textSubtle}
              value={cashRupees}
              onChangeText={setCashRupees}
            />
          </View>

          {/* 5. Gifts & Items */}
          <View style={[styles.rowBetween, { marginTop: 20 }]}>
            <Text style={styles.sectionLabel}>{Strings.itemsLabel}</Text>
            <TouchableOpacity onPress={handleAddItem}>
              <Text style={styles.quickAddLink}>{Strings.addItem}</Text>
            </TouchableOpacity>
          </View>

          {items.map((it, idx) => (
            <View key={idx} style={styles.itemBox}>
              <View style={styles.rowBetween}>
                <Text style={styles.itemBoxTitle}>सामान #{idx + 1}</Text>
                <TouchableOpacity onPress={() => handleRemoveItem(idx)}>
                  <Text style={styles.removeItemText}>✕ हटाएं</Text>
                </TouchableOpacity>
              </View>

              <TextInput
                style={styles.textInput}
                placeholder={Strings.itemNamePlaceholder}
                placeholderTextColor={Colors.textSubtle}
                value={it.item_name}
                onChangeText={v => handleUpdateItem(idx, 'item_name', v)}
              />

              <View style={styles.itemSubRow}>
                <View style={{ flex: 1, marginRight: 8 }}>
                  <Text style={styles.fieldSubLabel}>{Strings.quantityLabel}</Text>
                  <TextInput
                    style={styles.smallInput}
                    keyboardType="numeric"
                    placeholder="1"
                    value={String(it.quantity)}
                    onChangeText={v => handleUpdateItem(idx, 'quantity', v)}
                  />
                </View>

                <View style={{ flex: 1, marginRight: 8 }}>
                  <Text style={styles.fieldSubLabel}>{Strings.unitLabel}</Text>
                  <TextInput
                    style={styles.smallInput}
                    placeholder="सेट / संख्या"
                    value={it.unit}
                    onChangeText={v => handleUpdateItem(idx, 'unit', v)}
                  />
                </View>

                <View style={{ flex: 1.5 }}>
                  <Text style={styles.fieldSubLabel}>{Strings.estimatedValueLabel}</Text>
                  <TextInput
                    style={styles.smallInput}
                    keyboardType="numeric"
                    placeholder="₹ मूल्य"
                    value={it.estimated_value_rupees || ''}
                    onChangeText={v => handleUpdateItem(idx, 'estimated_value_rupees', v)}
                  />
                </View>
              </View>
            </View>
          ))}

          {/* 6. Notes */}
          <Text style={[styles.sectionLabel, { marginTop: 16 }]}>
            {Strings.notesLabel}
          </Text>
          <TextInput
            style={[styles.textInput, styles.notesInput]}
            multiline
            numberOfLines={3}
            placeholder={Strings.notesPlaceholder}
            placeholderTextColor={Colors.textSubtle}
            value={notes}
            onChangeText={setNotes}
          />

          {/* 7. Action Buttons */}
          <View style={styles.bottomButtonsWrapper}>
            <TouchableOpacity
              style={styles.saveBtn}
              onPress={() => validateAndSave(false)}
            >
              <Text style={styles.saveBtnText}>{Strings.save}</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.saveNextBtn}
              onPress={() => validateAndSave(true)}
            >
              <Text style={styles.saveNextBtnText}>{Strings.saveAndAddNext}</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>

        {/* Modal: Quick Add Person */}
        <Modal visible={showPersonModal} animationType="slide" transparent>
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>नया व्यक्ति / रिश्तेदार जोड़ें</Text>
              
              <Text style={styles.fieldSubLabel}>नाम *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="उदा. रमेश कुमार"
                value={newPersonName}
                onChangeText={setNewPersonName}
              />

              <Text style={styles.fieldSubLabel}>गांव या शहर</Text>
              <TextInput
                style={styles.textInput}
                placeholder="उदा. रामपुर"
                value={newPersonVillage}
                onChangeText={setNewPersonVillage}
              />

              <Text style={styles.fieldSubLabel}>रिश्तेदारी</Text>
              <TextInput
                style={styles.textInput}
                placeholder="उदा. मामा, चाचा, फुफा, मित्र"
                value={newPersonRelationship}
                onChangeText={setNewPersonRelationship}
              />

              <Text style={styles.fieldSubLabel}>मोबाइल नंबर (वैकल्पिक)</Text>
              <TextInput
                style={styles.textInput}
                keyboardType="phone-pad"
                placeholder="10 अंकों का नंबर"
                value={newPersonPhone}
                onChangeText={setNewPersonPhone}
              />

              <View style={styles.modalActionsRow}>
                <TouchableOpacity
                  style={styles.modalCancelBtn}
                  onPress={() => setShowPersonModal(false)}
                >
                  <Text style={styles.modalCancelText}>रद्द करें</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.modalSaveBtn}
                  onPress={handleCreateQuickPerson}
                >
                  <Text style={styles.modalSaveText}>जोड़ें</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>

        {/* Modal: Quick Add Event */}
        <Modal visible={showEventModal} animationType="slide" transparent>
          <View style={styles.modalOverlay}>
            <View style={styles.modalContent}>
              <Text style={styles.modalTitle}>नया कार्यक्रम जोड़ें</Text>
              
              <Text style={styles.fieldSubLabel}>कार्यक्रम का नाम *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="उदा. पूजा की शादी"
                value={newEventTitle}
                onChangeText={setNewEventTitle}
              />

              <Text style={styles.fieldSubLabel}>प्रकार (शादी, तिलक, मुंडन आदि)</Text>
              <TextInput
                style={styles.textInput}
                placeholder="शादी"
                value={newEventType}
                onChangeText={setNewEventType}
              />

              <Text style={styles.fieldSubLabel}>तारीख (YYYY-MM-DD)</Text>
              <TextInput
                style={styles.textInput}
                placeholder="2026-02-18"
                value={newEventDate}
                onChangeText={setNewEventDate}
              />

              <View style={styles.modalActionsRow}>
                <TouchableOpacity
                  style={styles.modalCancelBtn}
                  onPress={() => setShowEventModal(false)}
                >
                  <Text style={styles.modalCancelText}>रद्द करें</Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.modalSaveBtn}
                  onPress={handleCreateQuickEvent}
                >
                  <Text style={styles.modalSaveText}>जोड़ें</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  topHeader: {
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
  topHeaderTitle: {
    color: Colors.white,
    fontSize: 18,
    fontWeight: '800',
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  sectionLabel: {
    fontSize: 15,
    fontWeight: '700',
    color: Colors.primary,
    marginBottom: 8,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  quickAddLink: {
    fontSize: 13,
    color: Colors.accent,
    fontWeight: '700',
  },
  directionToggleContainer: {
    flexDirection: 'row',
    backgroundColor: '#EBE5D8',
    borderRadius: 12,
    padding: 4,
    marginBottom: 16,
  },
  directionButton: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderRadius: 10,
  },
  directionMilaActive: {
    backgroundColor: Colors.mila,
  },
  directionDiyaActive: {
    backgroundColor: Colors.diya,
  },
  directionText: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.textMuted,
  },
  directionTextActive: {
    color: Colors.white,
  },
  chipsScroll: {
    marginBottom: 10,
  },
  chip: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: '#D8CFC4',
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 20,
    marginRight: 8,
  },
  chipActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  chipText: {
    fontSize: 13,
    color: Colors.text,
    fontWeight: '600',
  },
  chipTextActive: {
    color: Colors.white,
  },
  personPreviewBox: {
    backgroundColor: '#EAE4D9',
    padding: 10,
    borderRadius: 8,
    marginBottom: 8,
  },
  personPreviewName: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.primary,
  },
  personPreviewDetail: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  amountInputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderWidth: 2,
    borderColor: Colors.accent,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 6,
  },
  rupeeSymbol: {
    fontSize: 28,
    fontWeight: '800',
    color: Colors.accent,
    marginRight: 8,
  },
  amountInput: {
    flex: 1,
    fontSize: 28,
    fontWeight: '800',
    color: Colors.text,
  },
  itemBox: {
    backgroundColor: Colors.surface,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E6DFD5',
    marginBottom: 10,
  },
  itemBoxTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.primary,
  },
  removeItemText: {
    fontSize: 12,
    color: '#DC2626',
    fontWeight: '700',
  },
  textInput: {
    backgroundColor: '#FAF8F5',
    borderWidth: 1,
    borderColor: '#D8CFC4',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: Colors.text,
    marginTop: 6,
  },
  itemSubRow: {
    flexDirection: 'row',
    marginTop: 8,
  },
  fieldSubLabel: {
    fontSize: 11,
    color: Colors.textMuted,
    fontWeight: '600',
  },
  smallInput: {
    backgroundColor: '#FAF8F5',
    borderWidth: 1,
    borderColor: '#D8CFC4',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    fontSize: 13,
    color: Colors.text,
    marginTop: 4,
  },
  notesInput: {
    minHeight: 70,
    textAlignVertical: 'top',
  },
  bottomButtonsWrapper: {
    marginTop: 24,
  },
  saveBtn: {
    backgroundColor: Colors.accent,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 10,
  },
  saveBtnText: {
    color: Colors.white,
    fontSize: 17,
    fontWeight: '800',
  },
  saveNextBtn: {
    backgroundColor: Colors.primary,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
  },
  saveNextBtnText: {
    color: Colors.white,
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
  modalActionsRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 18,
  },
  modalCancelBtn: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    marginRight: 10,
  },
  modalCancelText: {
    fontSize: 14,
    color: Colors.textMuted,
    fontWeight: '700',
  },
  modalSaveBtn: {
    backgroundColor: Colors.accent,
    paddingVertical: 10,
    paddingHorizontal: 20,
    borderRadius: 8,
  },
  modalSaveText: {
    color: Colors.white,
    fontSize: 14,
    fontWeight: '700',
  },
});
