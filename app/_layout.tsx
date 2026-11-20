import { useFonts } from 'expo-font';
import { DarkTheme, DefaultTheme, Stack, ThemeProvider } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import 'react-native-reanimated';

import { useColorScheme } from '@/components/useColorScheme';
import { initDatabase, ensureDefaultHousehold } from '../src/database/db';

export {
  ErrorBoundary,
} from 'expo-router';

export const unstable_settings = {
  anchor: '(tabs)',
};

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [loaded, error] = useFonts({
    SpaceMono: require('../assets/fonts/SpaceMono-Regular.ttf'),
  });

  useEffect(() => {
    try {
      initDatabase();
      ensureDefaultHousehold();
    } catch (e) {
      console.error('Database initialization error:', e);
    }
  }, []);

  useEffect(() => {
    if (error) throw error;
  }, [error]);

  useEffect(() => {
    if (loaded) {
      SplashScreen.hideAsync();
    }
  }, [loaded]);

  if (!loaded) {
    return null;
  }

  return <RootLayoutNav />;
}

function RootLayoutNav() {
  const colorScheme = useColorScheme();

  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="entry/new"
          options={{
            headerShown: true,
            title: 'नया व्यवहार',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen
          name="entry/[id]"
          options={{
            headerShown: true,
            title: 'व्यवहार विवरण',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen
          name="event/new"
          options={{
            headerShown: true,
            title: 'नया कार्यक्रम',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen
          name="event/[id]"
          options={{
            headerShown: true,
            title: 'कार्यक्रम विवरण',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen
          name="person/new"
          options={{
            headerShown: true,
            title: 'नया व्यक्ति',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen
          name="person/[id]"
          options={{
            headerShown: true,
            title: 'व्यक्ति प्रोफाइल',
            headerStyle: { backgroundColor: '#1F3352' },
            headerTintColor: '#F4EFE7',
          }}
        />
        <Stack.Screen name="gifts/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="reminders/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="reports/index" options={{ presentation: 'card' }} />
        <Stack.Screen name="modal" options={{ presentation: 'modal' }} />
      </Stack>
      <StatusBar style="light" />
    </ThemeProvider>
  );
}
