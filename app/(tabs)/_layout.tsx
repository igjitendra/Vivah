import React from 'react';
import { Tabs } from 'expo-router';
import { FloatingPillTabBar } from '../../src/components/FloatingTabBar';
import { Strings } from '../../src/constants/Strings';

export default function TabLayout() {
  return (
    <Tabs
      tabBar={(props) => <FloatingPillTabBar {...(props as any)} />}
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          elevation: 0,
          backgroundColor: 'transparent',
          borderTopWidth: 0,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: Strings.tabs.home,
        }}
      />
      <Tabs.Screen
        name="bahi"
        options={{
          title: Strings.tabs.bahi,
        }}
      />
      <Tabs.Screen
        name="events"
        options={{
          title: Strings.tabs.events,
        }}
      />
      <Tabs.Screen
        name="people"
        options={{
          title: Strings.tabs.people,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: Strings.tabs.settings,
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
