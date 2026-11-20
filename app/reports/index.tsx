import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  SafeAreaView,
  ActivityIndicator,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { PdfService } from '../../src/services/PdfService';
import { CsvService } from '../../src/services/CsvService';
import { EventsService } from '../../src/services/EventsService';
import { SummaryService, type DashboardSummary } from '../../src/services/SummaryService';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate } from '../../src/utils/date';
import type { Event } from '../../src/types';

export default function ReportsScreen() {
  const router = useRouter();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [events, setEvents] = useState<Event[]>([]);
  const [selectedYear, setSelectedYear] = useState<string>(String(new Date().getFullYear()));
  const [loading, setLoading] = useState<boolean>(true);
  const [exporting, setExporting] = useState<string | null>(null);

  useEffect(() => {
    try {
      setSummary(SummaryService.getDashboardSummary());
      setEvents(EventsService.getAll());
    } catch (e) {
      console.error('Reports load error:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleExportFullPdf = async () => {
    setExporting('पूर्ण PDF तैयार हो रही है...');
    try {
      await PdfService.generateFullReport();
    } catch (e: any) {
      Alert.alert('त्रुटि', `PDF तैयार नहीं हो सकी: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setExporting(null);
    }
  };

  const handleExportYearPdf = async () => {
    setExporting(`वर्ष ${selectedYear} की PDF तैयार हो रही है...`);
    try {
      await PdfService.generateYearReport(selectedYear);
    } catch (e: any) {
      Alert.alert('त्रुटि', `PDF तैयार नहीं हो सकी: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setExporting(null);
    }
  };

  const handleExportItemsPdf = async () => {
    setExporting('उपहार रिपोर्ट PDF तैयार हो रही है...');
    try {
      await PdfService.generateItemReport();
    } catch (e: any) {
      Alert.alert('त्रुटि', `PDF तैयार नहीं हो सकी: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setExporting(null);
    }
  };

  const handleExportCsv = async (type: 'entries' | 'people' | 'items') => {
    setExporting('CSV तैयार हो रही है...');
    try {
      if (type === 'entries') await CsvService.exportAllEntries();
      else if (type === 'people') await CsvService.exportPeople();
      else if (type === 'items') await CsvService.exportItems();
    } catch (e: any) {
      Alert.alert('त्रुटि', `CSV एक्सपोर्ट विफल: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setExporting(null);
    }
  };

  if (loading) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.center}><ActivityIndicator size="large" color="#1F3352" /></View>
      </SafeAreaView>
    );
  }

  const currentYear = new Date().getFullYear();
  const years = [String(currentYear), String(currentYear - 1), String(currentYear - 2)];

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← वापस</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>रिपोर्ट्स व एक्सपोर्ट</Text>
        <View style={{ width: 50 }} />
      </View>

      {exporting && (
        <View style={styles.loadingBanner}>
          <ActivityIndicator color="#1F3352" size="small" style={{ marginRight: 8 }} />
          <Text style={styles.loadingText}>{exporting}</Text>
        </View>
      )}

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Financial Summary */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>कुल नकद हिसाब (वास्तविक पूर्ण लेन-देन)</Text>
          <View style={styles.statsRow}>
            <View style={[styles.statBox, { backgroundColor: '#ECFDF5', borderColor: '#A7F3D0' }]}>
              <Text style={styles.statLabel}>↓ कुल मिला</Text>
              <Text style={[styles.statValue, { color: '#16A34A' }]}>{formatCurrency(summary?.totalMilaPaise ?? 0)}</Text>
              <Text style={styles.statSub}>गिफ्ट मूल्य शामिल नहीं</Text>
            </View>
            <View style={[styles.statBox, { backgroundColor: '#FEF2F2', borderColor: '#FECACA' }]}>
              <Text style={styles.statLabel}>↑ कुल दिया</Text>
              <Text style={[styles.statValue, { color: '#DC2626' }]}>{formatCurrency(summary?.totalDiyaPaise ?? 0)}</Text>
              <Text style={styles.statSub}>गिफ्ट मूल्य शामिल नहीं</Text>
            </View>
          </View>
          <Text style={styles.infoNote}>
            * मिला और दिया हमेशा अलग रखे जाते हैं। कोई ऋण या बकाया स्वचालित रूप से नहीं निकाला जाता।
          </Text>
        </View>

        {/* PDF Reports Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>आधिकारिक PDF रिपोर्ट्स (Devanagari A4)</Text>
          
          <TouchableOpacity style={styles.exportCard} onPress={handleExportFullPdf} disabled={Boolean(exporting)}>
            <View style={styles.iconCircle}>
              <Ionicons name="document-text-outline" size={20} color="#1F3352" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>संपूर्ण पारिवारिक बही खाता (PDF)</Text>
              <Text style={styles.exportCardSub}>सभी दर्ज व्यवहारों की प्रमाणित A4 प्रिंट रिपोर्ट</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <View style={styles.yearSelectorRow}>
            <Text style={styles.yearLabel}>वर्ष चुनें:</Text>
            {years.map(y => (
              <TouchableOpacity
                key={y}
                style={[styles.yearChip, selectedYear === y && styles.yearChipActive]}
                onPress={() => setSelectedYear(y)}
              >
                <Text style={[styles.yearChipText, selectedYear === y && styles.yearChipTextActive]}>{y}</Text>
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity style={styles.exportCard} onPress={handleExportYearPdf} disabled={Boolean(exporting)}>
            <View style={styles.iconCircle}>
              <Ionicons name="calendar-outline" size={20} color="#1F3352" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>वार्षिक रिपोर्ट — {selectedYear} (PDF)</Text>
              <Text style={styles.exportCardSub}>वर्ष {selectedYear} के समस्त व्यवहार</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.exportCard} onPress={handleExportItemsPdf} disabled={Boolean(exporting)}>
            <View style={styles.iconCircle}>
              <Ionicons name="gift-outline" size={20} color="#1F3352" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>उपहार व सामान सूची (PDF)</Text>
              <Text style={styles.exportCardSub}>भौतिक वस्तुओं और अनुमानित मूल्यों का अलग विवरण</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>
        </View>

        {/* Event-wise PDF */}
        {events.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>कार्यक्रम अनुसार PDF रिपोर्ट</Text>
            {events.slice(0, 5).map(ev => (
              <TouchableOpacity
                key={ev.id}
                style={styles.eventRow}
                onPress={() => {
                  setExporting(`${ev.title} की PDF तैयार हो रही है...`);
                  PdfService.generateEventReport(ev.id)
                    .catch((err: any) => Alert.alert('त्रुटि', err?.message || 'PDF विफल'))
                    .finally(() => setExporting(null));
                }}
                disabled={Boolean(exporting)}
              >
                <View style={{ flex: 1 }}>
                  <Text style={styles.eventTitle}>{ev.title}</Text>
                  <Text style={styles.eventMeta}>{ev.event_type} • {formatHindiDate(ev.event_date)}</Text>
                </View>
                <View style={styles.pdfBadge}><Text style={styles.pdfBadgeText}>PDF बनाएं</Text></View>
              </TouchableOpacity>
            ))}
          </View>
        )}

        {/* CSV Export Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Excel / CSV एक्सपोर्ट (UTF-8 Devanagari)</Text>

          <TouchableOpacity style={styles.exportCard} onPress={() => handleExportCsv('entries')} disabled={Boolean(exporting)}>
            <View style={[styles.iconCircle, { backgroundColor: '#F0FDF4' }]}>
              <Ionicons name="reader-outline" size={20} color="#16A34A" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>सभी व्यवहार डेटा (CSV)</Text>
              <Text style={styles.exportCardSub}>Excel में खोलने हेतु उपयुक्त</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.exportCard} onPress={() => handleExportCsv('people')} disabled={Boolean(exporting)}>
            <View style={[styles.iconCircle, { backgroundColor: '#F0FDF4' }]}>
              <Ionicons name="people-outline" size={20} color="#16A34A" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>व्यक्तियों की निर्देशिका (CSV)</Text>
              <Text style={styles.exportCardSub}>नाम, गाँव, रिश्ते व फोन नंबर</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.exportCard} onPress={() => handleExportCsv('items')} disabled={Boolean(exporting)}>
            <View style={[styles.iconCircle, { backgroundColor: '#F0FDF4' }]}>
              <Ionicons name="cube-outline" size={20} color="#16A34A" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.exportCardTitle}>गिफ्ट व सामान सूची (CSV)</Text>
              <Text style={styles.exportCardSub}>वस्तुएँ, मात्राएँ व अनुमानित मूल्य</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F4EFE7' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  header: {
    backgroundColor: '#1F3352',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 48,
    paddingBottom: 16,
  },
  backBtn: { padding: 6 },
  backBtnText: { color: '#F4EFE7', fontSize: 15, fontWeight: '700' },
  headerTitle: { color: '#F4EFE7', fontSize: 18, fontWeight: '800' },
  loadingBanner: {
    backgroundColor: '#FEF3C7',
    paddingVertical: 10,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: { color: '#92400E', fontSize: 13, fontWeight: '600' },
  scroll: { padding: 16, paddingBottom: 40 },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 16,
    marginBottom: 16,
    elevation: 1,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1F3352',
    marginBottom: 12,
  },
  statsRow: { flexDirection: 'row', gap: 10 },
  statBox: {
    flex: 1,
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
  },
  statLabel: { fontSize: 11, fontWeight: '600', color: '#4B5563' },
  statValue: { fontSize: 18, fontWeight: '800', marginTop: 4 },
  statSub: { fontSize: 10, color: '#6B7280', marginTop: 2 },
  infoNote: { fontSize: 11, color: '#6B7280', marginTop: 10, lineHeight: 16 },
  exportCard: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  iconCircle: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#F4EFE7',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  exportCardTitle: { fontSize: 14, fontWeight: '700', color: '#1F2937' },
  exportCardSub: { fontSize: 12, color: '#6B7280', marginTop: 2 },
  yearSelectorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 12,
    marginBottom: 6,
  },
  yearLabel: { fontSize: 12, color: '#4B5563', fontWeight: '600' },
  yearChip: {
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 6,
    backgroundColor: '#F3F4F6',
  },
  yearChipActive: { backgroundColor: '#1F3352' },
  yearChipText: { fontSize: 12, fontWeight: '600', color: '#6B7280' },
  yearChipTextActive: { color: '#F4EFE7' },
  eventRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F3F4F6',
  },
  eventTitle: { fontSize: 14, fontWeight: '600', color: '#1F2937' },
  eventMeta: { fontSize: 12, color: '#6B7280', marginTop: 2 },
  pdfBadge: {
    backgroundColor: '#C05A2B',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  pdfBadgeText: { color: '#FFFFFF', fontSize: 11, fontWeight: '700' },
});
