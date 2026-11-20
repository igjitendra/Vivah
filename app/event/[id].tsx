import React from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useEventDetail } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView, EmptyState, DirectionBadge } from '../../src/components/ui';
import type { Entry } from '../../src/types';

export default function EventDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { event, entries, loading } = useEventDetail(id ?? '');

  if (loading) return <LoadingView />;
  if (!event) return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}><Text style={styles.notFound}>कार्यक्रम नहीं मिला।</Text></View>
    </SafeAreaView>
  );

  const renderEntry = ({ item }: { item: Entry }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/entry/${item.id}`)}>
      <View style={styles.cardTop}>
        <DirectionBadge direction={item.direction} size="sm" />
        <Text style={styles.amount}>{formatCurrency(item.cash_amount_paise)}</Text>
      </View>
      <Text style={styles.personName}>{item.person_name ?? '—'}</Text>
      {item.person_village && <Text style={styles.meta}>{item.person_village}</Text>}
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.headerCard}>
        <View style={styles.typeBadge}><Text style={styles.typeText}>{event.event_type}</Text></View>
        <Text style={styles.title}>{event.title}</Text>
        <Text style={styles.date}>{formatDate(event.event_date)}</Text>
        <View style={styles.stats}>
          <View style={styles.stat}>
            <Text style={styles.statAmount}>{formatCurrency(event.total_mila_paise ?? 0)}</Text>
            <Text style={styles.statLabel}>↓ मिला</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={[styles.statAmount, { color: '#FCA5A5' }]}>
              {formatCurrency(event.total_diya_paise ?? 0)}
            </Text>
            <Text style={styles.statLabel}>↑ दिया</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={styles.statAmount}>{event.total_entries_count ?? 0}</Text>
            <Text style={styles.statLabel}>व्यवहार</Text>
          </View>
        </View>
      </View>

      <TouchableOpacity style={styles.addBtn} onPress={() => router.push('/entry/new')}>
        <Text style={styles.addBtnText}>+ नया व्यवहार</Text>
      </TouchableOpacity>

      {entries.length === 0 ? (
        <EmptyState iconName="book-outline" title="कोई व्यवहार नहीं" subtitle="इस कार्यक्रम में अभी कोई रिकॉर्ड नहीं है" />
      ) : (
        <FlatList
          data={entries}
          keyExtractor={item => item.id}
          renderItem={renderEntry}
          contentContainerStyle={styles.list}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  notFound: { fontSize: 16, color: '#6B7280' },
  headerCard: { backgroundColor: '#1F3352', padding: 20, paddingTop: 12 },
  typeBadge: {
    backgroundColor: 'rgba(255,255,255,0.15)',
    alignSelf: 'flex-start',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 4,
    marginBottom: 8,
  },
  typeText: { color: '#F4EFE7', fontSize: 12, fontWeight: '600' },
  title: { fontSize: 22, fontWeight: '800', color: '#F4EFE7', marginBottom: 4 },
  date: { fontSize: 13, color: '#A8B8CF', marginBottom: 16 },
  stats: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 12,
    padding: 16,
  },
  stat: { flex: 1, alignItems: 'center' },
  statAmount: { fontSize: 18, fontWeight: '800', color: '#D1FAE5' },
  statLabel: { fontSize: 11, color: '#A8B8CF', marginTop: 4 },
  statDivider: { width: 1, backgroundColor: 'rgba(255,255,255,0.2)' },
  addBtn: { backgroundColor: '#C05A2B', margin: 16, borderRadius: 10, padding: 14, alignItems: 'center' },
  addBtnText: { color: '#FFFFFF', fontWeight: '700', fontSize: 15 },
  list: { paddingHorizontal: 16, paddingBottom: 32 },
  card: { backgroundColor: '#FFFFFF', borderRadius: 10, padding: 14, marginBottom: 8, elevation: 1 },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  amount: { fontSize: 18, fontWeight: '800', color: '#1F3352' },
  personName: { fontSize: 15, fontWeight: '600', color: '#1F2937' },
  meta: { fontSize: 13, color: '#6B7280', marginTop: 2 },
});
