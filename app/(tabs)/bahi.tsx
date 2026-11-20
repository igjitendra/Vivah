import React, { useState } from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { useEntries } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView, EmptyState, DirectionBadge } from '../../src/components/ui';
import type { Entry } from '../../src/types';

type Filter = 'all' | 'mila' | 'diya';

export default function BahiScreen() {
  const [filter, setFilter] = useState<Filter>('all');
  const { entries, loading, refresh } = useEntries(
    filter !== 'all' ? { direction: filter } : undefined
  );

  const renderEntry = ({ item }: { item: Entry }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/entry/${item.id}`)}>
      <View style={styles.cardTop}>
        <DirectionBadge direction={item.direction} size="sm" />
        <Text style={styles.amount}>{formatCurrency(item.cash_amount_paise)}</Text>
      </View>
      <Text style={styles.personName}>{item.person_name ?? 'अज्ञात'}</Text>
      {item.person_village && <Text style={styles.meta}>{item.person_village}</Text>}
      <View style={styles.cardBottom}>
        <Text style={styles.eventTitle}>{item.event_title ?? ''}</Text>
        <Text style={styles.date}>{formatDate(item.event_date ?? item.created_at)}</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.title}>बही खाता</Text>
        <TouchableOpacity style={styles.addBtn} onPress={() => router.push('/entry/new')}>
          <Text style={styles.addBtnText}>+ नया</Text>
        </TouchableOpacity>
      </View>

      {/* Filter tabs */}
      <View style={styles.filterRow}>
        {(['all', 'mila', 'diya'] as Filter[]).map(f => (
          <TouchableOpacity
            key={f}
            style={[styles.filterTab, filter === f && styles.filterTabActive]}
            onPress={() => setFilter(f)}
          >
            <Text style={[styles.filterText, filter === f && styles.filterTextActive]}>
              {f === 'all' ? 'सभी' : f === 'mila' ? '↓ मिला' : '↑ दिया'}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {loading ? (
        <LoadingView />
      ) : entries.length === 0 ? (
        <EmptyState
          iconName="book-outline"
          title="कोई व्यवहार नहीं"
          subtitle="नया व्यवहार दर्ज करने के लिए + दबाएं"
          action={{ label: '+ नया व्यवहार', onPress: () => router.push('/entry/new') }}
        />
      ) : (
        <FlatList
          data={entries}
          keyExtractor={item => item.id}
          renderItem={renderEntry}
          contentContainerStyle={styles.list}
          onRefresh={refresh}
          refreshing={loading}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  header: {
    backgroundColor: '#1F3352',
    paddingTop: 48,
    paddingBottom: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: { fontSize: 22, fontWeight: '800', color: '#F4EFE7' },
  addBtn: { backgroundColor: '#C05A2B', borderRadius: 8, paddingHorizontal: 14, paddingVertical: 8 },
  addBtnText: { color: '#FFFFFF', fontWeight: '700', fontSize: 14 },
  filterRow: { flexDirection: 'row', backgroundColor: '#FFFFFF', paddingHorizontal: 16, paddingVertical: 10, gap: 8 },
  filterTab: { flex: 1, paddingVertical: 8, borderRadius: 8, alignItems: 'center', backgroundColor: '#F3F4F6' },
  filterTabActive: { backgroundColor: '#1F3352' },
  filterText: { fontSize: 13, fontWeight: '600', color: '#6B7280' },
  filterTextActive: { color: '#F4EFE7' },
  list: { padding: 16, paddingBottom: 100 },
  card: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 14, marginBottom: 10, elevation: 1 },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  amount: { fontSize: 20, fontWeight: '800', color: '#1F3352' },
  personName: { fontSize: 16, fontWeight: '600', color: '#1F2937' },
  meta: { fontSize: 13, color: '#6B7280', marginTop: 2 },
  cardBottom: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 },
  eventTitle: { fontSize: 13, color: '#6B7280', flex: 1 },
  date: { fontSize: 12, color: '#9CA3AF' },
});
