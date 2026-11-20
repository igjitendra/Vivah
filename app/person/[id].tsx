import React from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { usePersonDetail } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView, EmptyState, DirectionBadge } from '../../src/components/ui';
import type { Entry } from '../../src/types';

export default function PersonDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { data, entries, loading } = usePersonDetail(id ?? '');

  if (loading) return <LoadingView />;
  if (!data?.person) return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}><Text style={styles.notFound}>व्यक्ति नहीं मिला।</Text></View>
    </SafeAreaView>
  );

  const { person, totalMilaPaise, totalDiyaPaise, entryCount } = data;

  const renderEntry = ({ item }: { item: Entry }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/entry/${item.id}`)}>
      <View style={styles.cardTop}>
        <DirectionBadge direction={item.direction} size="sm" />
        <Text style={styles.amount}>{formatCurrency(item.cash_amount_paise)}</Text>
      </View>
      <Text style={styles.eventTitle}>{item.event_title ?? '—'}</Text>
      <Text style={styles.date}>{formatDate(item.event_date ?? item.created_at)}</Text>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.headerCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{person.name.charAt(0)}</Text>
        </View>
        <Text style={styles.name}>{person.name}</Text>
        {person.village && <Text style={styles.meta}>{person.village}</Text>}
        {person.relationship && <Text style={styles.rel}>{person.relationship}</Text>}
        {person.phone && <Text style={styles.phone}>📞 {person.phone}</Text>}
        <View style={styles.stats}>
          <View style={styles.stat}>
            <Text style={styles.statAmount}>{formatCurrency(totalMilaPaise)}</Text>
            <Text style={styles.statLabel}>↓ मिला</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={[styles.statAmount, { color: '#FCA5A5' }]}>
              {formatCurrency(totalDiyaPaise)}
            </Text>
            <Text style={styles.statLabel}>↑ दिया</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.stat}>
            <Text style={styles.statAmount}>{entryCount}</Text>
            <Text style={styles.statLabel}>व्यवहार</Text>
          </View>
        </View>
      </View>

      <Text style={styles.sectionTitle}>व्यवहार का इतिहास</Text>

      {entries.length === 0 ? (
        <EmptyState icon="📒" title="कोई व्यवहार नहीं" subtitle="इस व्यक्ति के साथ अभी कोई रिकॉर्ड नहीं है" />
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
  headerCard: { backgroundColor: '#1F3352', padding: 24, alignItems: 'center' },
  avatar: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: '#C05A2B',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  avatarText: { color: '#F4EFE7', fontSize: 32, fontWeight: '800' },
  name: { fontSize: 22, fontWeight: '800', color: '#F4EFE7', marginBottom: 4 },
  meta: { fontSize: 14, color: '#A8B8CF', marginBottom: 2 },
  rel: { fontSize: 13, color: '#C05A2B', fontWeight: '600', marginBottom: 2 },
  phone: { fontSize: 13, color: '#A8B8CF', marginBottom: 16 },
  stats: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 12,
    padding: 16,
    width: '100%',
  },
  stat: { flex: 1, alignItems: 'center' },
  statAmount: { fontSize: 16, fontWeight: '800', color: '#D1FAE5' },
  statLabel: { fontSize: 11, color: '#A8B8CF', marginTop: 4 },
  statDivider: { width: 1, backgroundColor: 'rgba(255,255,255,0.2)' },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: '#1F3352', marginHorizontal: 16, marginTop: 16, marginBottom: 8 },
  list: { paddingHorizontal: 16, paddingBottom: 32 },
  card: { backgroundColor: '#FFFFFF', borderRadius: 10, padding: 14, marginBottom: 8, elevation: 1 },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
  amount: { fontSize: 18, fontWeight: '800', color: '#1F3352' },
  eventTitle: { fontSize: 14, color: '#1F2937', fontWeight: '500' },
  date: { fontSize: 12, color: '#6B7280', marginTop: 2 },
});
