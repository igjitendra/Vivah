import React from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { useEvents } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView, EmptyState } from '../../src/components/ui';
import type { Event } from '../../src/types';

export default function EventsScreen() {
  const { events, loading, refresh } = useEvents();

  const renderEvent = ({ item }: { item: Event }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/event/${item.id}`)}>
      <View style={styles.cardTop}>
        <View style={styles.typeBadge}>
          <Text style={styles.typeText}>{item.event_type}</Text>
        </View>
        <Text style={styles.date}>{formatDate(item.event_date)}</Text>
      </View>
      <Text style={styles.title}>{item.title}</Text>
      <View style={styles.stats}>
        <Text style={styles.stat}>↓ {formatCurrency(item.total_mila_paise ?? 0)}</Text>
        <Text style={styles.statSep}>·</Text>
        <Text style={[styles.stat, { color: '#DC2626' }]}>
          ↑ {formatCurrency(item.total_diya_paise ?? 0)}
        </Text>
        <Text style={styles.statSep}>·</Text>
        <Text style={styles.stat}>{item.total_entries_count ?? 0} व्यवहार</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>कार्यक्रम</Text>
        <TouchableOpacity style={styles.addBtn} onPress={() => router.push('/event/new')}>
          <Text style={styles.addBtnText}>+ नया</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <LoadingView />
      ) : events.length === 0 ? (
        <EmptyState
          icon="🎉"
          title="कोई कार्यक्रम नहीं"
          subtitle="नया कार्यक्रम जोड़ने के लिए + दबाएं"
          action={{ label: '+ नया कार्यक्रम', onPress: () => router.push('/event/new') }}
        />
      ) : (
        <FlatList
          data={events}
          keyExtractor={item => item.id}
          renderItem={renderEvent}
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
  headerTitle: { fontSize: 22, fontWeight: '800', color: '#F4EFE7' },
  addBtn: { backgroundColor: '#C05A2B', borderRadius: 8, paddingHorizontal: 14, paddingVertical: 8 },
  addBtnText: { color: '#FFFFFF', fontWeight: '700', fontSize: 14 },
  list: { padding: 16, paddingBottom: 32 },
  card: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 14, marginBottom: 10, elevation: 1 },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  typeBadge: { backgroundColor: '#EDE9FE', borderRadius: 8, paddingHorizontal: 10, paddingVertical: 4 },
  typeText: { fontSize: 12, color: '#6D28D9', fontWeight: '600' },
  date: { fontSize: 12, color: '#6B7280' },
  title: { fontSize: 17, fontWeight: '700', color: '#1F2937', marginBottom: 8 },
  stats: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  stat: { fontSize: 13, color: '#16A34A', fontWeight: '600' },
  statSep: { color: '#D1D5DB', fontSize: 13 },
});
