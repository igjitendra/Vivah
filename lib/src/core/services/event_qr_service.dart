import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../utils/date_utils.dart';
import '../../domain/entities/entities.dart';
import '../../domain/enums/transaction_enums.dart';

/// Function item serialized inside an event invitation QR payload.
class EventQrFunction {
  final String title;
  final String functionDate;
  final String? startTime;
  final String? venue;

  const EventQrFunction({
    required this.title,
    required this.functionDate,
    this.startTime,
    this.venue,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'n': title,
      'd': functionDate,
    };
    if (startTime != null && startTime!.trim().isNotEmpty) {
      map['t'] = startTime!.trim();
    }
    if (venue != null && venue!.trim().isNotEmpty) {
      map['v'] = venue!.trim();
    }
    return map;
  }

  static EventQrFunction? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final title = (raw['n'] ?? raw['title'])?.toString().trim() ?? '';
    if (title.isEmpty) return null;
    final date = (raw['d'] ?? raw['functionDate'])?.toString().trim() ?? '';
    final time = (raw['t'] ?? raw['startTime'])?.toString().trim();
    final venue = (raw['v'] ?? raw['venue'])?.toString().trim();
    return EventQrFunction(
      title: title,
      functionDate: date,
      startTime: (time != null && time.isNotEmpty) ? time : null,
      venue: (venue != null && venue.isNotEmpty) ? venue : null,
    );
  }
}

/// Decoded offline payload of a Vyavahaar Event QR invitation.
class EventQrPayload {
  static const String appIdentifier = 'vyavahaar';
  static const int currentVersion = 1;

  final int version;
  final String? sourceEventId;
  final String title;
  final EventType eventType;
  final String? category;
  final String eventDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? address;
  final String? villageCity;
  final String? hostName;
  final String? notes;
  final List<EventQrFunction> functions;

  const EventQrPayload({
    this.version = currentVersion,
    this.sourceEventId,
    required this.title,
    required this.eventType,
    this.category,
    required this.eventDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.venue,
    this.address,
    this.villageCity,
    this.hostName,
    this.notes,
    this.functions = const [],
  });

  /// Converts this decoded invitation payload into a fresh local [Event] entity ready to save.
  Event toNewEvent({
    EventScope scope = EventScope.relative,
    String? overrideHostName,
    String? attendingFamilyNote,
    bool addReminder = true,
  }) {
    final now = DateTime.now();
    final newEventId = const Uuid().v4();
    final effectiveHost = (overrideHostName != null && overrideHostName.trim().isNotEmpty)
        ? overrideHostName.trim()
        : hostName;

    final mappedFunctions = functions
        .map(
          (f) => EventFunction(
            id: const Uuid().v4(),
            eventId: newEventId,
            title: f.title,
            functionDate: _isValidIsoDate(f.functionDate) ? f.functionDate : eventDate,
            startTime: f.startTime,
            venue: f.venue,
            status: EventStatus.planned,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    return Event(
      id: newEventId,
      title: title.trim(),
      eventType: eventType,
      category: category,
      eventDate: eventDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      venue: venue,
      address: address,
      villageCity: villageCity,
      notes: notes,
      status: EventStatus.planned,
      priority: EventPriority.normal,
      eventScope: scope,
      hostPersonName: scope == EventScope.relative ? effectiveHost : null,
      attendingFamilyNote: (attendingFamilyNote != null && attendingFamilyNote.trim().isNotEmpty)
          ? attendingFamilyNote.trim()
          : null,
      createdAt: now,
      updatedAt: now,
      functions: mappedFunctions,
      reminders: addReminder
          ? [
              EventReminder(
                id: const Uuid().v4(),
                eventId: newEventId,
                title: '${title.trim()} — 1 दिन पहले',
                reminderDate: AppDateUtils.reminderDateForPreset(eventDate, '1_day_before'),
                preset: '1_day_before',
                createdAt: now,
              ),
            ]
          : const [],
    );
  }

  static bool _isValidIsoDate(String value) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim());
  }
}

/// Offline QR encoding/decoding helper for sharing Vyavahaar events without network access.
class EventQrService {
  EventQrService._();

  static const int _maxNotesLength = 180;
  static const int _maxFunctionsCount = 8;

  /// Resolves the best display name for the event host / sender family.
  static String? resolveHostDisplayName(Event event, FamilyProfile? profile) {
    if (event.hostPersonName != null && event.hostPersonName!.trim().isNotEmpty) {
      return event.hostPersonName!.trim();
    }
    if (profile != null) {
      if (profile.familyName.trim().isNotEmpty) {
        return profile.familyName.trim();
      }
      if (profile.headOfFamily.trim().isNotEmpty) {
        return profile.headOfFamily.trim();
      }
    }
    return null;
  }

  /// Encodes an [Event] into a compact UTF-8 JSON string suitable for fast QR scanning.
  static String encodeEvent(Event event, {FamilyProfile? familyProfile}) {
    final map = <String, dynamic>{
      'app': EventQrPayload.appIdentifier,
      'v': EventQrPayload.currentVersion,
      'eid': event.id,
      't': event.title.trim(),
      'tp': event.eventType.name,
      'd': event.eventDate.trim(),
    };

    void putIfNonEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        map[key] = value.trim();
      }
    }

    putIfNonEmpty('cat', event.category);
    putIfNonEmpty('ed', event.endDate);
    putIfNonEmpty('st', event.startTime);
    putIfNonEmpty('et', event.endTime);
    putIfNonEmpty('ven', event.venue);
    putIfNonEmpty('adr', event.address);
    putIfNonEmpty('cty', event.villageCity ?? familyProfile?.nativePlace);
    putIfNonEmpty('hst', resolveHostDisplayName(event, familyProfile));

    final noteSource = (event.notes ?? event.description)?.trim();
    if (noteSource != null && noteSource.isNotEmpty) {
      map['notes'] = noteSource.length > _maxNotesLength
          ? '${noteSource.substring(0, _maxNotesLength)}...'
          : noteSource;
    }

    if (event.functions.isNotEmpty) {
      map['fns'] = event.functions
          .take(_maxFunctionsCount)
          .map(
            (fn) => EventQrFunction(
              title: fn.title.trim(),
              functionDate: fn.functionDate.trim(),
              startTime: fn.startTime,
              venue: fn.venue,
            ).toJson(),
          )
          .toList();
    }

    return jsonEncode(map);
  }

  /// Attempts to parse raw scanned QR text into an [EventQrPayload].
  /// Returns `null` if the QR code is not a valid Vyavahaar Event payload.
  static EventQrPayload? tryDecode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    String jsonCandidate = trimmed;
    if (trimmed.startsWith('vyavahaar://')) {
      final uri = Uri.tryParse(trimmed);
      final encodedData = uri?.queryParameters['d'] ?? uri?.queryParameters['data'];
      if (encodedData == null || encodedData.isEmpty) return null;
      jsonCandidate = encodedData;
    }

    if (!jsonCandidate.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(jsonCandidate);
      if (decoded is! Map<String, dynamic>) return null;

      final app = decoded['app']?.toString().trim().toLowerCase();
      if (app != EventQrPayload.appIdentifier) return null;

      final title = (decoded['t'] ?? decoded['title'])?.toString().trim() ?? '';
      if (title.isEmpty) return null;

      final rawType = (decoded['tp'] ?? decoded['eventType'])?.toString().trim() ?? 'other';
      final rawDate = (decoded['d'] ?? decoded['eventDate'])?.toString().trim() ?? '';
      final validDate = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)
          ? rawDate
          : DateTime.now().toIso8601String().substring(0, 10);

      String? cleanOpt(dynamic val) {
        final s = val?.toString().trim();
        return (s != null && s.isNotEmpty) ? s : null;
      }

      final fnsRaw = decoded['fns'];
      final parsedFunctions = <EventQrFunction>[];
      if (fnsRaw is List) {
        for (final item in fnsRaw) {
          final parsed = EventQrFunction.fromJson(item);
          if (parsed != null) {
            parsedFunctions.add(parsed);
          }
        }
      }

      final rawVersion = decoded['v'];
      final version = rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '') ?? EventQrPayload.currentVersion;

      return EventQrPayload(
        version: version,
        sourceEventId: cleanOpt(decoded['eid']),
        title: title,
        eventType: EventType.fromString(rawType),
        category: cleanOpt(decoded['cat']),
        eventDate: validDate,
        endDate: cleanOpt(decoded['ed']),
        startTime: cleanOpt(decoded['st']),
        endTime: cleanOpt(decoded['et']),
        venue: cleanOpt(decoded['ven'] ?? decoded['venue']),
        address: cleanOpt(decoded['adr'] ?? decoded['address']),
        villageCity: cleanOpt(decoded['cty'] ?? decoded['villageCity']),
        hostName: cleanOpt(decoded['hst'] ?? decoded['hostName']),
        notes: cleanOpt(decoded['notes'] ?? decoded['description']),
        functions: parsedFunctions,
      );
    } catch (_) {
      return null;
    }
  }
}
