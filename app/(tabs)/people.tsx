import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Modal,
  Alert,
  SafeAreaView,
} from 'react-native';
import { useFocusEffect } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { Person, Entry } from '../../src/types';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { DirectionBadge } from '../../src/components/DirectionBadge';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate } from '../../src/utils/date';

export default function PeopleScreen() {
  const [people, setPeople] = useState<Person[]>([]);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPerson, setSelectedPerson] = useState<Person | null>(null);

  // Modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [name, setName] = useState('');
  const [village, setVillage] = useState('');
  const [relationship, setRelationship] = useState('');
  const [phone, setPhone] = useState('');

  const loadData = useCallback(async () => {
    const pList = await db.getPeople();
    const eList = await db.getEntries();
    setPeople(pList);
    setEntries(eList);
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const handleAddPerson = async () => {
    if (!name.trim()) {
      Alert.alert('त्रुटि', 'कृपया नाम अवश्य दर्ज करें।');
      return;
    }
    await db.createPerson({
      name: name.trim(),
      village: village.trim() || undefined,
      relationship: relationship.trim() || undefined,
      phone: phone.trim() || undefined,
    });
    setName('');
    setVillage('');
    setRelationship('');
    setPhone('');
    setShowAddModal(false);
    loadData();
  };

  const filteredPeople = people.filter(p => {
    const q = searchQuery.toLowerCase().trim();
    if (!q) return true;
    return (
      p.name.toLowerCase().includes(q) ||
      (p.village && p.village.toLowerCase().includes(q)) ||
      (p.relationship && p.relationship.toLowerCase().includes(q))
    );
  });

  // Calculate totals for a person
  const getPersonStats = (personId: string) => {
    let mila = 0;
    let diya = 0;
    let count = 0;
    for (const e of entries) {
      if (e.person_id === personId) {
        count++;
        if (e.direction === 'mila') mila += e.cash_amount_paise;
        else if (e.direction === 'diya') diya += e.cash_amount_paise;
      }
    }
    return { mila, diya, count };
  };

  const personEntries = selectedPerson
    ? entries.filter(e => e.person_id === selectedPerson.id)
    : [];

  return (
    <SafeAreaView style={styles.container}>
      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>{Strings.tabs.people}</Text>
          <Text style={styles.headerSubtitle}>रिश्तेदारों और परिचितों की सूची</Text>
        </View>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => setShowAddModal(true)}
        >
          <Text style={styles.addBtnText}>+ नया व्यक्ति</Text>
        </TouchableOpacity>
      </View>

      {/* Search Input */}
      <View style={styles.searchWrapper}>
        <TextInput
          style={styles.searchInput}
          placeholder="नाम, गांव या रिश्ता खोजें..."
          placeholderTextColor={Colors.textSubtle}
          value={searchQuery}
          onChangeText={setSearchQuery}
        />
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {filteredPeople.map(person => {
          const stats = getPersonStats(person.id);
          const isSelected = selectedPerson?.id === person.id;

          return (
            <VyavahaarCard key={person.id} style={styles.personCard}>
              <TouchableOpacity
                onPress={() => setSelectedPerson(isSelected ? null : person)}
              >
                <View style={styles.rowBetween}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.personName}>{person.name}</Text>
                    <Text style={styles.personSubtext}>
                      {person.relationship ? `${person.relationship} • ` : ''}
                      {person.village ? `गांव: ${person.village}` : 'स्थान दर्ज नहीं'}
                      {person.phone ? ` • 📞 ${person.phone}` : ''}
                    </Text>
                  </View>
                  <Text style={styles.historyToggleText}>
                    {isSelected ? '▲ विवरण छिपाएं' : '▼ इतिहास देखें'}
                  </Text>
                </View>

                {/* Person Stats summary badges */}
                <View style={styles.statsRow}>
                  <View style={[styles.statBadge, { backgroundColor: Colors.milaBg }]}>
                    <Text style={[styles.statBadgeText, { color: Colors.mila }]}>
                      मिला: {formatCurrency(stats.mila)}
                    </Text>
                  </View>

                  <View style={[styles.statBadge, { backgroundColor: Colors.diyaBg }]}>
                    <Text style={[styles.statBadgeText, { color: Colors.diya }]}>
                      दिया: {formatCurrency(stats.diya)}
                    </Text>
                  </View>

                  <View style={[styles.statBadge, { backgroundColor: '#ECE7DE' }]}>
                    <Text style={[styles.statBadgeText, { color: Colors.textMuted }]}>
                      कुल: {stats.count} बार
                    </Text>
                  </View>
                </View>
              </TouchableOpacity>

              {/* Expanded History for this Person */}
              {isSelected && (
                <View style={styles.expandedSection}>
                  <Text style={styles.expandedTitle}>
                    {person.name} का संपूर्ण व्यवहार इतिहास:
                  </Text>

                  {personEntries.length === 0 ? (
                    <Text style={styles.noHistoryText}>अभी तक कोई व्यवहार दर्ज नहीं हुआ है।</Text>
                  ) : (
                    personEntries.map(e => (
                      <View key={e.id} style={styles.personEntryItem}>
                        <View style={styles.rowBetween}>
                          <Text style={styles.personEntryEvent}>🎉 {e.event_title}</Text>
                          <DirectionBadge direction={e.direction} size="small" />
                        </View>
                        <View style={[styles.rowBetween, { marginTop: 4 }]}>
                          <Text style={styles.personEntryDate}>{formatHindiDate(e.created_at)}</Text>
                          <Text
                            style={[
                              styles.personEntryAmount,
                              { color: e.direction === 'mila' ? Colors.mila : Colors.diya },
                            ]}
                          >
                            {formatCurrency(e.cash_amount_paise)}
                          </Text>
                        </View>
                        {e.items && e.items.length > 0 && (
                          <Text style={styles.personItemInfo}>
                            📦 {e.items.map(i => `${i.item_name} × ${i.quantity}`).join(', ')}
                          </Text>
                        )}
                        {e.notes ? (
                          <Text style={styles.personNotes}>📝 {e.notes}</Text>
                        ) : null}
                      </View>
                    ))
                  )}
                </View>
              )}
            </VyavahaarCard>
          );
        })}

        {filteredPeople.length === 0 && (
          <View style={styles.emptyBox}>
            <Text style={styles.emptyText}>{Strings.noPeopleYet}</Text>
          </View>
        )}
      </ScrollView>

      {/* Add Person Modal */}
      <Modal visible={showAddModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>नया व्यक्ति / रिश्तेदार जोड़ें</Text>
            
            <Text style={styles.fieldLabel}>नाम *</Text>
            <TextInput
              style={styles.input}
              placeholder="उदा. रामकिशोर शर्मा"
              value={name}
              onChangeText={setName}
            />

            <Text style={styles.fieldLabel}>गांव या शहर</Text>
            <TextInput
              style={styles.input}
              placeholder="उदा. रामपुर"
              value={village}
              onChangeText={setVillage}
            />

            <Text style={styles.fieldLabel}>रिश्तेदारी</Text>
            <TextInput
              style={styles.input}
              placeholder="उदा. चाचा, मामा, मौसा, मित्र"
              value={relationship}
              onChangeText={setRelationship}
            />

            <Text style={styles.fieldLabel}>फोन नंबर (वैकल्पिक)</Text>
            <TextInput
              style={styles.input}
              keyboardType="phone-pad"
              placeholder="10 अंकों का मोबाइल नंबर"
              value={phone}
              onChangeText={setPhone}
            />

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setShowAddModal(false)}
              >
                <Text style={styles.cancelText}>रद्द करें</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.saveBtn} onPress={handleAddPerson}>
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
  searchWrapper: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.background,
  },
  searchInput: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: '#D8CFC4',
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 14,
    color: Colors.text,
  },
  scroll: {
    padding: 16,
    paddingBottom: 30,
  },
  personCard: {
    paddingVertical: 14,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  personName: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.text,
  },
  personSubtext: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 3,
  },
  historyToggleText: {
    fontSize: 12,
    color: Colors.accent,
    fontWeight: '700',
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: 10,
  },
  statBadge: {
    paddingVertical: 3,
    paddingHorizontal: 8,
    borderRadius: 6,
    marginRight: 6,
  },
  statBadgeText: {
    fontSize: 11,
    fontWeight: '700',
  },
  expandedSection: {
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#E6DFD5',
  },
  expandedTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.primary,
    marginBottom: 8,
  },
  noHistoryText: {
    fontSize: 12,
    color: Colors.textMuted,
    fontStyle: 'italic',
  },
  personEntryItem: {
    backgroundColor: '#FAF8F5',
    padding: 10,
    borderRadius: 8,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#EAE4D9',
  },
  personEntryEvent: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.primary,
  },
  personEntryDate: {
    fontSize: 11,
    color: Colors.textSubtle,
  },
  personEntryAmount: {
    fontSize: 15,
    fontWeight: '800',
  },
  personItemInfo: {
    fontSize: 12,
    color: '#4B5563',
    marginTop: 4,
  },
  personNotes: {
    fontSize: 11,
    color: Colors.textMuted,
    fontStyle: 'italic',
    marginTop: 2,
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
