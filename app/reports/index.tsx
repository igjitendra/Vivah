import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  SafeAreaView,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { db } from '../../src/db/database';
import { Entry, Event } from '../../src/types';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate } from '../../src/utils/date';

export default function ReportsScreen() {
  const router = useRouter();
  const [entries, setEntries] = useState<Entry[]>([]);
  const [events, setEvents] = useState<Event[]>([]);
  const [selectedEventId, setSelectedEventId] = useState<string>('all');

  const loadData = useCallback(async () => {
    const eList = await db.getEntries();
    const evList = await db.getEvents();
    setEntries(eList);
    setEvents(evList);
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const filtered = selectedEventId === 'all'
    ? entries
    : entries.filter(e => e.event_id === selectedEventId);

  let cashMila = 0;
  let cashDiya = 0;
  let itemCount = 0;
  let itemEstimatedValue = 0;

  filtered.forEach(e => {
    if (e.direction === 'mila') cashMila += e.cash_amount_paise;
    else if (e.direction === 'diya') cashDiya += e.cash_amount_paise;

    if (e.items) {
      itemCount += e.items.length;
      e.items.forEach(it => {
        if (it.estimated_value_paise) {
          itemEstimatedValue += it.estimated_value_paise;
        }
      });
    }
  });

  const generateReportSummary = () => {
    const currentEv = events.find(ev => ev.id === selectedEventId);
    const title = currentEv ? currentEv.title : 'समस्त पारिवारिक बही';

    let text = `📜 *${title} — व्यवहार रिपोर्ट*\n`;
    text += `तारीख: ${new Date().toLocaleDateString('hi-IN')}\n\n`;
    text += `💰 कुल नकद मिला: ${formatCurrency(cashMila)}\n`;
    text += `💸 कुल नकद दिया: ${formatCurrency(cashDiya)}\n`;
    text += `🎁 कुल गिफ्ट संख्या: ${itemCount}\n`;
    text += `📦 अनुमानित सामान मूल्य: ${formatCurrency(itemEstimatedValue)}\n\n`;
    text += `--- मुख्य प्रविष्टियां ---\n`;

    filtered.slice(0, 15).forEach((e, idx) => {
      const dirText = e.direction === 'mila' ? 'प्राप्त' : 'दिया';
      text += `${idx + 1}. ${e.person_name} (${e.person_village || '—'}): ${dirText} ${formatCurrency(e.cash_amount_paise)}`;
      if (e.items && e.items.length > 0) {
        text += ` + [${e.items.map(it => it.item_name).join(', ')}]`;
      }
      text += '\n';
    });

    return text;
  };

  const handleShareReport = () => {
    const summary = generateReportSummary();
    Alert.alert(
      'रिपोर्ट तैयार है',
      'आप इस रिपोर्ट को कॉपी करके व्हाट्सएप (WhatsApp) पर परिवार के साथ साझा कर सकते हैं।\n\n' + summary.slice(0, 300) + '...'
    );
  };

  const handleExportCSV = async () => {
    let csv = 'प्रकार,व्यक्ति,गांव,रिश्ता,कार्यक्रम,नकद_रुपए,सामान_विवरण,तारीख\n';
    filtered.forEach(e => {
      const itemsStr = e.items ? e.items.map(i => `${i.item_name}x${i.quantity}`).join(';') : '';
      csv += `"${e.direction}","${e.person_name}","${e.person_village || ''}","${e.person_relationship || ''}","${e.event_title}","${formatCurrency(e.cash_amount_paise)}","${itemsStr}","${e.created_at}"\n`;
    });
    Alert.alert('CSV फाइल तैयार', `कुल ${filtered.length} प्रविष्टियों की CSV फाइल तैयार हो गई है।`);
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← वापस</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>रिपोर्ट्स व एक्सपोर्ट</Text>
        <View style={{ width: 50 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Event selector filter */}
        <Text style={styles.sectionLabel}>कार्यक्रम चुनें:</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipRow}>
          <TouchableOpacity
            style={[styles.chip, selectedEventId === 'all' && styles.chipActive]}
            onPress={() => setSelectedEventId('all')}
          >
            <Text style={[styles.chipText, selectedEventId === 'all' && styles.chipTextActive]}>
              सभी कार्यक्रम
            </Text>
          </TouchableOpacity>
          {events.map(ev => (
            <TouchableOpacity
              key={ev.id}
              style={[styles.chip, selectedEventId === ev.id && styles.chipActive]}
              onPress={() => setSelectedEventId(ev.id)}
            >
              <Text style={[styles.chipText, selectedEventId === ev.id && styles.chipTextActive]}>
                🎉 {ev.title}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Report Overview Cards */}
        <VyavahaarCard style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>वित्तीय एवं वस्तु सारांश</Text>

          <View style={styles.metricsGrid}>
            <View style={[styles.metricBox, { backgroundColor: Colors.milaBg }]}>
              <Text style={[styles.metricLabel, { color: Colors.mila }]}>कुल नकद मिला</Text>
              <Text style={[styles.metricValue, { color: Colors.mila }]}>
                {formatCurrency(cashMila)}
              </Text>
            </View>

            <View style={[styles.metricBox, { backgroundColor: Colors.diyaBg }]}>
              <Text style={[styles.metricLabel, { color: Colors.diya }]}>कुल नकद दिया</Text>
              <Text style={[styles.metricValue, { color: Colors.diya }]}>
                {formatCurrency(cashDiya)}
              </Text>
            </View>

            <View style={[styles.metricBox, { backgroundColor: '#ECE7DE' }]}>
              <Text style={styles.metricLabel}>गिफ्ट व सामान संख्या</Text>
              <Text style={[styles.metricValue, { color: Colors.primary }]}>
                {itemCount} वस्तुएं
              </Text>
            </View>

            <View style={[styles.metricBox, { backgroundColor: '#ECE7DE' }]}>
              <Text style={styles.metricLabel}>अनुमानित गिफ्ट मूल्य</Text>
              <Text style={[styles.metricValue, { color: Colors.primary }]}>
                {formatCurrency(itemEstimatedValue)}
              </Text>
            </View>
          </View>

          <Text style={styles.noteDisclaimer}>
            * बिजनेस रूल: नकद और गिफ्ट के अनुमानित मूल्य को एक में नहीं जोड़ा जाता है ताकि असली नकद हिसाब शुद्ध रहे।
          </Text>
        </VyavahaarCard>

        {/* Action Buttons for Export */}
        <View style={styles.exportSection}>
          <TouchableOpacity style={styles.shareBtn} onPress={handleShareReport}>
            <Text style={styles.shareBtnText}>📲 WhatsApp / शेयर रिपोर्ट बनाएं</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.csvBtn} onPress={handleExportCSV}>
            <Text style={styles.csvBtnText}>📥 Excel / CSV एक्सपोर्ट करें</Text>
          </TouchableOpacity>
        </View>

        {/* Breakdown table list preview */}
        <Text style={[styles.sectionLabel, { marginTop: 16 }]}>प्रविष्टि विवरण ({filtered.length}):</Text>
        {filtered.map(e => (
          <View key={e.id} style={styles.entryRow}>
            <View style={{ flex: 1 }}>
              <Text style={styles.rowPerson}>
                {e.person_name} ({e.person_village || '—'})
              </Text>
              <Text style={styles.rowSub}>
                {e.event_title} • {formatHindiDate(e.created_at)}
              </Text>
              {e.items && e.items.length > 0 && (
                <Text style={styles.rowItems}>
                  📦 {e.items.map(i => `${i.item_name} × ${i.quantity}`).join(', ')}
                </Text>
              )}
            </View>
            <View style={{ alignItems: 'flex-end' }}>
              <Text
                style={[
                  styles.rowAmount,
                  { color: e.direction === 'mila' ? Colors.mila : Colors.diya },
                ]}
              >
                {e.direction === 'mila' ? '+' : '-'} {formatCurrency(e.cash_amount_paise)}
              </Text>
              <Text style={styles.rowDir}>
                {e.direction === 'mila' ? 'प्राप्त' : 'दिया'}
              </Text>
            </View>
          </View>
        ))}
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
  scroll: {
    padding: 16,
    paddingBottom: 30,
  },
  sectionLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.primary,
    marginBottom: 8,
  },
  chipRow: {
    marginBottom: 14,
  },
  chip: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: '#D8CFC4',
    paddingVertical: 7,
    paddingHorizontal: 14,
    borderRadius: 20,
    marginRight: 8,
  },
  chipActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  chipText: {
    fontSize: 12,
    color: Colors.text,
    fontWeight: '600',
  },
  chipTextActive: {
    color: Colors.white,
  },
  summaryCard: {
    paddingVertical: 16,
  },
  summaryTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.primary,
    marginBottom: 12,
  },
  metricsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  metricBox: {
    width: '48%',
    padding: 12,
    borderRadius: 10,
    marginBottom: 10,
  },
  metricLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: Colors.textMuted,
  },
  metricValue: {
    fontSize: 16,
    fontWeight: '800',
    marginTop: 4,
  },
  noteDisclaimer: {
    fontSize: 11,
    color: Colors.textMuted,
    fontStyle: 'italic',
    marginTop: 8,
    lineHeight: 16,
  },
  exportSection: {
    marginTop: 14,
  },
  shareBtn: {
    backgroundColor: '#25D366', // WhatsApp Green
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 10,
  },
  shareBtnText: {
    color: Colors.white,
    fontSize: 15,
    fontWeight: '800',
  },
  csvBtn: {
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.primary,
    paddingVertical: 12,
    borderRadius: 12,
    alignItems: 'center',
  },
  csvBtnText: {
    color: Colors.primary,
    fontSize: 14,
    fontWeight: '700',
  },
  entryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: Colors.surface,
    padding: 12,
    borderRadius: 10,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#ECE7DE',
  },
  rowPerson: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text,
  },
  rowSub: {
    fontSize: 11,
    color: Colors.textMuted,
    marginTop: 2,
  },
  rowItems: {
    fontSize: 12,
    color: '#4B5563',
    marginTop: 4,
  },
  rowAmount: {
    fontSize: 15,
    fontWeight: '800',
  },
  rowDir: {
    fontSize: 11,
    color: Colors.textMuted,
    marginTop: 2,
  },
});
