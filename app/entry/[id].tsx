import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, Alert, SafeAreaView } from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { useEntryDetail } from '../../src/hooks';
import { EntriesService } from '../../src/services/EntriesService';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView, DirectionBadge, VButton, ConfirmDialog } from '../../src/components/ui';

export default function EntryDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { entry, loading } = useEntryDetail(id ?? '');
  const [showConfirm, setShowConfirm] = useState(false);

  const handleDelete = () => {
    try {
      EntriesService.softDelete(id ?? '');
      Alert.alert('हटाया गया', 'व्यवहार हटा दिया गया।', [{ text: 'ठीक है', onPress: () => router.back() }]);
    } catch (e) {
      Alert.alert('त्रुटि', 'व्यवहार नहीं हटाया जा सका।');
    }
  };

  if (loading) return <LoadingView />;
  if (!entry) return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.center}><Text style={styles.notFound}>व्यवहार नहीं मिला।</Text></View>
    </SafeAreaView>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        <View style={styles.headerCard}>
          <DirectionBadge direction={entry.direction} />
          <Text style={styles.amount}>{formatCurrency(entry.cash_amount_paise)}</Text>
          <Text style={styles.date}>{formatDate(entry.created_at)}</Text>
        </View>

        <View style={styles.infoCard}>
          <InfoRow label="व्यक्ति" value={entry.person_name ?? '—'} />
          {entry.person_village && <InfoRow label="गाँव" value={entry.person_village} />}
          {entry.person_relationship && <InfoRow label="रिश्ता" value={entry.person_relationship} />}
          <InfoRow label="कार्यक्रम" value={entry.event_title ?? '—'} />
          {entry.event_date && <InfoRow label="कार्यक्रम की तारीख" value={formatDate(entry.event_date)} />}
          {entry.notes && <InfoRow label="नोट" value={entry.notes} />}
        </View>

        {entry.items && entry.items.length > 0 && (
          <View style={styles.infoCard}>
            <Text style={styles.sectionLabel}>उपहार / सामान</Text>
            {entry.items.map(item => (
              <View key={item.id} style={styles.itemRow}>
                <Text style={styles.itemName}>{item.item_name}</Text>
                <Text style={styles.itemMeta}>{item.quantity} {item.unit}</Text>
                {item.estimated_value_paise ? (
                  <Text style={styles.itemValue}>~{formatCurrency(item.estimated_value_paise)}</Text>
                ) : null}
              </View>
            ))}
          </View>
        )}

        <VButton title="व्यवहार हटाएं" onPress={() => setShowConfirm(true)} variant="danger" style={{ marginTop: 20 }} />
      </ScrollView>

      <ConfirmDialog
        visible={showConfirm}
        title="व्यवहार हटाएं?"
        message="यह व्यवहार हटा दिया जाएगा। क्या आप सुनिश्चित हैं?"
        confirmLabel="हाँ, हटाएं"
        cancelLabel="रद्द करें"
        onConfirm={handleDelete}
        onCancel={() => setShowConfirm(false)}
        dangerous
      />
    </SafeAreaView>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={styles.infoValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  scroll: { flex: 1 },
  content: { padding: 16, paddingBottom: 40 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  notFound: { fontSize: 16, color: '#6B7280' },
  headerCard: { backgroundColor: '#1F3352', borderRadius: 16, padding: 24, alignItems: 'center', marginBottom: 16 },
  amount: { fontSize: 36, fontWeight: '800', color: '#F4EFE7', marginTop: 12 },
  date: { fontSize: 13, color: '#A8B8CF', marginTop: 6 },
  infoCard: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 16, marginBottom: 12, elevation: 1 },
  sectionLabel: { fontSize: 13, fontWeight: '700', color: '#6B7280', marginBottom: 10, textTransform: 'uppercase', letterSpacing: 0.5 },
  infoRow: { flexDirection: 'row', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#F3F4F6' },
  infoLabel: { fontSize: 14, color: '#6B7280', flex: 1 },
  infoValue: { fontSize: 14, fontWeight: '600', color: '#1F2937', flex: 2 },
  itemRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#F3F4F6' },
  itemName: { flex: 2, fontSize: 14, color: '#1F2937', fontWeight: '500' },
  itemMeta: { flex: 1, fontSize: 13, color: '#6B7280' },
  itemValue: { fontSize: 13, color: '#C05A2B', fontWeight: '600' },
});
