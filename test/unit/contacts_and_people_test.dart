import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/features/people/services/contacts_service.dart';

void main() {
  group('Advanced People & Contact Import - Unit Tests', () {
    final now = DateTime.now();

    test('1. Person Entity Helpers, Initials, and Address Formatting', () {
      final person = Person(
        id: 'p-test-1',
        fullName: 'रमेश कुमार शर्मा',
        nickname: 'बबुआ',
        phoneNumber: '9876543210',
        secondaryPhones: const ['9123456789', '9876500000'],
        emails: const ['ramesh@example.com'],
        village: 'रामपुर',
        city: 'जयपुर',
        district: 'जयपुर',
        state: 'राजस्थान',
        pinCode: '302001',
        occupation: 'शिक्षक',
        company: 'राजकीय विद्यालय',
        tags: const ['रिश्तेदार', 'VIP'],
        contactSource: 'phone_import',
        createdAt: now,
        updatedAt: now,
      );

      // Display Name includes nickname
      expect(person.displayName, equals('रमेश कुमार शर्मा (बबुआ)'));

      // Initials extracts first characters of first 2 words
      expect(person.initials, equals('रकु'));

      // All phones combines primary + secondary
      expect(person.allPhoneNumbers, equals(['9876543210', '9123456789', '9876500000']));

      // Full address formatting
      expect(person.fullAddress, contains('रामपुर'));
      expect(person.fullAddress, contains('जयपुर'));
      expect(person.fullAddress, contains('302001'));

      // Source checks
      expect(person.isPhoneImported, isTrue);
      expect(person.isArchived, isFalse);
    });

    test('2. Person copyWith Immutability', () {
      final original = Person(
        id: 'p-test-2',
        fullName: 'अमित वर्मा',
        phoneNumber: '9800000000',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        nickname: 'मोनू',
        secondaryPhones: ['9911223344'],
        village: 'वाराणसी',
      );

      expect(original.nickname, isNull);
      expect(original.secondaryPhones, isEmpty);
      expect(original.village, isNull);

      expect(updated.id, equals(original.id));
      expect(updated.fullName, equals('अमित वर्मा'));
      expect(updated.nickname, equals('मोनू'));
      expect(updated.secondaryPhones, equals(['9911223344']));
      expect(updated.village, equals('वाराणसी'));
    });

    test('3. ContactDraft Parsing & Getters', () {
      const draft = ContactDraft(
        id: 'c-draft-1',
        name: 'सुनील कुमार',
        phones: ['9888877777', '9111122222', '9333344444'],
        emails: ['sunil@example.com'],
        city: 'लखनऊ',
        source: 'phone_contacts',
      );

      expect(draft.primaryPhone, equals('9888877777'));
      expect(draft.secondaryPhones, equals(['9111122222', '9333344444']));
    });

    test('4. vCard 3.0 Format Generation', () {
      final person = Person(
        id: 'p-vcard-1',
        fullName: 'विशाल सिंह',
        nickname: 'विक्की',
        phoneNumber: '9876543210',
        secondaryPhones: const ['9123456789'],
        emails: const ['vishal@test.com'],
        address: 'सिविल लाइन्स',
        city: 'प्रयागराज',
        state: 'उत्तर प्रदेश',
        pinCode: '211001',
        occupation: 'इंजीनियर',
        company: 'टेक कॉर्प',
        notes: 'पारिवारिक मित्र',
        createdAt: now,
        updatedAt: now,
      );

      final vCardStr = ContactsService.generatePersonVCard(person);

      expect(vCardStr, contains('BEGIN:VCARD'));
      expect(vCardStr, contains('VERSION:3.0'));
      expect(vCardStr, contains('FN:विशाल सिंह'));
      expect(vCardStr, contains('NICKNAME:विक्की'));
      expect(vCardStr, contains('TEL;TYPE=CELL,PREF:9876543210'));
      expect(vCardStr, contains('TEL;TYPE=VOICE:9123456789'));
      expect(vCardStr, contains('EMAIL;TYPE=INTERNET:vishal@test.com'));
      expect(vCardStr, contains('TITLE:इंजीनियर'));
      expect(vCardStr, contains('ORG:टेक कॉर्प'));
      expect(vCardStr, contains('NOTE:पारिवारिक मित्र'));
      expect(vCardStr, contains('END:VCARD'));
    });

    test('5. vCard Parser Engine', () {
      const sampleVCard = '''
BEGIN:VCARD
VERSION:3.0
FN:रोहन मेहरा
TEL;TYPE=CELL:9898989898
TEL;TYPE=HOME:9191919191
EMAIL:rohan@mehra.com
ORG:मेहरा एसोसिएट्स
TITLE:वकील
NOTE:हाई कोर्ट अधिवक्ता
END:VCARD
''';

      final parsed = ContactsService.parseVCardString(sampleVCard);

      expect(parsed.length, equals(1));
      final contact = parsed.first;
      expect(contact.name, equals('रोहन मेहरा'));
      expect(contact.phones, contains('9898989898'));
      expect(contact.phones, contains('9191919191'));
      expect(contact.emails, contains('rohan@mehra.com'));
      expect(contact.company, equals('मेहरा एसोसिएट्स'));
      expect(contact.jobTitle, equals('वकील'));
      expect(contact.notes, equals('हाई कोर्ट अधिवक्ता'));
    });
  });
}
