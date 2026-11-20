import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  TouchableOpacity,
  SafeAreaView,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../src/constants/Colors';
import { db } from '../../src/db/database';
import { Entry, Direction } from '../../src/types';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { DirectionBadge } from '../../src/components/DirectionBadge';
import { formatCurrency } from '../../src/utils/currency';

interface FlatGiftItem {
  id: string;
  item_name: string;
  quantity: number;
  unit: string;
  estimated_value_paise?: number | null;
  person_name?: string;
  person_village?: string;
  event_title?: string;
  direction: Direction;
  date: string;
}

export default function GiftsScreen() {
  const router = useRouter();
  const [gifts, setGifts] = useState<FlatGiftItem[]>([]);
  const [search, setSearch] = useState('');

  const loadData = useCallback(async () => {
    const entries = await db.getEntries();
    const flat: FlatGiftItem[] = [];

    entries.forEach(e => {
      if (e.items && e.items.length > 0) {
        e.items.forEach(it => {
          flat.push({
            id: it.id,
            item_name: it.item_name,
            quantity: it.quantity,
            unit: it.unit,
            estimated_value_paise: it.estimated_value_paise,
            person_name: e.person_name,
            person_village: e.person_village,
            event_title: e.event_title,
            direction: e.direction,
            date: e.created_at,
          });
        });
      }
    });

    setGifts(flat);
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const filteredGifts = gifts.filter(g => {
    const q = search.toLowerCase().trim();
    if (!q) return true;
    return (
      g.item_name.toLowerCase().includes(q) ||
      (g.person_name && g.person_name.toLowerCase().includes(q)) ||
      (g.event_title && g.event_title.toLowerCase().includes(q))
    );
  });

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← वापस</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>गिफ्ट व सामान इन्वेंटरी</Text>
        <View style={{ width: 50 }} />
      </View>

      <View style={styles.searchBox}>
        <TextInput
          style={styles.input}
          placeholder="सामान का नाम, देने वाले या कार्यक्रम से खोजें..."
          placeholderTextColor={Colors.textSubtle}
          value={search}
          onChangeText={setSearch}
        />
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {filteredGifts.map(g => (
          <VyavahaarCard key={g.id} style={styles.card}>
            <View style={styles.rowBetween}>
              <View style={{ flex: 1 }}>
                <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                  <Ionicons name="gift-outline" size={16} color="#C05A2B" style={{ marginRight: 6 }} />
                  <Text style={styles.itemName}>
                    {g.item_name} × {g.quantity} {g.unit}
                  </Text>
                </View>
                <Text style={styles.subtext}>
                  {g.person_name} ({g.person_village || '—'}) • {g.event_title}
                </Text>
              </View>
              <DirectionBadge direction={g.direction} size="small" />
            </View>

            {g.estimated_value_paise ? (
              <View style={styles.valueRow}>
                <Text style={styles.valueLabel}>अनुमानित बाजार मूल्य:</Text>
                <Text style={styles.valueAmount}>
                  {formatCurrency(g.estimated_value_paise)}
                </Text>
              </View>
            ) : null}
          </VyavahaarCard>
        ))}

        {filteredGifts.length === 0 && (
          <View style={styles.emptyBox}>
            <Text style={styles.emptyText}>कोई गिफ्ट या सामान नहीं मिला।</Text>
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
  searchBox: {
    padding: 16,
    backgroundColor: Colors.background,
  },
  input: {
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
    paddingHorizontal: 16,
    paddingBottom: 30,
  },
  card: {
    paddingVertical: 12,
  },
  rowBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  itemName: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.primary,
  },
  subtext: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 3,
  },
  valueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    paddingTop: 6,
    borderTopWidth: 1,
    borderTopColor: '#ECE7DE',
  },
  valueLabel: {
    fontSize: 12,
    color: Colors.textMuted,
    marginRight: 6,
  },
  valueAmount: {
    fontSize: 14,
    fontWeight: '800',
    color: Colors.accent,
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
