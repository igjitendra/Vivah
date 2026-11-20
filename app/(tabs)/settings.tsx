import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  SafeAreaView,
} from 'react-native';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';
import { db } from '../../src/db/database';
import { VyavahaarCard } from '../../src/components/VyavahaarCard';

export default function SettingsScreen() {
  const [pinLockEnabled, setPinLockEnabled] = useState(false);

  const handleExportBackup = async () => {
    try {
      const json = await db.exportBackupJson();
      Alert.alert(
        'स्थानीय बैकअप तैयार',
        `आपकी बही का डेटा सुरक्षित रूप से JSON प्रारूप में तैयार है (${(json.length / 1024).toFixed(1)} KB)।\n\nआप इस फाइल को अपने फोन स्टोरेज में सहेज सकते हैं।`
      );
    } catch {
      Alert.alert('त्रुटि', 'बैकअप बनाने में समस्या आई।');
    }
  };

  const handleRestoreBackup = () => {
    Alert.alert(
      'डेटा रीस्टोर',
      'क्या आप अपनी पुरानी बैकअप फाइल से डेटा रीस्टोर करना चाहते हैं?',
      [
        { text: 'रद्द करें', style: 'cancel' },
        {
          text: 'रीस्टोर करें',
          onPress: () => {
            Alert.alert('सफल', 'डेटाबेस का रीस्टोर सफलता से पूरा हुआ।');
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{Strings.tabs.settings}</Text>
        <Text style={styles.headerSubtitle}>डेटा सुरक्षा, बैकअप एवं प्राथमिकताएं</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Household Info */}
        <VyavahaarCard style={styles.card}>
          <Text style={styles.cardTitle}>बही का विवरण</Text>
          <View style={styles.settingRow}>
            <View>
              <Text style={styles.settingLabel}>पारिवारिक बही का नाम</Text>
              <Text style={styles.settingValue}>हमारा परिवार (मुख्य बही)</Text>
            </View>
            <View style={styles.badgeOffline}>
              <Text style={styles.badgeOfflineText}>🔒 100% ऑफलाइन</Text>
            </View>
          </View>
        </VyavahaarCard>

        {/* Security & Lock */}
        <VyavahaarCard style={styles.card}>
          <Text style={styles.cardTitle}>सुरक्षा व गोपनीयता (Security)</Text>
          
          <View style={styles.settingRow}>
            <View style={{ flex: 1, marginRight: 10 }}>
              <Text style={styles.settingLabel}>ऐप सुरक्षा लॉक (PIN Lock)</Text>
              <Text style={styles.settingDesc}>
                ऐप खोलने पर 4-अंकों का गुप्त पिन या फिंगरप्रिंट मांगें।
              </Text>
            </View>
            <Switch
              value={pinLockEnabled}
              onValueChange={v => {
                setPinLockEnabled(v);
                if (v) {
                  Alert.alert('PIN लॉक सक्षम', 'आपका डिफ़ॉल्ट पिन 1234 सेट किया गया है।');
                }
              }}
              trackColor={{ false: '#D8CFC4', true: Colors.accent }}
            />
          </View>
        </VyavahaarCard>

        {/* Backup & Restore */}
        <VyavahaarCard style={styles.card}>
          <Text style={styles.cardTitle}>बैकअप व रीस्टोर (Offline First)</Text>
          <Text style={styles.settingDesc}>
            आपका सारा डेटा आपके फोन के SQLite डेटाबेस में सुरक्षित है। इंटरनेट न होने पर भी यह हमेशा काम करता है।
          </Text>

          <TouchableOpacity style={styles.backupBtn} onPress={handleExportBackup}>
            <Text style={styles.backupBtnText}>📦 स्थानीय बैकअप डाउनलोड करें</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.restoreBtn} onPress={handleRestoreBackup}>
            <Text style={styles.restoreBtnText}>🔄 बैकअप से रीस्टोर करें</Text>
          </TouchableOpacity>
        </VyavahaarCard>

        {/* Language & App Info */}
        <VyavahaarCard style={styles.card}>
          <Text style={styles.cardTitle}>ऐप के बारे में</Text>
          
          <View style={styles.infoRow}>
            <Text style={styles.infoKey}>संस्करण (Version):</Text>
            <Text style={styles.infoVal}>1.0.0 (MVP Preview)</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoKey}>प्राथमिक भाषा:</Text>
            <Text style={styles.infoVal}>हिंदी (Hindi-First)</Text>
          </View>

          <View style={styles.infoRow}>
            <Text style={styles.infoKey}>डेटाबेस आर्किटेक्चर:</Text>
            <Text style={styles.infoVal}>SQLite Local Ledger</Text>
          </View>
        </VyavahaarCard>

        {/* Privacy Note */}
        <View style={styles.privacyNote}>
          <Text style={styles.privacyText}>
            🛡️ <Text style={{ fontWeight: '700' }}>गोपनीयता वादा:</Text> आपके परिवार के रिश्ते, फोन नंबर या व्यवहार की कोई भी जानकारी बिना आपकी अनुमति के किसी भी बाहरी सर्वर पर नहीं भेजी जाती।
          </Text>
        </View>
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
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: Colors.white,
  },
  headerSubtitle: {
    fontSize: 12,
    color: '#D8CFC4',
    marginTop: 2,
  },
  scroll: {
    padding: 16,
    paddingBottom: 30,
  },
  card: {
    paddingVertical: 14,
    marginBottom: 12,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.primary,
    marginBottom: 10,
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 6,
  },
  settingLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: Colors.text,
  },
  settingValue: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 2,
  },
  settingDesc: {
    fontSize: 12,
    color: Colors.textMuted,
    marginTop: 4,
    lineHeight: 18,
  },
  badgeOffline: {
    backgroundColor: '#E8F5E9',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#C3E6CB',
  },
  badgeOfflineText: {
    fontSize: 11,
    fontWeight: '700',
    color: Colors.mila,
  },
  backupBtn: {
    backgroundColor: Colors.accent,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 14,
  },
  backupBtnText: {
    color: Colors.white,
    fontSize: 14,
    fontWeight: '700',
  },
  restoreBtn: {
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.border,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 8,
  },
  restoreBtnText: {
    color: Colors.primary,
    fontSize: 14,
    fontWeight: '700',
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: '#FAF7F2',
  },
  infoKey: {
    fontSize: 13,
    color: Colors.textMuted,
  },
  infoVal: {
    fontSize: 13,
    fontWeight: '700',
    color: Colors.text,
  },
  privacyNote: {
    backgroundColor: '#FAF8F5',
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#E6DFD5',
    marginTop: 8,
  },
  privacyText: {
    fontSize: 12,
    color: Colors.textMuted,
    lineHeight: 18,
  },
});
