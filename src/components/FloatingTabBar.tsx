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
import { useRouter } from 'expo-router';
import * as Haptics from 'expo-haptics';

interface RouteInfo {
  key: string;
  name: string;
}

interface TabDescriptor {
  options?: {
    title?: string;
    href?: any;
    tabBarLabel?: any;
    tabBarStyle?: any;
  };
  navigation?: {
    navigate?: (name: string, params?: any) => void;
  };
}

interface CustomTabBarProps {
  state?: {
    index: number;
    routes: RouteInfo[];
  };
  descriptors?: Record<string, TabDescriptor>;
  emitter?: {
    emit?: (event: any) => { defaultPrevented?: boolean };
  };
  navigateToTab?: (routeKey: string) => void;
  navigation?: {
    navigate?: (name: string, params?: any) => void;
    emit?: (event: any) => { defaultPrevented?: boolean };
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

export function FloatingPillTabBar(props: CustomTabBarProps) {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const bottomPosition = Math.max(insets?.bottom ?? 0, 12) + 6;

  const state = props?.state;
  const descriptors = props?.descriptors ?? {};
  const emitter = props?.emitter;
  const navigateToTab = props?.navigateToTab;
  const navigation = props?.navigation;

  const routes = state?.routes ?? [];
  const currentIndex = state?.index ?? 0;
  const currentFocusedRoute = routes[currentIndex];

  // Filter out hidden routes (e.g. 'two')
  const visibleRoutes = routes.filter((route) => {
    const options = descriptors[route.key]?.options;
    if (options?.href === null || route.name === 'two') {
      return false;
    }
    return Boolean(TAB_CONFIG[route.name]);
  });

  return (
    <View
      style={[
        styles.floatingContainer,
        {
          paddingBottom: bottomPosition,
        },
      ]}
      pointerEvents="box-none"
    >
      <View style={styles.pillBar} pointerEvents="auto">
        {visibleRoutes.map((route) => {
          const isFocused = currentFocusedRoute?.key === route.key;
          const config = TAB_CONFIG[route.name] || {
            label: route.name,
            activeIcon: 'ellipse',
            inactiveIcon: 'ellipse-outline',
          };

          const handlePress = () => {
            try {
              // Haptic vibration feedback on tap
              if (Platform.OS !== 'web') {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
              }
            } catch {
              // Ignore haptic errors
            }

            try {
              // 1. Emit tabPress event
              let defaultPrevented = false;
              if (emitter?.emit) {
                const event = emitter.emit({
                  type: 'tabPress',
                  target: route.key,
                  canPreventDefault: true,
                });
                defaultPrevented = Boolean(event?.defaultPrevented);
              } else if (navigation?.emit) {
                const event = navigation.emit({
                  type: 'tabPress',
                  target: route.key,
                  canPreventDefault: true,
                });
                defaultPrevented = Boolean(event?.defaultPrevented);
              }

              // 2. Perform navigation if not already focused and not cancelled
              if (!isFocused && !defaultPrevented) {
                let navigated = false;

                // Official React Navigation Bottom Tabs method
                if (typeof navigateToTab === 'function') {
                  try {
                    navigateToTab(route.key);
                    navigated = true;
                  } catch {
                    navigated = false;
                  }
                }

                // Route descriptor navigation
                if (!navigated && descriptors[route.key]?.navigation?.navigate) {
                  try {
                    descriptors[route.key]?.navigation?.navigate?.(route.name);
                    navigated = true;
                  } catch {
                    navigated = false;
                  }
                }

                // Standard navigation prop
                if (!navigated && navigation?.navigate) {
                  try {
                    navigation.navigate(route.name);
                    navigated = true;
                  } catch {
                    navigated = false;
                  }
                }

                // Direct Expo Router imperative navigation
                if (!navigated) {
                  try {
                    const targetPath = route.name === 'index' ? '/(tabs)' : `/(tabs)/${route.name}`;
                    router.navigate(targetPath as any);
                  } catch {
                    const targetPath = route.name === 'index' ? '/(tabs)' : `/(tabs)/${route.name}`;
                    router.push(targetPath as any);
                  }
                }
              }
            } catch (err) {
              console.warn('Navigation error:', err);
              // Fallback to router.navigate
              try {
                const targetPath = route.name === 'index' ? '/(tabs)' : `/(tabs)/${route.name}`;
                router.navigate(targetPath as any);
              } catch {
                // Ignore
              }
            }
          };

          if (isFocused) {
            // Expanding chip with icon + label inside colored capsule (Demo style)
            return (
              <TouchableOpacity
                key={route.key}
                onPress={handlePress}
                activeOpacity={0.88}
                style={styles.activeChip}
                hitSlop={{ top: 12, bottom: 12, left: 10, right: 10 }}
                accessibilityRole="tab"
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
              onPress={handlePress}
              activeOpacity={0.7}
              style={styles.inactiveTab}
              hitSlop={{ top: 12, bottom: 12, left: 10, right: 10 }}
              accessibilityRole="tab"
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
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
    zIndex: 9999,
    elevation: 9999,
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
