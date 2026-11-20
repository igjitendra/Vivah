import React, { useState, useEffect } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, SafeAreaView, Share, Alert } from 'react-native';
import { getDatabaseStats, exportDatabaseAsJSON } from '../../src/database/db';

export default function SettingsScreen() {
  const [stats, setStats] = useState<{ tableCount: number; entryCount: number } | null>(null);

  useEffect(() => {
    try {
      setStats(getDatabaseStats());
    } catch (e) {
      console.error('Stats error:', e);
    }
  }, []);

  const handleExport = async () => {
    try {
      const json = exportDatabaseAsJSON();
      await Share.share({ message: json, title: 'व्यवहार डेटा बैकअप' });
    } catch (e) {
      Alert.alert('त्रुटि', 'निर्यात नहीं हो सका');
    }
  };

  const SettingRow = ({ icon, label, onPress }: { icon: string; label: string; onPress?: () => void }) => (
    <TouchableOpacity style={styles.row} onPress={onPress} disabled={!onPress}>
      <Text style={styles.rowIcon}>{icon}</Text>
      <Text style={styles.rowLabel}>{label}</Text>
      {onPress && <Text style={styles.rowArrow}>›</Text>}
    </TouchableOpacity>
  );

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>सेटिंग</Text>
      </View>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        {/* App info */}
        <View style={styles.appCard}>
          <Text style={styles.appName}>व्यवहार</Text>
          <Text style={styles.appTagline}>रिश्तों का हिसाब, हमेशा याद।</Text>
          <Text style={styles.appVersion}>संस्करण 1.0.0 (Phase 2)</Text>
        </View>

        {/* DB stats */}
        {stats && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>डेटाबेस</Text>
            <View style={styles.row}>
              <Text style={styles.rowIcon}>📊</Text>
              <Text style={styles.rowLabel}>{stats.entryCount} व्यवहार दर्ज हैं</Text>
            </View>
            <View style={styles.row}>
              <Text style={styles.rowIcon}>💾</Text>
              <Text style={styles.rowLabel}>{stats.tableCount} तालिकाएँ</Text>
            </View>
          </View>
        )}

        {/* Data management */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>डेटा प्रबंधन</Text>
          <SettingRow icon="📤" label="डेटा निर्यात (JSON)" onPress={handleExport} />
          <SettingRow icon="☁️" label="Supabase Sync (Phase 3 में आएगा)" />
        </View>

        {/* Privacy */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>गोपनीयता</Text>
          <SettingRow icon="🔒" label="सभी डेटा आपके फोन पर सुरक्षित है" />
          <SettingRow icon="🚫" label="कोई क्लाउड अपलोड नहीं (अभी)" />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  header: { backgroundColor: '#1F3352', paddingTop: 48, paddingBottom: 16, paddingHorizontal: 20 },
  headerTitle: { fontSize: 22, fontWeight: '800', color: '#F4EFE7' },
  scroll: { flex: 1 },
  content: { padding: 16, paddingBottom: 48 },
  appCard: { backgroundColor: '#1F3352', borderRadius: 16, padding: 24, alignItems: 'center', marginBottom: 20 },
  appName: { fontSize: 28, fontWeight: '800', color: '#F4EFE7', letterSpacing: 1 },
  appTagline: { fontSize: 13, color: '#A8B8CF', marginTop: 4 },
  appVersion: { fontSize: 11, color: '#6B7280', marginTop: 8 },
  section: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 4, marginBottom: 16, elevation: 1 },
  sectionTitle: { fontSize: 12, fontWeight: '700', color: '#6B7280', paddingHorizontal: 16, paddingTop: 12, paddingBottom: 4, textTransform: 'uppercase', letterSpacing: 0.5 },
  row: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 14, borderTopWidth: 1, borderTopColor: '#F3F4F6' },
  rowIcon: { fontSize: 18, marginRight: 12 },
  rowLabel: { flex: 1, fontSize: 15, color: '#1F2937' },
  rowArrow: { fontSize: 20, color: '#C05A2B' },
});
