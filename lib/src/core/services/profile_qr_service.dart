import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../domain/entities/entities.dart';
import '../localization/app_localizations.dart';
import 'event_qr_service.dart';

/// Compact family member metadata serialized inside a Family Profile QR code.
class FamilyQrMember {
  final String name;
  final String relationship;
  final String? phone;
  final String? occupation;

  const FamilyQrMember({
    required this.name,
    required this.relationship,
    this.phone,
    this.occupation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'n': name};
    if (relationship.trim().isNotEmpty) map['r'] = relationship.trim();
    if (phone != null && phone!.trim().isNotEmpty) map['ph'] = phone!.trim();
    if (occupation != null && occupation!.trim().isNotEmpty) map['occ'] = occupation!.trim();
    return map;
  }

  static FamilyQrMember? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final name = (raw['n'] ?? raw['name'])?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    final rel = (raw['r'] ?? raw['relationship'])?.toString().trim() ?? '';
    final phone = (raw['ph'] ?? raw['phone'])?.toString().trim();
    final occ = (raw['occ'] ?? raw['occupation'])?.toString().trim();
    return FamilyQrMember(
      name: name,
      relationship: rel,
      phone: (phone != null && phone.isNotEmpty) ? phone : null,
      occupation: (occ != null && occ.isNotEmpty) ? occ : null,
    );
  }
}

/// Decoded offline QR payload for a Relative ([Person]).
class PersonQrPayload {
  static const String kindValue = 'person';
  final int version;
  final String fullName;
  final String? relationshipLabel;
  final String? phoneNumber;
  final List<String> secondaryPhones;
  final String? whatsappNumber;
  final List<String> emails;
  final String? address;
  final String? village;
  final String? city;
  final String? district;
  final String? state;
  final String? pinCode;
  final String? occupation;
  final String? company;
  final String? notes;
  final List<String> tags;

  const PersonQrPayload({
    this.version = 1,
    required this.fullName,
    this.relationshipLabel,
    this.phoneNumber,
    this.secondaryPhones = const [],
    this.whatsappNumber,
    this.emails = const [],
    this.address,
    this.village,
    this.city,
    this.district,
    this.state,
    this.pinCode,
    this.occupation,
    this.company,
    this.notes,
    this.tags = const [],
  });

  /// Converts this decoded QR contact into a fresh local [Person] ready for saving.
  Person toNewPerson({
    String? familyId,
    String? overrideRelationship,
  }) {
    final now = DateTime.now();
    final rel = (overrideRelationship != null && overrideRelationship.trim().isNotEmpty)
        ? overrideRelationship.trim()
        : relationshipLabel;
    return Person(
      id: const Uuid().v4(),
      familyId: familyId,
      fullName: fullName.trim(),
      phoneNumber: phoneNumber,
      secondaryPhones: secondaryPhones,
      whatsappNumber: whatsappNumber,
      emails: emails,
      address: address,
      village: village,
      city: city,
      district: district,
      state: state,
      pinCode: pinCode,
      relationshipLabel: rel,
      occupation: occupation,
      company: company,
      notes: notes,
      tags: tags,
      contactSource: 'qr_import',
      importedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Decoded offline QR payload for a Family Profile ([FamilyProfile]).
class FamilyProfileQrPayload {
  static const String kindValue = 'family_profile';
  final int version;
  final String familyName;
  final String? headOfFamily;
  final String? nativePlace;
  final String? currentCity;
  final String? address;
  final String? gotra;
  final String? kuldevi;
  final String? primaryPhone;
  final String? alternatePhone;
  final String? email;
  final String? about;
  final List<FamilyQrMember> members;

  const FamilyProfileQrPayload({
    this.version = 1,
    required this.familyName,
    this.headOfFamily,
    this.nativePlace,
    this.currentCity,
    this.address,
    this.gotra,
    this.kuldevi,
    this.primaryPhone,
    this.alternatePhone,
    this.email,
    this.about,
    this.members = const [],
  });

  /// Converts this scanned Family Profile into a directory [Family] record.
  Family toNewFamily() {
    final now = DateTime.now();
    final descParts = <String>[
      if (headOfFamily != null && headOfFamily!.isNotEmpty) headOfFamily!,
      if (gotra != null && gotra!.isNotEmpty) gotra!,
      if (nativePlace != null && nativePlace!.isNotEmpty) nativePlace!,
    ];
    final noteLines = <String>[
      if (kuldevi != null && kuldevi!.isNotEmpty) 'कुलदेवी/कुलदेवता: $kuldevi',
      if (primaryPhone != null && primaryPhone!.isNotEmpty) 'फ़ोन: $primaryPhone',
      if (currentCity != null && currentCity!.isNotEmpty) 'शहर: $currentCity',
      if (address != null && address!.isNotEmpty) 'पता: $address',
      if (about != null && about!.isNotEmpty) about!,
    ];
    return Family(
      id: const Uuid().v4(),
      name: familyName.trim(),
      description: descParts.isNotEmpty ? descParts.join(' • ') : null,
      notes: noteLines.isNotEmpty ? noteLines.join('\n') : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Extracts [Person] records for the Head of Family and listed members.
  List<Person> toRelativePersons({required String familyId}) {
    final now = DateTime.now();
    final people = <Person>[];
    final seenNames = <String>{};

    void addCandidate({
      required String name,
      String? relation,
      String? phone,
      String? occupation,
    }) {
      final cleanName = name.trim();
      if (cleanName.isEmpty) return;
      final key = cleanName.toLowerCase();
      if (seenNames.contains(key)) return;
      seenNames.add(key);

      final extraPhones = (phone == null && alternatePhone != null && people.isEmpty)
          ? [alternatePhone!]
          : const <String>[];
      people.add(
        Person(
          id: const Uuid().v4(),
          familyId: familyId,
          fullName: cleanName,
          phoneNumber: phone ?? (people.isEmpty ? primaryPhone : null),
          secondaryPhones: extraPhones,
          emails: (people.isEmpty && email != null && email!.isNotEmpty) ? [email!] : const [],
          village: nativePlace,
          city: currentCity,
          address: address,
          relationshipLabel: relation,
          occupation: occupation,
          contactSource: 'qr_import',
          importedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (headOfFamily != null && headOfFamily!.trim().isNotEmpty) {
      addCandidate(
        name: headOfFamily!,
        relation: familyName,
        phone: primaryPhone,
      );
    }

    for (final m in members) {
      addCandidate(
        name: m.name,
        relation: m.relationship.isNotEmpty ? m.relationship : familyName,
        phone: m.phone,
        occupation: m.occupation,
      );
    }

    return people;
  }
}

/// Sealed result returned when decoding any supported Vyavahaar offline QR code.
sealed class VyavahaarQrDecodeResult {
  const VyavahaarQrDecodeResult();
}

final class VyavahaarDecodedEvent extends VyavahaarQrDecodeResult {
  final EventQrPayload payload;
  const VyavahaarDecodedEvent(this.payload);
}

final class VyavahaarDecodedPerson extends VyavahaarQrDecodeResult {
  final PersonQrPayload payload;
  const VyavahaarDecodedPerson(this.payload);
}

final class VyavahaarDecodedFamily extends VyavahaarQrDecodeResult {
  final FamilyProfileQrPayload payload;
  const VyavahaarDecodedFamily(this.payload);
}

/// Offline QR encoding, decoding, and formatted text sharing for Relatives and Family Profiles.
class ProfileQrService {
  ProfileQrService._();

  static const int _maxNotesLength = 140;
  static const int _maxMembersInQr = 10;

  static String? _cleanOpt(dynamic val) {
    final s = val?.toString().trim();
    return (s != null && s.isNotEmpty) ? s : null;
  }

  static List<String> _cleanList(dynamic raw, int limit) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .take(limit)
        .toList();
  }

  static Map<String, dynamic>? _extractVyavahaarJson(String? raw) {
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
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Encodes a Relative ([Person]) into a compact offline Vyavahaar QR JSON payload.
  static String encodePerson(Person person) {
    final map = <String, dynamic>{
      'app': EventQrPayload.appIdentifier,
      'kind': PersonQrPayload.kindValue,
      'v': 1,
      'n': person.fullName.trim(),
    };

    void put(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) map[k] = v.trim();
    }

    put('rel', person.relationshipLabel);
    put('ph', person.phoneNumber);
    if (person.secondaryPhones.isNotEmpty) {
      map['ph2'] = person.secondaryPhones.where((e) => e.trim().isNotEmpty).take(2).toList();
    }
    put('wa', person.whatsappNumber);
    if (person.emails.isNotEmpty) {
      map['em'] = person.emails.where((e) => e.trim().isNotEmpty).take(2).toList();
    }
    put('adr', person.address);
    put('vil', person.village);
    put('cty', person.city);
    put('dst', person.district);
    put('st', person.state);
    put('pin', person.pinCode);
    put('occ', person.occupation);
    put('cmp', person.company);
    if (person.tags.isNotEmpty) {
      map['tags'] = person.tags.where((e) => e.trim().isNotEmpty).take(5).toList();
    }
    final cleanNote = person.notes?.trim();
    if (cleanNote != null && cleanNote.isNotEmpty) {
      map['notes'] = cleanNote.length > _maxNotesLength
          ? '${cleanNote.substring(0, _maxNotesLength)}...'
          : cleanNote;
    }
    return jsonEncode(map);
  }

  /// Encodes a [FamilyProfile] into a compact offline Vyavahaar QR JSON payload.
  static String encodeFamilyProfile(FamilyProfile profile) {
    final title = profile.familyName.trim().isNotEmpty
        ? profile.familyName.trim()
        : (profile.headOfFamily.trim().isNotEmpty ? profile.headOfFamily.trim() : 'परिवार');
    final map = <String, dynamic>{
      'app': EventQrPayload.appIdentifier,
      'kind': FamilyProfileQrPayload.kindValue,
      'v': 1,
      'fn': title,
    };

    void put(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) map[k] = v.trim();
    }

    put('hd', profile.headOfFamily);
    put('np', profile.nativePlace);
    put('cc', profile.currentCity);
    put('adr', profile.address);
    put('gt', profile.gotra);
    put('kd', profile.kuldevi);
    put('ph', profile.primaryPhone);
    put('ph2', profile.alternatePhone);
    put('em', profile.email);

    final about = profile.about.trim();
    if (about.isNotEmpty) {
      map['abt'] = about.length > _maxNotesLength
          ? '${about.substring(0, _maxNotesLength)}...'
          : about;
    }

    if (profile.members.isNotEmpty) {
      map['m'] = profile.members
          .take(_maxMembersInQr)
          .map(
            (m) => FamilyQrMember(
              name: m.name.trim(),
              relationship: m.relationship.trim(),
              phone: m.phone,
              occupation: m.occupation,
            ).toJson(),
          )
          .toList();
    }

    return jsonEncode(map);
  }

  /// Decodes raw QR text into a [PersonQrPayload], or returns `null` if invalid.
  static PersonQrPayload? tryDecodePerson(String? raw) {
    final decoded = _extractVyavahaarJson(raw);
    if (decoded == null) return null;
    if (decoded['kind']?.toString().trim() != PersonQrPayload.kindValue) return null;
    final name = _cleanOpt(decoded['n'] ?? decoded['fullName']);
    if (name == null) return null;

    return PersonQrPayload(
      version: decoded['v'] is int ? decoded['v'] as int : 1,
      fullName: name,
      relationshipLabel: _cleanOpt(decoded['rel']),
      phoneNumber: _cleanOpt(decoded['ph']),
      secondaryPhones: _cleanList(decoded['ph2'], 3),
      whatsappNumber: _cleanOpt(decoded['wa']),
      emails: _cleanList(decoded['em'], 3),
      address: _cleanOpt(decoded['adr']),
      village: _cleanOpt(decoded['vil']),
      city: _cleanOpt(decoded['cty']),
      district: _cleanOpt(decoded['dst']),
      state: _cleanOpt(decoded['st']),
      pinCode: _cleanOpt(decoded['pin']),
      occupation: _cleanOpt(decoded['occ']),
      company: _cleanOpt(decoded['cmp']),
      notes: _cleanOpt(decoded['notes']),
      tags: _cleanList(decoded['tags'], 5),
    );
  }

  /// Decodes raw QR text into a [FamilyProfileQrPayload], or returns `null` if invalid.
  static FamilyProfileQrPayload? tryDecodeFamilyProfile(String? raw) {
    final decoded = _extractVyavahaarJson(raw);
    if (decoded == null) return null;
    if (decoded['kind']?.toString().trim() != FamilyProfileQrPayload.kindValue) return null;
    final familyName = _cleanOpt(decoded['fn'] ?? decoded['familyName']);
    if (familyName == null) return null;

    final rawMembers = decoded['m'];
    final members = <FamilyQrMember>[];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        final parsed = FamilyQrMember.fromJson(item);
        if (parsed != null) members.add(parsed);
      }
    }

    return FamilyProfileQrPayload(
      version: decoded['v'] is int ? decoded['v'] as int : 1,
      familyName: familyName,
      headOfFamily: _cleanOpt(decoded['hd']),
      nativePlace: _cleanOpt(decoded['np']),
      currentCity: _cleanOpt(decoded['cc']),
      address: _cleanOpt(decoded['adr']),
      gotra: _cleanOpt(decoded['gt']),
      kuldevi: _cleanOpt(decoded['kd']),
      primaryPhone: _cleanOpt(decoded['ph']),
      alternatePhone: _cleanOpt(decoded['ph2']),
      email: _cleanOpt(decoded['em']),
      about: _cleanOpt(decoded['abt']),
      members: members,
    );
  }

  /// Decodes any supported Vyavahaar offline QR payload (Event, Relative, or Family Profile).
  static VyavahaarQrDecodeResult? decodeAny(String? raw) {
    final decoded = _extractVyavahaarJson(raw);
    if (decoded == null) return null;
    final kind = decoded['kind']?.toString().trim();

    if (kind == PersonQrPayload.kindValue) {
      final person = tryDecodePerson(raw);
      return person != null ? VyavahaarDecodedPerson(person) : null;
    }
    if (kind == FamilyProfileQrPayload.kindValue) {
      final family = tryDecodeFamilyProfile(raw);
      return family != null ? VyavahaarDecodedFamily(family) : null;
    }

    final event = EventQrService.tryDecode(raw);
    return event != null ? VyavahaarDecodedEvent(event) : null;
  }

  /// Formats a [FamilyProfile] into clean shareable text for WhatsApp/SMS/System Share.
  static String formatFamilyProfileText(FamilyProfile p, AppLocalizations l10n) {
    final buf = StringBuffer();
    final title = p.familyName.trim().isNotEmpty ? p.familyName.trim() : l10n.myFamily;
    buf.writeln(title);
    if (p.headOfFamily.trim().isNotEmpty) {
      buf.writeln('${l10n.mukhiyaBadge}: ${p.headOfFamily.trim()}');
    }
    if (p.gotra.trim().isNotEmpty) {
      buf.writeln('${l10n.gotra}: ${p.gotra.trim()}');
    }
    if (p.kuldevi.trim().isNotEmpty) {
      buf.writeln('${l10n.kuldevi}: ${p.kuldevi.trim()}');
    }
    if (p.nativePlace.trim().isNotEmpty) {
      buf.writeln('${l10n.nativePlace}: ${p.nativePlace.trim()}');
    }
    if (p.currentCity.trim().isNotEmpty) {
      buf.writeln('${l10n.currentCity}: ${p.currentCity.trim()}');
    }
    if (p.address.trim().isNotEmpty) {
      buf.writeln('${l10n.fullAddress}: ${p.address.trim()}');
    }
    if (p.primaryPhone.trim().isNotEmpty) {
      buf.writeln('${l10n.primaryPhone}: ${p.primaryPhone.trim()}');
    }
    if (p.alternatePhone.trim().isNotEmpty) {
      buf.writeln('${l10n.alternatePhone}: ${p.alternatePhone.trim()}');
    }
    if (p.email.trim().isNotEmpty) {
      buf.writeln('${l10n.familyEmail}: ${p.email.trim()}');
    }
    if (p.members.isNotEmpty) {
      buf.writeln('');
      buf.writeln('${l10n.familyMembers} (${p.members.length}):');
      for (final m in p.members) {
        final phonePart = (m.phone != null && m.phone!.trim().isNotEmpty) ? ' • ${m.phone}' : '';
        final relPart = m.relationship.trim().isNotEmpty ? ' (${m.relationship.trim()})' : '';
        buf.writeln('• ${m.name}$relPart$phonePart');
      }
    }
    if (p.about.trim().isNotEmpty) {
      buf.writeln('');
      buf.writeln(p.about.trim());
    }
    buf.writeln('\n— ${l10n.appName}');
    return buf.toString().trim();
  }
}
