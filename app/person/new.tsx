import React, { useState } from 'react';
import { ScrollView, StyleSheet, Alert, SafeAreaView } from 'react-native';
import { router } from 'expo-router';
import { PeopleService } from '../../src/services/PeopleService';
import { VInput, VButton } from '../../src/components/ui';

export default function NewPersonScreen() {
  const [name, setName] = useState('');
  const [village, setVillage] = useState('');
  const [relationship, setRelationship] = useState('');
  const [phone, setPhone] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSave = () => {
    if (!name.trim()) { Alert.alert('नाम आवश्यक', 'व्यक्ति का नाम डालें।'); return; }
    setLoading(true);
    try {
      PeopleService.create({
        name: name.trim(),
        village: village.trim() || undefined,
        relationship: relationship.trim() || undefined,
        phone: phone.trim() || undefined,
        notes: notes.trim() || undefined,
      });
      Alert.alert('सफल!', 'व्यक्ति जोड़ा गया।', [{ text: 'ठीक है', onPress: () => router.back() }]);
    } catch (e) {
      Alert.alert('त्रुटि', 'व्यक्ति नहीं जुड़ा।');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <VInput label="नाम" value={name} onChangeText={setName} placeholder="जैसे: रमेश कुमार" required />
        <VInput label="गाँव / शहर (वैकल्पिक)" value={village} onChangeText={setVillage} placeholder="जैसे: रामपुर" />
        <VInput label="रिश्ता (वैकल्पिक)" value={relationship} onChangeText={setRelationship} placeholder="जैसे: मामा, चाचा, दोस्त" />
        <VInput label="मोबाइल नंबर (वैकल्पिक)" value={phone} onChangeText={setPhone} placeholder="10 अंक" keyboardType="phone-pad" />
        <VInput label="नोट (वैकल्पिक)" value={notes} onChangeText={setNotes} placeholder="कोई विशेष बात..." multiline />
        <VButton title="व्यक्ति जोड़ें" onPress={handleSave} loading={loading} style={{ marginTop: 8 }} />
        <VButton title="रद्द करें" onPress={() => router.back()} variant="ghost" style={{ marginTop: 8 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#F4EFE7' },
  scroll: { flex: 1 },
  content: { padding: 20, paddingBottom: 40 },
});
