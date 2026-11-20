import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../constants/Colors';
import { Direction } from '../types';

interface Props {
  direction: Direction;
  size?: 'small' | 'medium' | 'large';
}

export const DirectionBadge: React.FC<Props> = ({ direction, size = 'medium' }) => {
  const isMila = direction === 'mila';

  return (
    <View
      style={[
        styles.badge,
        {
          backgroundColor: isMila ? Colors.milaBg : Colors.diyaBg,
          borderColor: isMila ? '#A3D9C9' : '#F5C6CB',
          paddingVertical: size === 'small' ? 3 : size === 'large' ? 8 : 5,
          paddingHorizontal: size === 'small' ? 8 : size === 'large' ? 14 : 10,
        },
      ]}
    >
      <Text
        style={[
          styles.text,
          {
            color: isMila ? Colors.mila : Colors.diya,
            fontSize: size === 'small' ? 12 : size === 'large' ? 16 : 13,
            fontWeight: '700',
          },
        ]}
      >
        {isMila ? '↓ व्यवहार मिला' : '↑ व्यवहार दिया'}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  badge: {
    borderRadius: 8,
    borderWidth: 1,
    alignSelf: 'flex-start',
  },
  text: {
    fontWeight: '700',
  },
});
