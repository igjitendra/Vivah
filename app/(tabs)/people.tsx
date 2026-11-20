import React, { useState } from 'react';
import { View, Text, FlatList, StyleSheet, TouchableOpacity, SafeAreaView, TextInput } from 'react-native';
import { router } from 'expo-router';
import { usePeople } from '../../src/hooks';
import { LoadingView, EmptyState } from '../../src/components/ui';
import type { Person } from '../../src/types';

export default function PeopleScreen() {
  const [query, setQuery] = useState('');
  const { people, loading, refresh } = usePeople(query);

  const renderPerson = ({ item }: { item: Person }) => (
    <TouchableOpacity style={styles.card} onPress={() => router.push(`/person/${item.id}`)}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{item.name.charAt(0)}</Text>
      </View>
      <View style={styles.info}>
        <Text style={styles.name}>{item.name}</Text>
        {item.village && <Text style={styles.meta}>{item.village}</Text>}
        {item.relationship && <Text style={styles.rel}>{item.relationship}</Text>}
      </View>
      <Text style={styles.arrow}>›</Text>
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>लोग</Text>
        <TouchableOpacity style={styles.addBtn} onPress={() => router.push('/person/new')}>
          <Text style={styles.addBtnText}>+ नया</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.searchRow}>
        <TextInput
          style={styles.search}
          value={query}
          onChangeText={setQuery}
          placeholder="नाम, गाँव या रिश्ते से खोजें..."
          placeholderTextColor="#9CA3AF"
        />
      </View>

      {loading ? (
        <LoadingView />
      ) : people.length === 0 ? (
        <EmptyState
          iconName="people-outline"
          title={query ? 'कोई परिणाम नहीं' : 'कोई व्यक्ति नहीं'}
          subtitle={query ? 'दूसरा नाम खोजें' : 'नया व्यक्ति जोड़ने के लिए + दबाएं'}
          action={!query ? { label: '+ नया व्यक्ति', onPress: () => router.push('/person/new') } : undefined}
        />
      ) : (
        <FlatList
          data={people}
          keyExtractor={item => item.id}
          renderItem={renderPerson}
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
  searchRow: { backgroundColor: '#FFFFFF', paddingHorizontal: 16, paddingVertical: 10 },
  search: {
    backgroundColor: '#F3F4F6',
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 10,
    fontSize: 15,
    color: '#1F2937',
  },
  list: { padding: 16, paddingBottom: 32 },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 14,
    marginBottom: 8,
    flexDirection: 'row',
    alignItems: 'center',
    elevation: 1,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#1F3352',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  avatarText: { color: '#F4EFE7', fontSize: 18, fontWeight: '700' },
  info: { flex: 1 },
  name: { fontSize: 16, fontWeight: '700', color: '#1F2937' },
  meta: { fontSize: 13, color: '#6B7280', marginTop: 2 },
  rel: { fontSize: 12, color: '#C05A2B', marginTop: 2, fontWeight: '600' },
  arrow: { fontSize: 20, color: '#C05A2B' },
});
