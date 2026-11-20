import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Platform,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import * as Haptics from 'expo-haptics';

interface RouteInfo {
  key: string;
  name: string;
}

interface TabDescriptor {
  options: {
    title?: string;
    href?: any;
    tabBarLabel?: any;
  };
}

interface CustomTabBarProps {
  state: {
    index: number;
    routes: RouteInfo[];
  };
  descriptors: Record<string, TabDescriptor>;
  navigation: {
    navigate: (name: string, params?: any) => void;
    emit: (event: any) => { defaultPrevented: boolean };
  };
}

const TAB_CONFIG: Record<
  string,
  {
    label: string;
    activeIcon: keyof typeof Ionicons.glyphMap;
    inactiveIcon: keyof typeof Ionicons.glyphMap;
  }
> = {
  index: {
    label: 'होम',
    activeIcon: 'home',
    inactiveIcon: 'home-outline',
  },
  bahi: {
    label: 'बही',
    activeIcon: 'book',
    inactiveIcon: 'book-outline',
  },
  events: {
    label: 'कार्यक्रम',
    activeIcon: 'calendar',
    inactiveIcon: 'calendar-outline',
  },
  people: {
    label: 'लोग',
    activeIcon: 'people',
    inactiveIcon: 'people-outline',
  },
  settings: {
    label: 'सेटिंग',
    activeIcon: 'settings',
    inactiveIcon: 'settings-outline',
  },
};

export function FloatingPillTabBar({ state, descriptors, navigation }: CustomTabBarProps) {
  const insets = useSafeAreaInsets();
  const bottomPosition = Math.max(insets.bottom, 12) + 6;

  // Filter out hidden routes (e.g. 'two')
  const visibleRoutes = state.routes.filter(route => {
    const { options } = descriptors[route.key] || { options: {} };
    if (options.href === null || route.name === 'two') {
      return false;
    }
    return Boolean(TAB_CONFIG[route.name]);
  });

  return (
    <View
      style={[
        styles.floatingContainer,
        {
          bottom: bottomPosition,
        },
      ]}
      pointerEvents="box-none"
    >
      <View style={styles.pillBar}>
        {visibleRoutes.map((route) => {
          const isFocused = state.routes[state.index]?.name === route.name;
          const config = TAB_CONFIG[route.name] || {
            label: route.name,
            activeIcon: 'ellipse',
            inactiveIcon: 'ellipse-outline',
          };

          const onPress = () => {
            try {
              if (Platform.OS !== 'web') {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              }
            } catch {
              // ignore haptic error
            }

            const event = navigation.emit({
              type: 'tabPress',
              target: route.key,
              canPreventDefault: true,
            });

            if (!isFocused && !event.defaultPrevented) {
              navigation.navigate(route.name);
            }
          };

          if (isFocused) {
            // Expanding chip with icon + label inside colored capsule (Demo style)
            return (
              <TouchableOpacity
                key={route.key}
                onPress={onPress}
                activeOpacity={0.88}
                style={styles.activeChip}
                accessibilityRole="button"
                accessibilityState={{ selected: true }}
                accessibilityLabel={config.label}
              >
                <Ionicons
                  name={config.activeIcon}
                  size={19}
                  color="#FFFFFF"
                  style={{ marginRight: 6 }}
                />
                <Text style={styles.activeChipLabel} numberOfLines={1}>
                  {config.label}
                </Text>
              </TouchableOpacity>
            );
          }

          // Inactive compact tab with icon only
          return (
            <TouchableOpacity
              key={route.key}
              onPress={onPress}
              activeOpacity={0.7}
              style={styles.inactiveTab}
              accessibilityRole="button"
              accessibilityState={{ selected: false }}
              accessibilityLabel={config.label}
            >
              <Ionicons
                name={config.inactiveIcon}
                size={22}
                color="#64748B"
              />
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  floatingContainer: {
    position: 'absolute',
    left: 0,
    right: 0,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
    zIndex: 999,
  },
  pillBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderRadius: 36,
    paddingHorizontal: 8,
    paddingVertical: 7,
    maxWidth: 420,
    width: '100%',
    // Premium soft elevation & shadow
    shadowColor: '#0F172A',
    shadowOffset: {
      width: 0,
      height: 6,
    },
    shadowOpacity: 0.14,
    shadowRadius: 18,
    elevation: 10,
    borderWidth: 1,
    borderColor: 'rgba(226, 232, 240, 0.8)',
  },
  activeChip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#C05A2B', // Official Terracotta brand color (matches demo red/terracotta pill)
    paddingHorizontal: 16,
    paddingVertical: 9,
    borderRadius: 24,
    shadowColor: '#C05A2B',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.35,
    shadowRadius: 6,
    elevation: 3,
  },
  activeChipLabel: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
    letterSpacing: 0.2,
  },
  inactiveTab: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
    paddingVertical: 9,
    minWidth: 44,
    borderRadius: 22,
  },
});
