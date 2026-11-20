import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { router, useFocusEffect } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useDashboard } from '../../src/hooks';
import { formatCurrency } from '../../src/utils/currency';
import { formatDate } from '../../src/utils/date';
import { LoadingView } from '../../src/components/ui';

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { summary, loading, error, refresh } = useDashboard();
  const [refreshing, setRefreshing] = useState(false);

  // Auto-refresh when tab is focused
  useFocusEffect(
    useCallback(() => {
      refresh();
    }, [refresh])
  );

  const onPullRefresh = useCallback(async () => {
    setRefreshing(true);
    refresh();
    setRefreshing(false);
  }, [refresh]);

  if (loading && !summary) {
    return <LoadingView message="डेटा लोड हो रहा है..." />;
  }

  const topPadding = Math.max(insets.top, 16);

  return (
    <View style={styles.container}>
      <StatusBar style="light" />

      {/* A. Compact Premium Header */}
      <View style={[styles.header, { paddingTop: topPadding + 6 }]}>
        <View style={styles.headerContent}>
          <View style={styles.headerLeft}>
            <Text style={styles.headerTitle}>व्यवहार</Text>
            <Text style={styles.headerTagline}>रिश्तों का हिसाब, हमेशा याद।</Text>
          </View>
          <TouchableOpacity
            style={styles.settingsButton}
            onPress={() => router.push('/(tabs)/settings')}
            activeOpacity={0.7}
            accessibilityRole="button"
            accessibilityLabel="सेटिंग्स खोलें"
          >
            <Ionicons name="settings-outline" size={20} color="#F4EFE7" />
          </TouchableOpacity>
        </View>
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onPullRefresh}
            colors={['#C05A2B']}
            tintColor="#C05A2B"
          />
        }
      >
        {error && (
          <View style={styles.errorBanner}>
            <Ionicons name="alert-circle-outline" size={18} color="#DC2626" style={{ marginRight: 6 }} />
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {/* B. Financial Summary (Mila vs Diya Strictly Separated) */}
        <View style={styles.financialRow}>
          {/* Card 1: Kul Mila */}
          <View style={styles.milaCard}>
            <View style={styles.cardHeaderRow}>
              <View style={styles.milaBadge}>
                <Ionicons name="arrow-down" size={14} color="#15803D" />
              </View>
              <Text style={styles.milaLabel}>कुल मिला</Text>
            </View>
            <Text style={styles.milaAmount} numberOfLines={1} adjustsFontSizeToFit>
              {formatCurrency(summary?.totalMilaPaise ?? 0)}
            </Text>
            <Text style={styles.milaSubtext}>प्राप्त राशि</Text>
          </View>

          {/* Card 2: Kul Diya */}
          <View style={styles.diyaCard}>
            <View style={styles.cardHeaderRow}>
              <View style={styles.diyaBadge}>
                <Ionicons name="arrow-up" size={14} color="#B91C1C" />
              </View>
              <Text style={styles.diyaLabel}>कुल दिया</Text>
            </View>
            <Text style={styles.diyaAmount} numberOfLines={1} adjustsFontSizeToFit>
              {formatCurrency(summary?.totalDiyaPaise ?? 0)}
            </Text>
            <Text style={styles.diyaSubtext}>दी गई राशि</Text>
          </View>
        </View>

        {/* C. Overview Statistics (Unified Single-Bar Layout) */}
        <View style={styles.statsContainer}>
          <TouchableOpacity
            style={styles.statItem}
            onPress={() => router.push('/(tabs)/events')}
            activeOpacity={0.7}
          >
            <View style={styles.statIconRow}>
              <Ionicons name="calendar-outline" size={14} color="#64748B" style={{ marginRight: 4 }} />
              <Text style={styles.statItemLabel}>कार्यक्रम</Text>
            </View>
            <Text style={styles.statItemValue}>{summary?.totalEvents ?? 0}</Text>
          </TouchableOpacity>

          <View style={styles.statDivider} />

          <TouchableOpacity
            style={styles.statItem}
            onPress={() => router.push('/(tabs)/people')}
            activeOpacity={0.7}
          >
            <View style={styles.statIconRow}>
              <Ionicons name="people-outline" size={14} color="#64748B" style={{ marginRight: 4 }} />
              <Text style={styles.statItemLabel}>व्यक्ति</Text>
            </View>
            <Text style={styles.statItemValue}>{summary?.totalPeople ?? 0}</Text>
          </TouchableOpacity>

          <View style={styles.statDivider} />

          <TouchableOpacity
            style={styles.statItem}
            onPress={() => router.push('/(tabs)/bahi')}
            activeOpacity={0.7}
          >
            <View style={styles.statIconRow}>
              <Ionicons name="book-outline" size={14} color="#64748B" style={{ marginRight: 4 }} />
              <Text style={styles.statItemLabel}>व्यवहार</Text>
            </View>
            <Text style={styles.statItemValue}>{summary?.totalEntries ?? 0}</Text>
          </TouchableOpacity>
        </View>

        {/* D. Current / Recent Event (हाल का कार्यक्रम) */}
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>हाल का कार्यक्रम</Text>
          {summary?.recentEventTitle && (
            <TouchableOpacity onPress={() => router.push('/(tabs)/events')} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
              <Text style={styles.sectionActionText}>सभी देखें</Text>
            </TouchableOpacity>
          )}
        </View>

        {summary?.recentEventTitle ? (
          <TouchableOpacity
            style={styles.eventCard}
            onPress={() => {
              if (summary.recentEventId) {
                router.push(`/event/${summary.recentEventId}`);
              } else {
                router.push('/(tabs)/events');
              }
            }}
            activeOpacity={0.75}
          >
            <View style={styles.eventLeftBadge}>
              <Ionicons name="calendar" size={20} color="#C05A2B" />
            </View>
            <View style={styles.eventDetails}>
              <Text style={styles.eventTitle} numberOfLines={1}>
                {summary.recentEventTitle}
              </Text>
              {summary.recentEventDate && (
                <View style={styles.eventDateRow}>
                  <Ionicons name="time-outline" size={13} color="#64748B" style={{ marginRight: 4 }} />
                  <Text style={styles.eventDate}>{formatDate(summary.recentEventDate)}</Text>
                </View>
              )}
            </View>
            <Ionicons name="chevron-forward" size={18} color="#94A3B8" />
          </TouchableOpacity>
        ) : (
          <View style={styles.emptyEventCard}>
            <View style={styles.emptyIconBadge}>
              <Ionicons name="calendar-outline" size={20} color="#64748B" />
            </View>
            <Text style={styles.emptyEventText}>अभी कोई सक्रिय कार्यक्रम नहीं है</Text>
            <TouchableOpacity
              style={styles.createEventButton}
              onPress={() => router.push('/event/new')}
              activeOpacity={0.8}
            >
              <Ionicons name="add" size={16} color="#1F3352" style={{ marginRight: 4 }} />
              <Text style={styles.createEventButtonText}>पहला कार्यक्रम बनाएं</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* E. Quick Actions (त्वरित कार्य) */}
        <Text style={[styles.sectionTitle, { marginTop: 18, marginBottom: 10 }]}>त्वरित कार्य</Text>

        {/* Primary Action Tile */}
        <TouchableOpacity
          style={styles.primaryActionTile}
          onPress={() => router.push('/entry/new')}
          activeOpacity={0.85}
        >
          <View style={styles.primaryActionBadge}>
            <Ionicons name="wallet-outline" size={20} color="#FFFFFF" />
          </View>
          <View style={styles.actionTextContainer}>
            <Text style={styles.primaryActionTitle}>नया व्यवहार दर्ज करें</Text>
            <Text style={styles.primaryActionSubtitle}>रुपये या भेंट की नई प्रविष्टि करें</Text>
          </View>
          <View style={styles.primaryChevronBadge}>
            <Ionicons name="arrow-forward" size={16} color="#FFFFFF" />
          </View>
        </TouchableOpacity>

        {/* Secondary Action 1: Create Event */}
        <TouchableOpacity
          style={styles.secondaryActionTile}
          onPress={() => router.push('/event/new')}
          activeOpacity={0.75}
        >
          <View style={styles.secondaryActionBadge}>
            <Ionicons name="calendar-outline" size={18} color="#1F3352" />
          </View>
          <View style={styles.actionTextContainer}>
            <Text style={styles.secondaryActionTitle}>नया कार्यक्रम बनाएं</Text>
            <Text style={styles.secondaryActionSubtitle}>शादी, जन्मदिन या पारिवारिक उत्सव</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color="#94A3B8" />
        </TouchableOpacity>

        {/* Secondary Action 2: Add Person */}
        <TouchableOpacity
          style={styles.secondaryActionTile}
          onPress={() => router.push('/person/new')}
          activeOpacity={0.75}
        >
          <View style={styles.secondaryActionBadge}>
            <Ionicons name="person-add-outline" size={18} color="#1F3352" />
          </View>
          <View style={styles.actionTextContainer}>
            <Text style={styles.secondaryActionTitle}>नया व्यक्ति जोड़ें</Text>
            <Text style={styles.secondaryActionSubtitle}>रिश्तेदार, मित्र या परिवार का सदस्य</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color="#94A3B8" />
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4EFE7',
  },
  header: {
    backgroundColor: '#1F3352',
    paddingBottom: 16,
    paddingHorizontal: 20,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 10,
    elevation: 6,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerLeft: {
    flex: 1,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: 0.5,
  },
  headerTagline: {
    fontSize: 12,
    color: '#94A3B8',
    marginTop: 2,
    fontWeight: '500',
  },
  settingsButton: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: 'rgba(255, 255, 255, 0.12)',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.18)',
  },
  scroll: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 110, // Generous spacing so floating tab bar never covers content
  },
  errorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEE2E2',
    borderRadius: 12,
    padding: 12,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#FECACA',
  },
  errorText: {
    color: '#DC2626',
    fontSize: 13,
    fontWeight: '500',
    flex: 1,
  },
  financialRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 12,
  },
  milaCard: {
    flex: 1,
    backgroundColor: '#E2F5EB',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(32, 155, 104, 0.2)',
    shadowColor: '#209B68',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  diyaCard: {
    flex: 1,
    backgroundColor: '#FCE9E7',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(220, 38, 38, 0.2)',
    shadowColor: '#DC2626',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  cardHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  milaBadge: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: '#D1F2E0',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 6,
  },
  diyaBadge: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: '#FBD5D2',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 6,
  },
  milaLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#15803D',
  },
  diyaLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: '#B91C1C',
  },
  milaAmount: {
    fontSize: 22,
    fontWeight: '800',
    color: '#15803D',
    letterSpacing: -0.5,
  },
  diyaAmount: {
    fontSize: 22,
    fontWeight: '800',
    color: '#B91C1C',
    letterSpacing: -0.5,
  },
  milaSubtext: {
    fontSize: 11,
    fontWeight: '500',
    color: '#166534',
    opacity: 0.85,
    marginTop: 4,
  },
  diyaSubtext: {
    fontSize: 11,
    fontWeight: '500',
    color: '#991B1B',
    opacity: 0.85,
    marginTop: 4,
  },
  statsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    paddingVertical: 12,
    paddingHorizontal: 6,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
  },
  statIconRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  statItemLabel: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '600',
  },
  statItemValue: {
    fontSize: 20,
    fontWeight: '800',
    color: '#1F3352',
  },
  statDivider: {
    width: 1,
    height: 32,
    backgroundColor: '#E2E8F0',
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#1F3352',
    letterSpacing: 0.2,
  },
  sectionActionText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#C05A2B',
  },
  eventCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
    marginBottom: 6,
  },
  eventLeftBadge: {
    width: 42,
    height: 42,
    borderRadius: 12,
    backgroundColor: '#FDEEE8',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  eventDetails: {
    flex: 1,
  },
  eventTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#1F3352',
  },
  eventDateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  eventDate: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '500',
  },
  emptyEventCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderStyle: 'dashed',
    marginBottom: 6,
  },
  emptyIconBadge: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  emptyEventText: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
    marginBottom: 12,
  },
  createEventButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F4EFE7',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(31, 51, 82, 0.15)',
  },
  createEventButtonText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#1F3352',
  },
  primaryActionTile: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#C05A2B',
    borderRadius: 16,
    padding: 14,
    marginBottom: 10,
    shadowColor: '#C05A2B',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.28,
    shadowRadius: 8,
    elevation: 4,
  },
  primaryActionBadge: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  actionTextContainer: {
    flex: 1,
  },
  primaryActionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  primaryActionSubtitle: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.85)',
    marginTop: 2,
    fontWeight: '500',
  },
  primaryChevronBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryActionTile: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 13,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  secondaryActionBadge: {
    width: 38,
    height: 38,
    borderRadius: 11,
    backgroundColor: '#EBF1F8',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  secondaryActionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1F3352',
  },
  secondaryActionSubtitle: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 2,
  },
});
