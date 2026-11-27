import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/localization/app_localizations.dart';
import 'package:vyavahaar/src/core/services/event_qr_service.dart';
import 'package:vyavahaar/src/core/services/profile_qr_service.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';

void main() {
  group('ProfileQrService & Unified QR Decoding Tests', () {
    test('encodes and decodes Relative (Person) QR payload faithfully', () {
      final now = DateTime(2026, 11, 27);
      final person = Person(
        id: 'p-share-1',
        fullName: 'राजेश शर्मा',
        relationshipLabel: 'मामा जी',
        phoneNumber: '+91 9876543210',
        secondaryPhones: const ['9123456789'],
        whatsappNumber: '9876543210',
        emails: const ['rajesh@example.com'],
        village: 'रामपुर',
        city: 'जयपुर',
        state: 'राजस्थान',
        occupation: 'व्यापार',
        tags: const ['VIP', 'रिश्तेदार'],
        createdAt: now,
        updatedAt: now,
      );

      final qr = ProfileQrService.encodePerson(person);
      final decoded = ProfileQrService.tryDecodePerson(qr);

      expect(decoded, isNotNull);
      expect(decoded!.fullName, 'राजेश शर्मा');
      expect(decoded.relationshipLabel, 'मामा जी');
      expect(decoded.phoneNumber, '+91 9876543210');
      expect(decoded.secondaryPhones, ['9123456789']);
      expect(decoded.emails, ['rajesh@example.com']);
      expect(decoded.city, 'जयपुर');
      expect(decoded.occupation, 'व्यापार');

      final anyResult = ProfileQrService.decodeAny(qr);
      expect(anyResult, isA<VyavahaarDecodedPerson>());

      final imported = decoded.toNewPerson(overrideRelationship: 'मामा जी (जयपुर)');
      expect(imported.id, isNot('p-share-1'));
      expect(imported.relationshipLabel, 'मामा जी (जयपुर)');
      expect(imported.contactSource, 'qr_import');
    });

    test('encodes and decodes FamilyProfile QR and creates directory family + relatives', () {
      const profile = FamilyProfile(
        familyName: 'शर्मा परिवार',
        headOfFamily: 'श्री रमेश चंद्र शर्मा',
        gotra: 'कौशिक',
        kuldevi: 'मां शाकम्भरी',
        nativePlace: 'सीकर',
        currentCity: 'जयपुर',
        primaryPhone: '9811122233',
        email: 'sharma@example.com',
        members: [
          FamilyMember(
            id: 'm1',
            name: 'अमित शर्मा',
            relationship: 'पुत्र',
            phone: '9811122244',
          ),
        ],
      );

      final qr = ProfileQrService.encodeFamilyProfile(profile);
      final decoded = ProfileQrService.tryDecodeFamilyProfile(qr);

      expect(decoded, isNotNull);
      expect(decoded!.familyName, 'शर्मा परिवार');
      expect(decoded.headOfFamily, 'श्री रमेश चंद्र शर्मा');
      expect(decoded.gotra, 'कौशिक');
      expect(decoded.members.length, 1);
      expect(decoded.members.first.name, 'अमित शर्मा');

      final anyResult = ProfileQrService.decodeAny(qr);
      expect(anyResult, isA<VyavahaarDecodedFamily>());

      final dirFamily = decoded.toNewFamily();
      expect(dirFamily.name, 'शर्मा परिवार');
      final relatives = decoded.toRelativePersons(familyId: dirFamily.id);
      expect(relatives.length, 2);
      expect(relatives.first.fullName, 'श्री रमेश चंद्र शर्मा');
      expect(relatives.last.fullName, 'अमित शर्मा');
      expect(relatives.first.familyId, dirFamily.id);

      final formatted = ProfileQrService.formatFamilyProfileText(
        profile,
        AppLocalizations(const Locale('hi', 'IN')),
      );
      expect(formatted, contains('शर्मा परिवार'));
      expect(formatted, contains('कौशिक'));
      expect(formatted, contains('अमित शर्मा'));
    });

    test('decodeAny continues to support Event QR payloads without regression', () {
      final now = DateTime(2026, 11, 27);
      final event = Event(
        id: 'ev-qr-1',
        title: 'शुभ विवाह',
        eventType: EventType.shaadi,
        eventDate: '2026-12-20',
        createdAt: now,
        updatedAt: now,
      );
      final qr = EventQrService.encodeEvent(event);
      final anyResult = ProfileQrService.decodeAny(qr);
      expect(anyResult, isA<VyavahaarDecodedEvent>());
      expect((anyResult as VyavahaarDecodedEvent).payload.title, 'शुभ विवाह');
    });

    test('cross-type decoders reject mismatched kinds cleanly', () {
      final now = DateTime(2026, 11, 27);
      final personQr = ProfileQrService.encodePerson(
        Person(id: 'p1', fullName: 'टेस्ट', createdAt: now, updatedAt: now),
      );
      expect(EventQrService.tryDecode(personQr), isNull);
      expect(ProfileQrService.tryDecodeFamilyProfile(personQr), isNull);
      expect(ProfileQrService.decodeAny('invalid'), isNull);
    });
  });
}
