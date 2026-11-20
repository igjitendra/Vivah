import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Alert,
  SafeAreaView,
  RefreshControl,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { Entry, Direction } from '../../src/types';
import { DirectionBadge } from '../../src/components/DirectionBadge';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate } from '../../src/utils/date';

export default function BahiScreen() {
  const router = useRouter();
  const [entries, setEntries] = useState<Entry[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDirection, setSelectedDirection] = useState<Direction | 'all'>('all');
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    const list = await db.getEntries({
      direction: selectedDirection === 'all' ? undefined : selectedDirection,
      searchQuery: searchQuery.trim() || undefined,
    });
    setEntries(list);
  }, [selectedDirection, searchQuery]);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const handleDelete = (id: string, name?: string) => {
    Alert.alert(
      Strings.confirmDeleteTitle,
      `${name || 'यह प्रविष्टि'} को हटाना चाहते हैं? यह बही से हट जाएगा।`,
      [
        { text: Strings.cancel, style: 'cancel' },
        {
          text: Strings.delete,
          style: 'destructive',
          onPress: async () => {
            await db.deleteEntry(id);
            loadData();
          },
        },
      ]
    );
  };

  // Calculate totals for currently filtered view
  let totalMila = 0;
  let totalDiya = 0;
  for (const e of entries) {
    if (e.direction === 'mila') totalMila += e.cash_amount_paise;
    else if (e.direction === 'diya') totalDiya += e.cash_amount_paise;
  }

  return (
    <SafeAreaView style={styles.container}>
      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>{Strings.tabs.bahi}</Text>
          <Text style={styles.headerSubtitle}>संपूर्ण लेन-देन एवं शगुन रजिस्टर</Text>
        </View>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => router.push('/entry/new')}
        >
          <Text style={styles.addBtnText}>+ नया व्यवहार</Text>
        </TouchableOpacity>
      </View>

      {/* Search Bar */}
      <View style={styles.searchSection}>
        <TextInput
          style={styles.searchInput}
          placeholder="नाम, गांव, कार्यक्रम या नोट खोजें..."
          placeholderTextColor={Colors.textSubtle}
          value={searchQuery}
          onChangeText={t => {
            setSearchQuery(t);
            loadData();
          }}
        />

        {/* Direction Filter Tabs */}
        <View style={styles.filterTabsRow}>
          <TouchableOpacity
            style={[
              styles.filterTab,
              selectedDirection === 'all' && styles.filterTabActive,
            ]}
            onPress={() => {
              setSelectedDirection('all');
              loadData();
            }}
          >
            <Text
              style={[
                styles.filterTabText,
                selectedDirection === 'all' && styles.filterTabTextActive,
              ]}
            >
              सभी ({entries.length})
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.filterTab,
              selectedDirection === 'mila' && styles.filterTabMilaActive,
            ]}
            onPress={() => {
              setSelectedDirection('mila');
              loadData();
            }}
          >
            <Text
              style={[
                styles.filterTabText,
                selectedDirection === 'mila' && styles.filterTabTextActive,
              ]}
            >
              ↓ केवल मिला
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.filterTab,
              selectedDirection === 'diya' && styles.filterTabDiyaActive,
            ]}
            onPress={() => {
              setSelectedDirection('diya');
              loadData();
            }}
          >
            <Text
              style={[
                styles.filterTabText,
                selectedDirection === 'diya' && styles.filterTabTextActive,
              ]}
            >
              ↑ केवल दिया
            </Text>
          </TouchableOpacity>
        </View>

        {/* Filter Summary Banner */}
        <View style={styles.summaryBar}>
          <Text style={[styles.summaryText, { color: Colors.mila }]}>
            मिला: {formatCurrency(totalMila)}
          </Text>
          <Text style={styles.summaryDivider}>|</Text>
          <Text style={[styles.summaryText, { color: Colors.diya }]}>
            दिया: {formatCurrency(totalDiya)}
          </Text>
        </View>
      </View>

      {/* Entries List */}
      <ScrollView
        contentContainerStyle={styles.scroll}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {entries.map(e => (
          <VyavahaarCard key={e.id} style={styles.entryCard}>
            <View style={styles.rowBetween}>
              <View style={{ flex: 1 }}>
                <Text style={styles.personName}>{e.person_name}</Text>
                <Text style={styles.personDetail}>
                  {e.person_relationship ? `${e.person_relationship} • ` : ''}
                  {e.person_village ? `गांव: ${e.person_village}` : 'स्थान नहीं'}
                </Text>
              </View>
              <DirectionBadge direction={e.direction} />
            </View>

            <View style={[styles.rowBetween, { marginTop: 8 }]}>
              <Text style={styles.eventBadge}>🎉 {e.event_title}</Text>
              <Text
                style={[
                  styles.amountText,
                  { color: e.direction === 'mila' ? Colors.mila : Colors.diya },
                ]}
              >
                {formatCurrency(e.cash_amount_paise)}
              </Text>
            </View>

            {/* Gift items */}
            {e.items && e.items.length > 0 && (
              <View style={styles.itemsBox}>
                {e.items.map(it => (
                  <Text key={it.id} style={styles.itemText}>
                    🎁 {it.item_name} × {it.quantity} {it.unit}
                    {it.estimated_value_paise
                      ? ` (अनुमानित मूल्य ${formatCurrency(it.estimated_value_paise)})`
                      : ''}
                  </Text>
                ))}
              </View>
            )}

            {e.notes ? (
              <Text style={styles.notesText}>📝 {e.notes}</Text>
            ) : null}

            <View style={styles.cardFooter}>
              <Text style={styles.dateText}>तारीख: {formatHindiDate(e.created_at)}</Text>
              <TouchableOpacity onPress={() => handleDelete(e.id, e.person_name)}>
                <Text style={styles.deleteBtnText}>हटाएं</Text>
              </TouchableOpacity>
            </View>
          </VyavahaarCard>
        ))}

        {entries.length === 0 && (
          <View style={styles.emptyBox}>
            <Text style={styles.emptyText}>{Strings.noEntriesYet}</Text>
          </View>
        )}
      </ScrollView>
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
  searchSection: {
    paddingHorizontal: 16,
    paddingTop: 12,
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
  filterTabsRow: {
    flexDirection: 'row',
    marginTop: 10,
    backgroundColor: '#EAE4D9',
    borderRadius: 10,
    padding: 3,
  },
  filterTab: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    borderRadius: 8,
  },
  filterTabActive: {
    backgroundColor: Colors.primary,
  },
  filterTabMilaActive: {
    backgroundColor: Colors.mila,
  },
  filterTabDiyaActive: {
    backgroundColor: Colors.diya,
  },
  filterTabText: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.textMuted,
  },
  filterTabTextActive: {
    color: Colors.white,
  },
  summaryBar: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
    paddingVertical: 4,
  },
  summaryText: {
    fontSize: 13,
    fontWeight: '800',
  },
  summaryDivider: {
    marginHorizontal: 12,
    color: Colors.border,
    fontSize: 14,
  },
  scroll: {
    padding: 16,
    paddingBottom: 30,
  },
  entryCard: {
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
  personDetail: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  eventBadge: {
    fontSize: 13,
    color: Colors.primary,
    fontWeight: '600',
    backgroundColor: '#EBE5D8',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  amountText: {
    fontSize: 19,
    fontWeight: '800',
  },
  itemsBox: {
    backgroundColor: '#FAF7F2',
    padding: 8,
    borderRadius: 8,
    marginTop: 8,
  },
  itemText: {
    fontSize: 13,
    color: '#4B5563',
    fontWeight: '500',
  },
  notesText: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 6,
    fontStyle: 'italic',
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#ECE7DE',
  },
  dateText: {
    fontSize: 11,
    color: Colors.textSubtle,
  },
  deleteBtnText: {
    fontSize: 12,
    color: '#DC2626',
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
});
