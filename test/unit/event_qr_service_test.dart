import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/services/event_qr_service.dart';
import 'package:vyavahaar/src/domain/entities/entities.dart';
import 'package:vyavahaar/src/domain/enums/transaction_enums.dart';

void main() {
  group('EventQrService Offline QR Encoding & Decoding', () {
    test('encodes wedding event with functions and family host, then decodes identically', () {
      final now = DateTime(2026, 11, 26);
      final sourceEvent = Event(
        id: 'evt-source-1',
        title: 'राहुल एवं प्रिया शुभ विवाह',
        eventType: EventType.shaadi,
        eventDate: '2026-12-15',
        venue: 'शर्मा वाटिका',
        villageCity: 'अयोध्या',
        notes: 'सपरिवार सादर आमंत्रित हैं।',
        eventScope: EventScope.ownFamily,
        createdAt: now,
        updatedAt: now,
        functions: [
          EventFunction(
            id: 'fn-1',
            eventId: 'evt-source-1',
            title: 'हल्दी एवं मेहंदी',
            functionDate: '2026-12-14',
            startTime: '11:00',
            createdAt: now,
            updatedAt: now,
          ),
          EventFunction(
            id: 'fn-2',
            eventId: 'evt-source-1',
            title: 'बारात एवं पाणिग्रहण',
            functionDate: '2026-12-15',
            startTime: '19:30',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      const profile = FamilyProfile(
        familyName: 'शर्मा परिवार',
        headOfFamily: 'श्री रमेश चंद्र शर्मा',
        nativePlace: 'अयोध्या',
      );

      final qrText = EventQrService.encodeEvent(sourceEvent, familyProfile: profile);
      final decoded = EventQrService.tryDecode(qrText);

      expect(decoded, isNotNull);
      expect(decoded!.sourceEventId, 'evt-source-1');
      expect(decoded.title, 'राहुल एवं प्रिया शुभ विवाह');
      expect(decoded.eventType, EventType.shaadi);
      expect(decoded.eventDate, '2026-12-15');
      expect(decoded.venue, 'शर्मा वाटिका');
      expect(decoded.villageCity, 'अयोध्या');
      expect(decoded.hostName, 'शर्मा परिवार');
      expect(decoded.functions.length, 2);
      expect(decoded.functions.first.title, 'हल्दी एवं मेहंदी');

      final imported = decoded.toNewEvent();
      expect(imported.id, isNot('evt-source-1'));
      expect(imported.eventScope, EventScope.relative);
      expect(imported.hostPersonName, 'शर्मा परिवार');
      expect(imported.functions.length, 2);
      expect(imported.functions.first.eventId, imported.id);
      expect(imported.reminders.length, 1);
      expect(imported.reminders.single.reminderDate, '2026-12-14');

      final withoutReminder = decoded.toNewEvent(addReminder: false);
      expect(withoutReminder.reminders, isEmpty);
    });

    test('supports override host name and ownFamily scope on import', () {
      final now = DateTime(2026, 11, 26);
      final source = Event(
        id: 'evt-2',
        title: 'मुंडन संस्कार',
        eventType: EventType.mundan,
        eventDate: '2026-12-20',
        createdAt: now,
        updatedAt: now,
      );

      final qrText = EventQrService.encodeEvent(source);
      final decoded = EventQrService.tryDecode(qrText);
      expect(decoded, isNotNull);

      final asRelative = decoded!.toNewEvent(
        scope: EventScope.relative,
        overrideHostName: 'मामा जी',
      );
      expect(asRelative.eventScope, EventScope.relative);
      expect(asRelative.hostPersonName, 'मामा जी');

      final asOwn = decoded.toNewEvent(
        scope: EventScope.ownFamily,
        overrideHostName: 'मामा जी',
      );
      expect(asOwn.eventScope, EventScope.ownFamily);
      expect(asOwn.hostPersonName, isNull);
    });

    test('rejects invalid or non-Vyavahaar QR payloads gracefully', () {
      expect(EventQrService.tryDecode(null), isNull);
      expect(EventQrService.tryDecode(''), isNull);
      expect(EventQrService.tryDecode('upi://pay?pa=test@upi'), isNull);
      expect(EventQrService.tryDecode('https://example.com'), isNull);
      expect(EventQrService.tryDecode('{"app":"other","t":"Test"}'), isNull);
      expect(EventQrService.tryDecode('{"app":"vyavahaar","t":""}'), isNull);
      expect(EventQrService.tryDecode('{malformed json'), isNull);
    });
  });
}
