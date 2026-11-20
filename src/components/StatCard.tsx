import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../constants/Colors';
import { formatCurrency } from '../utils/currency';

interface Props {
  title: string;
  amountPaise: number;
  type: 'mila' | 'diya' | 'neutral';
  countLabel?: string;
}

export const StatCard: React.FC<Props> = ({ title, amountPaise, type, countLabel }) => {
  const isMila = type === 'mila';
  const isDiya = type === 'diya';

  const accentColor = isMila ? Colors.mila : isDiya ? Colors.diya : Colors.primary;
  const bgColor = isMila ? Colors.milaBg : isDiya ? Colors.diyaBg : Colors.surface;

  return (
    <View style={[styles.card, { backgroundColor: bgColor, borderColor: isMila ? '#C3E6CB' : isDiya ? '#F5C6CB' : Colors.border }]}>
      <Text style={[styles.title, { color: accentColor }]}>{title}</Text>
      <Text style={[styles.amount, { color: accentColor }]}>{formatCurrency(amountPaise)}</Text>
      {countLabel ? <Text style={styles.count}>{countLabel}</Text> : null}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    flex: 1,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    marginHorizontal: 4,
  },
  title: {
    fontSize: 13,
    fontWeight: '600',
    marginBottom: 4,
  },
  amount: {
    fontSize: 22,
    fontWeight: '800',
    letterSpacing: -0.5,
  },
  count: {
    fontSize: 11,
    color: Colors.textMuted,
    marginTop: 4,
  },
});
