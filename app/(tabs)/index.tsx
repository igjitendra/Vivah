import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  SafeAreaView,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { useRouter, useFocusEffect } from 'expo-router';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { DashboardSummary, Reminder } from '../../src/types';
import { StatCard } from '../../src/components/StatCard';
import { DirectionBadge } from '../../src/components/DirectionBadge';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';
import { formatCurrency } from '../../src/utils/currency';
import { formatHindiDate } from '../../src/utils/date';

export default function HomeScreen() {
  const router = useRouter();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [reminders, setReminders] = useState<Reminder[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = useCallback(async () => {
    try {
      const data = await db.getDashboardSummary();
      const rems = await db.getReminders();
      setSummary(data);
      setReminders(rems.filter(r => !r.is_completed).slice(0, 2));
    } catch (err) {
      console.error('Error loading dashboard:', err);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [loadData])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="light" />
      
      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>{Strings.appName}</Text>
          <Text style={styles.headerSubtitle}>{Strings.appTagline}</Text>
        </View>
        <TouchableOpacity
          style={styles.quickAddHeaderBtn}
          onPress={() => router.push('/entry/new')}
        >
          <Text style={styles.quickAddHeaderText}>+ व्यवहार</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {/* Cash Summary Cards */}
        <View style={styles.statsRow}>
          <StatCard
            title="कुल मिला (प्राप्त)"
            amountPaise={summary?.totalMilaPaise || 0}
            type="mila"
            countLabel="नकद आमदनी बही"
          />
          <StatCard
            title="कुल दिया (शगुन)"
            amountPaise={summary?.totalDiyaPaise || 0}
            type="diya"
            countLabel="नकद खर्च / न्योता"
          />
        </View>

        {/* Quick Action Buttons */}
        <View style={styles.actionsContainer}>
          <TouchableOpacity
            style={styles.primaryActionBtn}
            onPress={() => router.push('/entry/new')}
          >
            <Text style={styles.primaryActionBtnText}>{Strings.addEntry}</Text>
            <Text style={styles.primaryActionBtnSubtext}>पैसे या सामान का हिसाब तुरंत लिखें</Text>
          </TouchableOpacity>

          <View style={styles.secondaryActionsRow}>
            <TouchableOpacity
              style={styles.secondaryActionBtn}
              onPress={() => router.push('/events')}
            >
              <Text style={styles.secondaryActionText}>📅 {Strings.addEvent}</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryActionBtn}
              onPress={() => router.push('/gifts')}
            >
              <Text style={styles.secondaryActionText}>🎁 गिफ्ट व सामान</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.secondaryActionBtn}
              onPress={() => router.push('/reports')}
            >
              <Text style={styles.secondaryActionText}>📊 रिपोर्ट</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Reminders Banner */}
        {reminders.length > 0 && (
          <View style={styles.remindersBox}>
            <View style={styles.remindersHeader}>
              <Text style={styles.remindersIcon}>🔔</Text>
              <Text style={styles.remindersTitle}>आगामी कार्यक्रम की याद</Text>
            </View>
            {reminders.map(rem => (
              <View key={rem.id} style={styles.reminderItem}>
                <Text style={styles.reminderTarget}>
                  {rem.person_name} ({rem.person_village}) - {rem.event_title}
                </Text>
                <Text style={styles.reminderDate}>तारीख: {formatHindiDate(rem.target_date)}</Text>
                {rem.note ? <Text style={styles.reminderNote}>"{rem.note}"</Text> : null}
              </View>
            ))}
          </View>
        )}

        {/* Recent Transactions List */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>हाल की प्रविष्टियां</Text>
          <TouchableOpacity onPress={() => router.push('/bahi')}>
            <Text style={styles.seeAllText}>पूरी बही देखें →</Text>
          </TouchableOpacity>
        </View>

        {summary?.recentEntries && summary.recentEntries.length > 0 ? (
          summary.recentEntries.map(entry => (
            <VyavahaarCard key={entry.id} style={styles.entryCard}>
              <View style={styles.entryTopRow}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.personName}>{entry.person_name}</Text>
                  <Text style={styles.personMeta}>
                    {entry.person_relationship ? `${entry.person_relationship} • ` : ''}
                    {entry.person_village || 'गांव दर्ज नहीं'}
                  </Text>
                </View>
                <DirectionBadge direction={entry.direction} />
              </View>

              <View style={styles.entryMiddleRow}>
                <Text style={styles.eventBadge}>🎉 {entry.event_title}</Text>
                <Text
                  style={[
                    styles.cashAmount,
                    { color: entry.direction === 'mila' ? Colors.mila : Colors.diya },
                  ]}
                >
                  {formatCurrency(entry.cash_amount_paise)}
                </Text>
              </View>

              {/* Items Display */}
              {entry.items && entry.items.length > 0 && (
                <View style={styles.itemsWrapper}>
                  {entry.items.map(item => (
                    <Text key={item.id} style={styles.itemText}>
                      📦 {item.item_name} × {item.quantity} {item.unit}
                      {item.estimated_value_paise
                        ? ` (अनुमानित ${formatCurrency(item.estimated_value_paise)})`
                        : ''}
                    </Text>
                  ))}
                </View>
              )}

              {entry.notes ? (
                <Text style={styles.entryNotes}>📝 {entry.notes}</Text>
              ) : null}

              <Text style={styles.entryDate}>{formatHindiDate(entry.created_at)}</Text>
            </VyavahaarCard>
          ))
        ) : (
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyText}>{Strings.noEntriesYet}</Text>
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
    paddingHorizontal: 20,
    paddingTop: 18,
    paddingBottom: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: Colors.white,
    letterSpacing: 0.5,
  },
  headerSubtitle: {
    fontSize: 12,
    color: '#D8CFC4',
    marginTop: 2,
  },
  quickAddHeaderBtn: {
    backgroundColor: Colors.accent,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
  },
  quickAddHeaderText: {
    color: Colors.white,
    fontWeight: '700',
    fontSize: 14,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 32,
  },
  statsRow: {
    flexDirection: 'row',
    marginBottom: 16,
  },
  actionsContainer: {
    marginBottom: 20,
  },
  primaryActionBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 14,
    paddingVertical: 14,
    paddingHorizontal: 20,
    alignItems: 'center',
    shadowColor: Colors.accent,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 6,
    elevation: 3,
  },
  primaryActionBtnText: {
    color: Colors.white,
    fontSize: 18,
    fontWeight: '800',
  },
  primaryActionBtnSubtext: {
    color: '#FDEEE8',
    fontSize: 12,
    marginTop: 2,
  },
  secondaryActionsRow: {
    flexDirection: 'row',
    marginTop: 10,
    justifyContent: 'space-between',
  },
  secondaryActionBtn: {
    flex: 1,
    backgroundColor: Colors.surface,
    paddingVertical: 10,
    paddingHorizontal: 6,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#E6DFD5',
    marginHorizontal: 3,
    alignItems: 'center',
  },
  secondaryActionText: {
    fontSize: 12,
    fontWeight: '600',
    color: Colors.primary,
  },
  remindersBox: {
    backgroundColor: '#FEF9C3',
    borderColor: '#FDE047',
    borderWidth: 1,
    borderRadius: 12,
    padding: 14,
    marginBottom: 20,
  },
  remindersHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  remindersIcon: {
    fontSize: 16,
    marginRight: 6,
  },
  remindersTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#854D0E',
  },
  reminderItem: {
    marginTop: 4,
  },
  reminderTarget: {
    fontSize: 13,
    fontWeight: '700',
    color: '#713F12',
  },
  reminderDate: {
    fontSize: 11,
    color: '#A16207',
    marginTop: 2,
  },
  reminderNote: {
    fontSize: 11,
    fontStyle: 'italic',
    color: '#713F12',
    marginTop: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
    marginTop: 4,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.primary,
  },
  seeAllText: {
    fontSize: 13,
    fontWeight: '600',
    color: Colors.accent,
  },
  entryCard: {
    paddingVertical: 14,
  },
  entryTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  personName: {
    fontSize: 17,
    fontWeight: '700',
    color: Colors.text,
  },
  personMeta: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  entryMiddleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
  },
  eventBadge: {
    fontSize: 13,
    color: Colors.primary,
    fontWeight: '600',
    backgroundColor: '#EBE5D8',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  cashAmount: {
    fontSize: 19,
    fontWeight: '800',
  },
  itemsWrapper: {
    backgroundColor: '#FAF7F2',
    padding: 8,
    borderRadius: 8,
    marginTop: 8,
  },
  itemText: {
    fontSize: 13,
    color: '#4B5563',
    fontWeight: '500',
  },
  entryNotes: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 6,
    fontStyle: 'italic',
  },
  entryDate: {
    fontSize: 10,
    color: Colors.textSubtle,
    marginTop: 6,
    textAlign: 'right',
  },
  emptyContainer: {
    backgroundColor: Colors.surface,
    padding: 28,
    borderRadius: 14,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E6DFD5',
  },
  emptyText: {
    color: Colors.textMuted,
    fontSize: 14,
  },
});
