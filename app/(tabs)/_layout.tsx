import React from 'react';
import { Tabs } from 'expo-router';
import { Text } from 'react-native';
import { Colors } from '../../src/constants/Colors';
import { Strings } from '../../src/constants/Strings';

function TabIcon({ label }: { label: string }) {
  return <Text style={{ fontSize: 18 }}>{label}</Text>;
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: Colors.accent,
        tabBarInactiveTintColor: Colors.textMuted,
        tabBarStyle: {
          backgroundColor: Colors.surface,
          borderTopColor: '#E6DFD5',
          height: 62,
          paddingBottom: 8,
          paddingTop: 6,
        },
        tabBarLabelStyle: {
          fontSize: 12,
          fontWeight: '700',
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: Strings.tabs.home,
          tabBarIcon: () => <TabIcon label="🏠" />,
        }}
      />
      <Tabs.Screen
        name="bahi"
        options={{
          title: Strings.tabs.bahi,
          tabBarIcon: () => <TabIcon label="📜" />,
        }}
      />
      <Tabs.Screen
        name="events"
        options={{
          title: Strings.tabs.events,
          tabBarIcon: () => <TabIcon label="🎉" />,
        }}
      />
      <Tabs.Screen
        name="people"
        options={{
          title: Strings.tabs.people,
          tabBarIcon: () => <TabIcon label="👥" />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: Strings.tabs.settings,
          tabBarIcon: () => <TabIcon label="⚙️" />,
        }}
      />
      {/* Hide default template tab 'two' if present */}
      <Tabs.Screen
        name="two"
        options={{
          href: null,
        }}
      />
    </Tabs>
  );
}
