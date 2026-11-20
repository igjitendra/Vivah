import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  Alert,
  Modal,
  TextInput,
  ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { getDatabaseStats } from '../../src/database/db';
import { BackupService } from '../../src/services/BackupService';

export default function SettingsScreen() {
  const [stats, setStats] = useState<{ tableCount: number; entryCount: number; plannedCount: number } | null>(null);
  const [loading, setLoading] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [password, setPassword] = useState('');
  const [showRestoreModal, setShowRestoreModal] = useState(false);
  const [restoreJson, setRestoreJson] = useState('');
  const [restorePassword, setRestorePassword] = useState('');
  const [needsPasswordForRestore, setNeedsPasswordForRestore] = useState(false);

  const refreshStats = () => {
    try {
      setStats(getDatabaseStats());
    } catch (e) {
      console.error('Stats error:', e);
    }
  };

  useEffect(() => {
    refreshStats();
  }, []);

  // Quick plain backup
  const handleQuickBackup = async () => {
    setLoading(true);
    try {
      const { uri, filename, metadata } = await BackupService.createBackup();
      Alert.alert(
        'बैकअप सफल!',
        `फाइल: ${filename}\nकुल ${metadata.entries_count} व्यवहार, ${metadata.people_count} लोग, और ${metadata.events_count} कार्यक्रम सुरक्षित किए गए।`,
        [
          { text: 'फाइल साझा करें', onPress: () => BackupService.shareBackupFile(uri) },
          { text: 'ठीक है' },
        ]
      );
    } catch (e: any) {
      Alert.alert('त्रुटि', `बैकअप नहीं बन सका: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setLoading(false);
    }
  };

  // Encrypted backup creation
  const handleCreateEncryptedBackup = async () => {
    if (!password || password.length < 4) {
      Alert.alert('कमजोर पासवर्ड', 'कृपया कम से कम 4 अक्षरों का पासवर्ड डालें।');
      return;
    }

    setShowPasswordModal(false);
    setLoading(true);
    try {
      const { uri, filename } = await BackupService.createBackup(password);
      setPassword('');
      Alert.alert(
        'सुरक्षित एन्क्रिप्टेड बैकअप तैयार!',
        `फाइल: ${filename}\nयह बैकअप आपके पासवर्ड द्वारा AES-256 से सुरक्षित किया गया है।\n\nसावधानी: बिना पासवर्ड के इस डेटा को कभी रिस्टोर नहीं किया जा सकता। पासवर्ड याद रखें।`,
        [
          { text: 'फाइल सुरक्षित करें / भेजें', onPress: () => BackupService.shareBackupFile(uri) },
          { text: 'ठीक है' },
        ]
      );
    } catch (e: any) {
      Alert.alert('त्रुटि', `एन्क्रिप्टेड बैकअप विफल: ${e?.message || 'अज्ञात त्रुटि'}`);
    } finally {
      setLoading(false);
    }
  };

  // Restore verification & execution
  const handleStartRestore = () => {
    if (!restoreJson.trim()) {
      Alert.alert('डेटा पेस्ट करें', 'कृपया बैकअप JSON सामग्री पेस्ट करें।');
      return;
    }

    const validation = BackupService.validateBackup(restoreJson.trim(), restorePassword);

    if (!validation.valid) {
      if (validation.isEncrypted && (!restorePassword || restorePassword.trim().length === 0)) {
        setNeedsPasswordForRestore(true);
        Alert.alert('पासवर्ड आवश्यक', 'यह बैकअप एन्क्रिप्टेड है। कृपया नीचे बैकअप पासवर्ड दर्ज करें।');
        return;
      }
      Alert.alert('सत्यापन विफल', validation.error || 'बैकअप फाइल अमान्य है।');
      return;
    }

    const meta = validation.metadata!;
    Alert.alert(
      'डेटा रिस्टोर की पुष्टि करें',
      `बैकअप विवरण:\n• लोग: ${meta.people_count}\n• कार्यक्रम: ${meta.events_count}\n• व्यवहार: ${meta.entries_count}\n\nसावधानी: रिस्टोर करने पर फोन का मौजूदा डेटा बदल जाएगा। क्या आप आगे बढ़ना चाहते हैं?`,
      [
        { text: 'रद्द करें', style: 'cancel' },
        {
          text: 'हाँ, रिस्टोर करें',
          style: 'destructive',
          onPress: () => {
            const safetySnapshot = BackupService.createSafetySnapshot();
            const result = BackupService.restoreFromPayload(validation.payload!, safetySnapshot);
            if (result.success) {
              refreshStats();
              setShowRestoreModal(false);
              setRestoreJson('');
              setRestorePassword('');
              setNeedsPasswordForRestore(false);
              Alert.alert(
                'रिस्टोर सफल!',
                `डेटा सफलतापूर्वक लोड हो गया है:\n• ${result.summary?.people} लोग\n• ${result.summary?.events} कार्यक्रम\n• ${result.summary?.entries} व्यवहार\n• ${result.summary?.items} सामान/उपहार`,
                [{ text: 'ठीक है' }]
              );
            } else {
              Alert.alert('त्रुटि', result.error || 'रिस्टोर असफल रहा।');
            }
          },
        },
      ]
    );
  };

  return (
    <SafeAreaView style={styles.safe}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>सेटिंग व बैकअप</Text>
      </View>

      {loading && (
        <View style={styles.loadingBanner}>
          <ActivityIndicator color="#1F3352" size="small" style={{ marginRight: 8 }} />
          <Text style={styles.loadingText}>कार्य प्रगति पर है...</Text>
        </View>
      )}

      <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
        {/* App branding card */}
        <View style={styles.appCard}>
          <Text style={styles.appName}>व्यवहार</Text>
          <Text style={styles.appTagline}>रिश्तों का हिसाब, हमेशा याद।</Text>
          <Text style={styles.appVersion}>संस्करण 1.0.0 • पूर्ण ऑफलाइन MVP</Text>
        </View>

        {/* Database status */}
        {stats && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>स्थानीय डेटाबेस स्थिति</Text>
            <View style={styles.row}>
              <Ionicons name="bar-chart-outline" size={20} color="#1F3352" style={styles.rowIcon} />
              <Text style={styles.rowLabel}>{stats.entryCount} पूर्ण व्यवहार दर्ज हैं</Text>
            </View>
            <View style={styles.row}>
              <Ionicons name="time-outline" size={20} color="#1F3352" style={styles.rowIcon} />
              <Text style={styles.rowLabel}>{stats.plannedCount} नियोजित व्यवहार</Text>
            </View>
            <View style={styles.row}>
              <Ionicons name="server-outline" size={20} color="#1F3352" style={styles.rowIcon} />
              <Text style={styles.rowLabel}>{stats.tableCount} तालिकाएँ (SQLite WAL)</Text>
            </View>
          </View>
        )}

        {/* Reports & PDF Link */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>रिपोर्ट्स व एक्सपोर्ट</Text>
          <TouchableOpacity style={styles.row} onPress={() => router.push('/reports')}>
            <Ionicons name="document-text-outline" size={20} color="#1F3352" style={styles.rowIcon} />
            <View style={{ flex: 1 }}>
              <Text style={styles.rowLabel}>PDF एवं CSV रिपोर्ट्स</Text>
              <Text style={styles.rowSub}>Devanagari प्रिंट रिपोर्ट व Excel स्प्रेडशीट</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>
        </View>

        {/* Local Backup System */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>लोकल बैकअप प्रबंधन (100% ऑफलाइन)</Text>
          
          <TouchableOpacity style={styles.row} onPress={handleQuickBackup} disabled={loading}>
            <Ionicons name="save-outline" size={20} color="#1F3352" style={styles.rowIcon} />
            <View style={{ flex: 1 }}>
              <Text style={styles.rowLabel}>त्वरित बैकअप (Quick Backup)</Text>
              <Text style={styles.rowSub}>संपूर्ण डेटा की प्रामाणिक JSON बैकअप फाइल बनाएं</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.row}
            onPress={() => {
              setShowPasswordModal(true);
            }}
            disabled={loading}
          >
            <Ionicons name="lock-closed-outline" size={20} color="#1F3352" style={styles.rowIcon} />
            <View style={{ flex: 1 }}>
              <Text style={styles.rowLabel}>पासवर्ड-सुरक्षित बैकअप (AES-256)</Text>
              <Text style={styles.rowSub}>गुप्त पासवर्ड द्वारा सुरक्षित एन्क्रिप्टेड फाइल बनाएं</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.row} onPress={() => setShowRestoreModal(true)} disabled={loading}>
            <Ionicons name="cloud-download-outline" size={20} color="#C05A2B" style={styles.rowIcon} />
            <View style={{ flex: 1 }}>
              <Text style={[styles.rowLabel, { color: '#C05A2B' }]}>डेटा रिस्टोर करें (Restore Data)</Text>
              <Text style={styles.rowSub}>पूर्ववर्ती बैकअप फाइल से डेटा पुनर्स्थापित करें</Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color="#C05A2B" />
          </TouchableOpacity>
        </View>

        {/* Privacy & Offline Guarantee */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>गोपनीयता व सुरक्षा</Text>
          <View style={styles.row}>
            <Ionicons name="shield-checkmark-outline" size={20} color="#16A34A" style={styles.rowIcon} />
            <Text style={styles.rowLabel}>100% ऑफलाइन — कोई डेटा सर्वर पर नहीं जाता</Text>
          </View>
          <View style={styles.row}>
            <Ionicons name="key-outline" size={20} color="#1F3352" style={styles.rowIcon} />
            <Text style={styles.rowLabel}>पैरामीटराइज़्ड क्वेरीज द्वारा SQL इंजेक्शन से सुरक्षित</Text>
          </View>
          <View style={styles.row}>
            <Ionicons name="cloud-offline-outline" size={20} color="#6B7280" style={styles.rowIcon} />
            <Text style={styles.rowLabel}>कोई इंटरनेट अनुमति आवश्यक नहीं</Text>
          </View>
        </View>
      </ScrollView>

      {/* Password Modal for Encrypted Backup */}
      <Modal visible={showPasswordModal} transparent animationType="slide" onRequestClose={() => setShowPasswordModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>बैकअप पासवर्ड सेट करें</Text>
            <Text style={styles.modalDesc}>
              इस बैकअप को खोलने के लिए इस पासवर्ड की आवश्यकता होगी। इसे कहीं सुरक्षित याद रखें।
            </Text>
            <TextInput
              style={styles.modalInput}
              placeholder="गुप्त पासवर्ड डालें (कम से कम 4 अक्षर)"
              placeholderTextColor="#9CA3AF"
              secureTextEntry
              value={password}
              onChangeText={setPassword}
            />
            <View style={styles.modalActions}>
              <TouchableOpacity style={styles.cancelBtn} onPress={() => setShowPasswordModal(false)}>
                <Text style={styles.cancelText}>रद्द करें</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.confirmBtn} onPress={handleCreateEncryptedBackup}>
                <Text style={styles.confirmText}>सुरक्षित बैकअप बनाएं</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Restore Modal */}
      <Modal visible={showRestoreModal} transparent animationType="slide" onRequestClose={() => setShowRestoreModal(false)}>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '85%' }]}>
            <Text style={styles.modalTitle}>डेटा रिस्टोर करें</Text>
            <Text style={styles.modalDesc}>
              अपनी पूर्ववर्ती बैकअप फाइल की सामग्री को नीचे पेस्ट करें:
            </Text>
            <TextInput
              style={[styles.modalInput, { height: 120, textAlignVertical: 'top' }]}
              placeholder='{"vyavahaar_backup_version": ...}'
              placeholderTextColor="#9CA3AF"
              multiline
              value={restoreJson}
              onChangeText={text => {
                setRestoreJson(text);
                try {
                  const p = JSON.parse(text);
                  setNeedsPasswordForRestore(Boolean(p.is_encrypted));
                } catch {
                  // ignore
                }
              }}
            />

            {needsPasswordForRestore && (
              <View style={{ marginTop: 10 }}>
                <Text style={styles.inputLabel}>इस बैकअप का पासवर्ड डालें *</Text>
                <TextInput
                  style={styles.modalInput}
                  placeholder="पासवर्ड"
                  placeholderTextColor="#9CA3AF"
                  secureTextEntry
                  value={restorePassword}
                  onChangeText={setRestorePassword}
                />
              </View>
            )}

            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => {
                  setShowRestoreModal(false);
                  setRestoreJson('');
                  setRestorePassword('');
                  setNeedsPasswordForRestore(false);
                }}
              >
                <Text style={styles.cancelText}>रद्द करें</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.confirmBtn, { backgroundColor: '#C05A2B' }]} onPress={handleStartRestore}>
                <Text style={styles.confirmText}>रिस्टोर जांचें</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  header: { backgroundColor: '#1F3352', paddingTop: 48, paddingBottom: 16, paddingHorizontal: 20 },
  headerTitle: { fontSize: 22, fontWeight: '800', color: '#F4EFE7' },
  loadingBanner: { backgroundColor: '#FEF3C7', padding: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  loadingText: { color: '#92400E', fontSize: 13, fontWeight: '600' },
  scroll: { flex: 1 },
  content: { padding: 16, paddingBottom: 48 },
  appCard: { backgroundColor: '#1F3352', borderRadius: 16, padding: 24, alignItems: 'center', marginBottom: 20 },
  appName: { fontSize: 28, fontWeight: '800', color: '#F4EFE7', letterSpacing: 1 },
  appTagline: { fontSize: 13, color: '#A8B8CF', marginTop: 4 },
  appVersion: { fontSize: 11, color: '#A8B8CF', marginTop: 8 },
  section: { backgroundColor: '#FFFFFF', borderRadius: 12, padding: 4, marginBottom: 16, elevation: 1 },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#6B7280',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 4,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  row: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 14, borderTopWidth: 1, borderTopColor: '#F3F4F6' },
  rowIcon: { marginRight: 12 },
  rowLabel: { fontSize: 14, color: '#1F2937', fontWeight: '600' },
  rowSub: { fontSize: 11, color: '#6B7280', marginTop: 2 },
  modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', alignItems: 'center', justifyContent: 'center', padding: 20 },
  modalContent: { backgroundColor: '#FFFFFF', borderRadius: 16, padding: 20, width: '100%', maxWidth: 400 },
  modalTitle: { fontSize: 18, fontWeight: '800', color: '#1F3352', marginBottom: 8 },
  modalDesc: { fontSize: 13, color: '#6B7280', marginBottom: 14, lineHeight: 18 },
  modalInput: { borderWidth: 1, borderColor: '#D1D5DB', borderRadius: 8, paddingHorizontal: 12, paddingVertical: 10, fontSize: 14, color: '#1F2937', marginTop: 6 },
  inputLabel: { fontSize: 12, fontWeight: '700', color: '#1F3352' },
  modalActions: { flexDirection: 'row', justifyContent: 'flex-end', marginTop: 18, gap: 10 },
  cancelBtn: { paddingVertical: 10, paddingHorizontal: 14 },
  cancelText: { color: '#6B7280', fontWeight: '600', fontSize: 14 },
  confirmBtn: { backgroundColor: '#1F3352', borderRadius: 8, paddingVertical: 10, paddingHorizontal: 16 },
  confirmText: { color: '#FFFFFF', fontWeight: '700', fontSize: 14 },
});
