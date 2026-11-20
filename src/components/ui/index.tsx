import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  StyleSheet,
  Modal,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';

const Colors = {
  navy: '#1F3352',
  terracotta: '#C05A2B',
  cream: '#F4EFE7',
  white: '#FFFFFF',
  gray: '#6B7280',
  lightGray: '#E5E7EB',
  red: '#DC2626',
  green: '#16A34A',
};

// ── VCard ──────────────────────────────────────────────────────────────────
interface VCardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  onPress?: () => void;
}
export function VCard({ children, style, onPress }: VCardProps) {
  if (onPress) {
    return (
      <TouchableOpacity style={[styles.card, style]} onPress={onPress} activeOpacity={0.85}>
        {children}
      </TouchableOpacity>
    );
  }
  return <View style={[styles.card, style]}>{children}</View>;
}

// ── DirectionBadge ─────────────────────────────────────────────────────────
interface DirectionBadgeProps {
  direction: 'mila' | 'diya';
  size?: 'sm' | 'md';
}
export function DirectionBadge({ direction, size = 'md' }: DirectionBadgeProps) {
  const isMila = direction === 'mila';
  return (
    <View style={[
      styles.badge,
      { backgroundColor: isMila ? '#D1FAE5' : '#FEE2E2' },
      size === 'sm' && { paddingHorizontal: 6, paddingVertical: 2 }
    ]}>
      <Text style={[
        styles.badgeText,
        { color: isMila ? Colors.green : Colors.red },
        size === 'sm' && { fontSize: 11 }
      ]}>
        {isMila ? '↓ मिला' : '↑ दिया'}
      </Text>
    </View>
  );
}

// ── StatCard ───────────────────────────────────────────────────────────────
interface StatCardProps {
  label: string;
  value: string;
  color?: string;
  style?: ViewStyle;
}
export function StatCard({ label, value, color, style }: StatCardProps) {
  return (
    <View style={[styles.statCard, style]}>
      <Text style={[styles.statValue, color ? { color } : {}]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

// ── VButton ────────────────────────────────────────────────────────────────
interface VButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
}
export function VButton({ title, onPress, variant = 'primary', disabled, loading, style }: VButtonProps) {
  const bg = variant === 'primary' ? Colors.navy
    : variant === 'secondary' ? Colors.terracotta
    : variant === 'danger' ? Colors.red
    : 'transparent';
  const textColor = variant === 'ghost' ? Colors.navy : Colors.white;
  const borderStyle = variant === 'ghost' ? { borderWidth: 1, borderColor: Colors.navy } : {};

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled || loading}
      style={[styles.button, { backgroundColor: bg }, borderStyle, (disabled || loading) && { opacity: 0.6 }, style]}
      activeOpacity={0.85}
    >
      {loading
        ? <ActivityIndicator color={textColor} size="small" />
        : <Text style={[styles.buttonText, { color: textColor }]}>{title}</Text>
      }
    </TouchableOpacity>
  );
}

// ── VInput ─────────────────────────────────────────────────────────────────
interface VInputProps {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  error?: string;
  multiline?: boolean;
  keyboardType?: 'default' | 'numeric' | 'phone-pad';
  style?: ViewStyle;
  required?: boolean;
}
export function VInput({ label, value, onChangeText, placeholder, error, multiline, keyboardType, style, required }: VInputProps) {
  return (
    <View style={[styles.inputWrapper, style]}>
      <Text style={styles.inputLabel}>{label}{required ? ' *' : ''}</Text>
      <TextInput
        style={[styles.input, error ? { borderColor: Colors.red } : {}, multiline && { height: 80, textAlignVertical: 'top' }]}
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={Colors.gray}
        multiline={multiline}
        keyboardType={keyboardType ?? 'default'}
      />
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
    </View>
  );
}

// ── AmountInput ────────────────────────────────────────────────────────────
interface AmountInputProps {
  label: string;
  amountPaise: number;
  onChangePaise: (paise: number) => void;
  error?: string;
}
export function AmountInput({ label, amountPaise, onChangePaise, error }: AmountInputProps) {
  const rupeeStr = amountPaise > 0 ? String(Math.floor(amountPaise / 100)) : '';
  return (
    <View style={styles.inputWrapper}>
      <Text style={styles.inputLabel}>{label}</Text>
      <View style={styles.amountRow}>
        <Text style={styles.rupeeSymbol}>₹</Text>
        <TextInput
          style={[styles.amountInput, error ? { borderColor: Colors.red } : {}]}
          value={rupeeStr}
          onChangeText={(txt) => {
            const num = parseInt(txt.replace(/[^0-9]/g, ''), 10);
            onChangePaise(isNaN(num) ? 0 : num * 100);
          }}
          placeholder="0"
          placeholderTextColor={Colors.gray}
          keyboardType="numeric"
        />
      </View>
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
    </View>
  );
}

// ── EmptyState ─────────────────────────────────────────────────────────────
interface EmptyStateProps {
  iconName?: keyof typeof Ionicons.glyphMap;
  title: string;
  subtitle?: string;
  action?: { label: string; onPress: () => void };
}
export function EmptyState({ iconName, title, subtitle, action }: EmptyStateProps) {
  return (
    <View style={styles.emptyState}>
      {iconName ? <Ionicons name={iconName} size={48} color={Colors.terracotta} style={{ marginBottom: 12 }} /> : null}
      <Text style={styles.emptyTitle}>{title}</Text>
      {subtitle ? <Text style={styles.emptySubtitle}>{subtitle}</Text> : null}
      {action ? (
        <VButton title={action.label} onPress={action.onPress} variant="secondary" style={{ marginTop: 16 }} />
      ) : null}
    </View>
  );
}

// ── LoadingView ────────────────────────────────────────────────────
export function LoadingView({ message }: { message?: string }) {
  return (
    <View style={styles.loading}>
      <ActivityIndicator size="large" color={Colors.navy} />
      {message ? <Text style={styles.loadingText}>{message}</Text> : null}
    </View>
  );
}

// ── ConfirmDialog ──────────────────────────────────────────────────────────
interface ConfirmDialogProps {
  visible: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm: () => void;
  onCancel: () => void;
  dangerous?: boolean;
}
export function ConfirmDialog({ visible, title, message, confirmLabel = 'हाँ', cancelLabel = 'नहीं', onConfirm, onCancel, dangerous }: ConfirmDialogProps) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <View style={styles.overlay}>
        <View style={styles.dialog}>
          <Text style={styles.dialogTitle}>{title}</Text>
          <Text style={styles.dialogMessage}>{message}</Text>
          <View style={styles.dialogButtons}>
            <VButton title={cancelLabel} onPress={onCancel} variant="ghost" style={{ flex: 1, marginRight: 8 }} />
            <VButton title={confirmLabel} onPress={onConfirm} variant={dangerous ? 'danger' : 'primary'} style={{ flex: 1 }} />
          </View>
        </View>
      </View>
    </Modal>
  );
}

// ── SyncStatusBar ──────────────────────────────────────────────────────────
export function SyncStatusBar() {
  return (
    <View style={styles.syncBar}>
      <Ionicons name="shield-checkmark-outline" size={14} color={Colors.gray} style={{ marginRight: 6 }} />
      <Text style={styles.syncText}>ऑफलाइन — डेटा सुरक्षित है</Text>
    </View>
  );
}

// ─── Styles ────────────────────────────────────────────────────────────────
const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.white,
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  badge: {
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  badgeText: { fontSize: 13, fontWeight: '600' },
  statCard: {
    backgroundColor: Colors.white,
    borderRadius: 10,
    padding: 14,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.06,
    shadowRadius: 3,
    elevation: 1,
  },
  statValue: { fontSize: 20, fontWeight: '700', color: Colors.navy },
  statLabel: { fontSize: 12, color: Colors.gray, marginTop: 4, textAlign: 'center' },
  button: {
    borderRadius: 10,
    paddingVertical: 14,
    paddingHorizontal: 20,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  buttonText: { fontSize: 16, fontWeight: '600' },
  inputWrapper: { marginBottom: 16 },
  inputLabel: { fontSize: 14, fontWeight: '600', color: Colors.navy, marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: Colors.lightGray,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    color: '#1F2937',
    backgroundColor: Colors.white,
    minHeight: 48,
  },
  errorText: { fontSize: 12, color: Colors.red, marginTop: 4 },
  amountRow: { flexDirection: 'row', alignItems: 'center' },
  rupeeSymbol: { fontSize: 20, fontWeight: '600', color: Colors.navy, marginRight: 8 },
  amountInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: Colors.lightGray,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 20,
    fontWeight: '600',
    color: Colors.navy,
    backgroundColor: Colors.white,
    minHeight: 48,
  },
  emptyState: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  emptyTitle: { fontSize: 18, fontWeight: '600', color: Colors.navy, textAlign: 'center' },
  emptySubtitle: { fontSize: 14, color: Colors.gray, textAlign: 'center', marginTop: 8 },
  loading: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  loadingText: { marginTop: 12, fontSize: 14, color: Colors.gray },
  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', alignItems: 'center', justifyContent: 'center' },
  dialog: {
    backgroundColor: Colors.white,
    borderRadius: 16,
    padding: 24,
    width: '85%',
    maxWidth: 360,
  },
  dialogTitle: { fontSize: 18, fontWeight: '700', color: Colors.navy, marginBottom: 10 },
  dialogMessage: { fontSize: 15, color: '#374151', marginBottom: 20 },
  dialogButtons: { flexDirection: 'row' },
  syncBar: { backgroundColor: '#F3F4F6', paddingVertical: 6, paddingHorizontal: 16, flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  syncText: { fontSize: 12, color: Colors.gray },
});
