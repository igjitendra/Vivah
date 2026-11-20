import React from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useDashboard } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView } from '../../src/components/ui';

export default function HomeScreen() {
  const { summary, loading, error } = useDashboard();

  if (loading) return <LoadingView message="लोड हो रहा है..." />;

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>व्यवहार</Text>
        <Text style={styles.headerSubtitle}>रिश्तों का हिसाब, हमेशा याद।</Text>
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        {error && (
          <View style={styles.errorBanner}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {/* Summary cards: mila and diya strictly separated */}
        <View style={styles.row}>
          <View style={[styles.statCard, { backgroundColor: '#D1FAE5' }]}>
            <Text style={styles.statAmount}>{formatCurrency(summary?.totalMilaPaise ?? 0)}</Text>
            <Text style={styles.statLabel}>↓ मिला (कुल)</Text>
          </View>
          <View style={[styles.statCard, { backgroundColor: '#FEE2E2' }]}>
            <Text style={[styles.statAmount, { color: '#DC2626' }]}>
              {formatCurrency(summary?.totalDiyaPaise ?? 0)}
            </Text>
            <Text style={styles.statLabel}>↑ दिया (कुल)</Text>
          </View>
        </View>

        {/* Quick stats */}
        <View style={styles.row}>
          <TouchableOpacity style={styles.miniCard} onPress={() => router.push('/(tabs)/events')}>
            <Text style={styles.miniNum}>{summary?.totalEvents ?? 0}</Text>
            <Text style={styles.miniLabel}>कार्यक्रम</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.miniCard} onPress={() => router.push('/(tabs)/people')}>
            <Text style={styles.miniNum}>{summary?.totalPeople ?? 0}</Text>
            <Text style={styles.miniLabel}>व्यक्ति</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.miniCard} onPress={() => router.push('/(tabs)/bahi')}>
            <Text style={styles.miniNum}>{summary?.totalEntries ?? 0}</Text>
            <Text style={styles.miniLabel}>व्यवहार</Text>
          </TouchableOpacity>
        </View>

        {/* Recent event */}
        {summary?.recentEventTitle && (
          <View style={styles.recentCard}>
            <View style={styles.recentLabelRow}>
              <Ionicons name="calendar-outline" size={13} color="#6B7280" style={{ marginRight: 4 }} />
              <Text style={styles.recentLabel}>हाल का कार्यक्रम</Text>
            </View>
            <Text style={styles.recentTitle}>{summary.recentEventTitle}</Text>
            {summary.recentEventDate && (
              <Text style={styles.recentDate}>{formatDate(summary.recentEventDate)}</Text>
            )}
          </View>
        )}

        {/* Quick actions */}
        <Text style={styles.sectionTitle}>त्वरित कार्य</Text>
        <TouchableOpacity style={styles.actionBtn} onPress={() => router.push('/entry/new')}>
          <View style={styles.iconCircle}><Ionicons name="wallet-outline" size={20} color="#1F3352" /></View>
          <Text style={styles.actionText}>नया व्यवहार दर्ज करें</Text>
          <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionBtn} onPress={() => router.push('/event/new')}>
          <View style={styles.iconCircle}><Ionicons name="calendar-outline" size={20} color="#1F3352" /></View>
          <Text style={styles.actionText}>नया कार्यक्रम बनाएं</Text>
          <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
        </TouchableOpacity>
        <TouchableOpacity style={styles.actionBtn} onPress={() => router.push('/person/new')}>
          <View style={styles.iconCircle}><Ionicons name="person-add-outline" size={20} color="#1F3352" /></View>
          <Text style={styles.actionText}>नया व्यक्ति जोड़ें</Text>
          <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  header: { backgroundColor: '#1F3352', paddingTop: 48, paddingBottom: 24, paddingHorizontal: 20 },
  headerTitle: { fontSize: 28, fontWeight: '800', color: '#F4EFE7', letterSpacing: 1 },
  headerSubtitle: { fontSize: 13, color: '#A8B8CF', marginTop: 4 },
  scroll: { flex: 1 },
  content: { padding: 16, paddingBottom: 100 },
  errorBanner: { backgroundColor: '#FEE2E2', borderRadius: 8, padding: 12, marginBottom: 12 },
  errorText: { color: '#DC2626', fontSize: 14 },
  row: { flexDirection: 'row', gap: 12, marginBottom: 12 },
  statCard: { flex: 1, borderRadius: 12, padding: 16 },
  statAmount: { fontSize: 22, fontWeight: '800', color: '#16A34A' },
  statLabel: { fontSize: 12, color: '#374151', marginTop: 4 },
  miniCard: { flex: 1, backgroundColor: '#FFFFFF', borderRadius: 10, padding: 14, alignItems: 'center', elevation: 1 },
  miniNum: { fontSize: 24, fontWeight: '800', color: '#1F3352' },
  miniLabel: { fontSize: 12, color: '#6B7280', marginTop: 4 },
  recentCard: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 16, marginBottom: 12, elevation: 1 },
  recentLabelRow: { flexDirection: 'row', alignItems: 'center', marginBottom: 4 },
  recentLabel: { fontSize: 12, color: '#6B7280' },
  recentTitle: { fontSize: 17, fontWeight: '700', color: '#1F3352' },
  recentDate: { fontSize: 13, color: '#6B7280', marginTop: 2 },
  sectionTitle: { fontSize: 15, fontWeight: '700', color: '#1F3352', marginBottom: 10, marginTop: 8 },
  actionBtn: { backgroundColor: '#FFFFFF', borderRadius: 10, padding: 14, flexDirection: 'row', alignItems: 'center', marginBottom: 8, elevation: 1 },
  iconCircle: { width: 36, height: 36, borderRadius: 18, backgroundColor: '#F4EFE7', alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  actionText: { flex: 1, fontSize: 15, fontWeight: '600', color: '#1F2937' },
});
