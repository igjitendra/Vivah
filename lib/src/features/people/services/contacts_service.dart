import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/entities.dart';

/// Comprehensive Offline Service for Phone Contacts Import, vCard Parsing,
/// CSV/vCard Export, and External Communications (Call, SMS, WhatsApp, Email).
class ContactsService {
  ContactsService._();

  /// Check whether native phone contact book access is supported on current platform
  static bool get isPhoneContactsSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// vCard file import is supported on ALL platforms (Android, iOS, Windows, macOS, Linux)
  static bool get isVCardImportSupported => true;

  /// Request runtime contacts permission
  static Future<bool> requestContactsPermission() async {
    if (!isPhoneContactsSupported) return false;
    try {
      return await FlutterContacts.requestPermission(readonly: true);
    } catch (_) {
      return false;
    }
  }

  /// Open native phone contact picker to select a single contact
  static Future<ContactDraft?> pickSinglePhoneContact() async {
    if (!isPhoneContactsSupported) return null;

    final hasPermission = await requestContactsPermission();
    if (!hasPermission) return null;

    try {
      final basicContact = await FlutterContacts.openExternalPick();
      if (basicContact == null) return null;

      // Fetch full properties including all phones, emails, addresses
      final fullContact = await FlutterContacts.getContact(
        basicContact.id,
        withProperties: true,
        withPhoto: true,
      );

      final contact = fullContact ?? basicContact;
      return _mapContactToDraft(contact);
    } catch (e) {
      debugPrint('Error picking native contact: $e');
      return null;
    }
  }

  /// Fetch all phone contacts for batch import review
  static Future<List<ContactDraft>> fetchAllPhoneContacts({bool withPhotos = false}) async {
    if (!isPhoneContactsSupported) return [];

    final hasPermission = await requestContactsPermission();
    if (!hasPermission) return [];

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: withPhotos,
      );

      return contacts.map(_mapContactToDraft).toList();
    } catch (e) {
      debugPrint('Error fetching all contacts: $e');
      return [];
    }
  }

  /// Helper to convert FlutterContacts [Contact] to [ContactDraft]
  static ContactDraft _mapContactToDraft(Contact c) {
    final phones = c.phones.map((p) => p.number.trim()).where((p) => p.isNotEmpty).toList();
    final emails = c.emails.map((e) => e.address.trim()).where((e) => e.isNotEmpty).toList();

    String? fullAddress;
    String? city;
    String? state;
    String? postalCode;

    if (c.addresses.isNotEmpty) {
      final primaryAddr = c.addresses.first;
      fullAddress = primaryAddr.address.trim();
      city = primaryAddr.city.trim().isNotEmpty ? primaryAddr.city.trim() : null;
      state = primaryAddr.state.trim().isNotEmpty ? primaryAddr.state.trim() : null;
      postalCode = primaryAddr.postalCode.trim().isNotEmpty ? primaryAddr.postalCode.trim() : null;
    }

    String? company;
    String? jobTitle;
    if (c.organizations.isNotEmpty) {
      final org = c.organizations.first;
      company = org.company.trim().isNotEmpty ? org.company.trim() : null;
      jobTitle = org.title.trim().isNotEmpty ? org.title.trim() : null;
    }

    String? birthday;
    final bdayEvent = c.events.where((ev) => ev.label == EventLabel.birthday).firstOrNull;
    if (bdayEvent != null) {
      final y = bdayEvent.year != null ? bdayEvent.year.toString().padLeft(4, '0') : '1990';
      final m = bdayEvent.month.toString().padLeft(2, '0');
      final d = bdayEvent.day.toString().padLeft(2, '0');
      birthday = '$y-$m-$d';
    }

    return ContactDraft(
      id: c.id,
      name: c.displayName.trim().isNotEmpty ? c.displayName.trim() : '${c.name.first} ${c.name.last}'.trim(),
      firstName: c.name.first.trim().isNotEmpty ? c.name.first.trim() : null,
      middleName: c.name.middle.trim().isNotEmpty ? c.name.middle.trim() : null,
      lastName: c.name.last.trim().isNotEmpty ? c.name.last.trim() : null,
      nickname: c.name.nickname.trim().isNotEmpty ? c.name.nickname.trim() : null,
      phones: phones,
      emails: emails,
      address: fullAddress,
      village: city,
      city: city,
      state: state,
      pinCode: postalCode,
      company: company,
      jobTitle: jobTitle,
      birthday: birthday,
      externalId: c.id,
      source: 'phone_contacts',
      notes: c.notes.isNotEmpty ? c.notes.first.note.trim() : null,
    );
  }

  // =========================================================================
  // vCard (.vcf) Parser & File Importer (Cross-Platform)
  // =========================================================================

  /// Pick a .vcf file from device storage and parse all contacts
  static Future<List<ContactDraft>> pickAndParseVCardFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vcf', 'vcard'],
      );

      if (result == null || result.files.isEmpty || result.files.first.path == null) {
        return [];
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      return parseVCardString(content);
    } catch (e) {
      debugPrint('Error picking vCard file: $e');
      return [];
    }
  }

  /// Robust vCard Parser supporting vCard 2.1, 3.0, and 4.0 specifications
  static List<ContactDraft> parseVCardString(String vCardContent) {
    final drafts = <ContactDraft>[];
    final vCards = vCardContent.split(RegExp(r'BEGIN:VCARD', caseSensitive: false));

    for (var i = 1; i < vCards.length; i++) {
      final block = vCards[i];
      final lines = block.split(RegExp(r'\r\n|\r|\n'));

      String name = '';
      String? firstName;
      String? middleName;
      String? lastName;
      String? nickname;
      final phones = <String>[];
      final emails = <String>[];
      String? address;
      String? city;
      String? state;
      String? postalCode;
      String? company;
      String? jobTitle;
      String? birthday;
      String? notes;

      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || line.toUpperCase().startsWith('END:VCARD')) continue;

        if (line.toUpperCase().startsWith('FN:') || line.toUpperCase().startsWith('FN;')) {
          final idx = line.indexOf(':');
          if (idx != -1) name = line.substring(idx + 1).trim();
        } else if (line.toUpperCase().startsWith('N:') || line.toUpperCase().startsWith('N;')) {
          final idx = line.indexOf(':');
          if (idx != -1) {
            final parts = line.substring(idx + 1).split(';');
            if (parts.isNotEmpty) lastName = parts[0].trim();
            if (parts.length > 1) firstName = parts[1].trim();
            if (parts.length > 2) middleName = parts[2].trim();
          }
        } else if (line.toUpperCase().startsWith('NICKNAME:') || line.toUpperCase().startsWith('NICKNAME;')) {
          final idx = line.indexOf(':');
          if (idx != -1) nickname = line.substring(idx + 1).trim();
        } else if (line.toUpperCase().startsWith('TEL:') || line.toUpperCase().startsWith('TEL;')) {
          final idx = line.indexOf(':');
          if (idx != -1) {
            final ph = line.substring(idx + 1).trim();
            if (ph.isNotEmpty && !phones.contains(ph)) phones.add(ph);
          }
        } else if (line.toUpperCase().startsWith('EMAIL:') || line.toUpperCase().startsWith('EMAIL;')) {
          final idx = line.indexOf(':');
          if (idx != -1) {
            final em = line.substring(idx + 1).trim();
            if (em.isNotEmpty && !emails.contains(em)) emails.add(em);
          }
        } else if (line.toUpperCase().startsWith('ADR:') || line.toUpperCase().startsWith('ADR;')) {
          final idx = line.indexOf(':');
          if (idx != -1) {
            final parts = line.substring(idx + 1).split(';');
            final cleanParts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
            if (cleanParts.isNotEmpty) address = cleanParts.join(', ');
            if (parts.length > 3 && parts[3].trim().isNotEmpty) city = parts[3].trim();
            if (parts.length > 4 && parts[4].trim().isNotEmpty) state = parts[4].trim();
            if (parts.length > 5 && parts[5].trim().isNotEmpty) postalCode = parts[5].trim();
          }
        } else if (line.toUpperCase().startsWith('ORG:') || line.toUpperCase().startsWith('ORG;')) {
          final idx = line.indexOf(':');
          if (idx != -1) company = line.substring(idx + 1).split(';').first.trim();
        } else if (line.toUpperCase().startsWith('TITLE:') || line.toUpperCase().startsWith('TITLE;')) {
          final idx = line.indexOf(':');
          if (idx != -1) jobTitle = line.substring(idx + 1).trim();
        } else if (line.toUpperCase().startsWith('BDAY:') || line.toUpperCase().startsWith('BDAY;')) {
          final idx = line.indexOf(':');
          if (idx != -1) birthday = line.substring(idx + 1).trim();
        } else if (line.toUpperCase().startsWith('NOTE:') || line.toUpperCase().startsWith('NOTE;')) {
          final idx = line.indexOf(':');
          if (idx != -1) notes = line.substring(idx + 1).trim();
        }
      }

      if (name.isEmpty && (firstName != null || lastName != null)) {
        name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      }

      if (name.isNotEmpty || phones.isNotEmpty || emails.isNotEmpty) {
        drafts.add(ContactDraft(
          id: 'vcard_${i}_${DateTime.now().millisecondsSinceEpoch}',
          name: name.isNotEmpty ? name : 'अज्ञात संपर्क',
          firstName: firstName,
          middleName: middleName,
          lastName: lastName,
          nickname: nickname,
          phones: phones,
          emails: emails,
          address: address,
          village: city,
          city: city,
          state: state,
          pinCode: postalCode,
          company: company,
          jobTitle: jobTitle,
          birthday: birthday,
          source: 'vcard_file',
          notes: notes,
        ));
      }
    }

    return drafts;
  }

  // =========================================================================
  // vCard & CSV Exporters
  // =========================================================================

  /// Generate vCard 3.0 text for a single person
  static String generatePersonVCard(Person p) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:${p.fullName}');
    buffer.writeln('N:${p.lastName ?? ''};${p.firstName ?? p.fullName};${p.middleName ?? ''};;');
    if (p.nickname != null && p.nickname!.isNotEmpty) {
      buffer.writeln('NICKNAME:${p.nickname}');
    }
    if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL,PREF:${p.phoneNumber}');
    }
    for (final sec in p.secondaryPhones) {
      if (sec.isNotEmpty && sec != p.phoneNumber) {
        buffer.writeln('TEL;TYPE=VOICE:$sec');
      }
    }
    for (final em in p.emails) {
      if (em.isNotEmpty) {
        buffer.writeln('EMAIL;TYPE=INTERNET:$em');
      }
    }
    if (p.fullAddress.isNotEmpty) {
      buffer.writeln('ADR;TYPE=HOME:;;${p.address ?? ''};${p.city ?? p.village ?? ''};${p.state ?? ''};${p.pinCode ?? ''};India');
    }
    if (p.occupation != null && p.occupation!.isNotEmpty) {
      buffer.writeln('TITLE:${p.occupation}');
    }
    if (p.company != null && p.company!.isNotEmpty) {
      buffer.writeln('ORG:${p.company}');
    }
    if (p.notes != null && p.notes!.isNotEmpty) {
      buffer.writeln('NOTE:${p.notes}');
    }
    buffer.writeln('PRODID:-//व्यवहार Digital Family Ledger//Vyavahaar App//EN');
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  /// Export multiple people to a single .vcf file and share
  static Future<void> exportAndShareVCard(List<Person> people, {String fileName = 'vyavahaar_contacts.vcf'}) async {
    if (people.isEmpty) return;

    final buffer = StringBuffer();
    for (final p in people) {
      buffer.writeln(generatePersonVCard(p));
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await SharePlus.shareXFiles(
      [XFile(file.path)],
      subject: 'व्यवहार संपर्क सूची (vCard)',
      text: '${people.length} संपर्क व्यवहार ऐप से निर्यात किए गए।',
    );
  }

  /// Export multiple people to a standard CSV file and share
  static Future<void> exportAndShareCsv(List<Person> people, {String fileName = 'vyavahaar_contacts.csv'}) async {
    if (people.isEmpty) return;

    final csvRows = <List<String>>[
      [
        'नाम (Full Name)',
        'उपनाम (Nickname)',
        'प्राथमिक फ़ोन (Primary Phone)',
        'अतिरिक्त फ़ोन (Secondary Phones)',
        'ईमेल (Emails)',
        'रिश्ता (Relationship)',
        'पता / गाँव (Address / Village)',
        'शहर (City)',
        'ज़िला (District)',
        'राज्य (State)',
        'पिन कोड (PIN Code)',
        'व्यवसाय (Occupation)',
        'कंपनी (Company)',
        'टैग (Tags)',
        'नोट्स (Notes)',
      ],
    ];

    for (final p in people) {
      csvRows.add([
        p.fullName,
        p.nickname ?? '',
        p.phoneNumber ?? '',
        p.secondaryPhones.join('; '),
        p.emails.join('; '),
        p.relationshipLabel ?? '',
        p.address ?? p.village ?? '',
        p.city ?? '',
        p.district ?? '',
        p.state ?? '',
        p.pinCode ?? '',
        p.occupation ?? '',
        p.company ?? '',
        p.tags.join(', '),
        p.notes ?? '',
      ]);
    }

    // Convert rows to CSV string
    final csvContent = csvRows.map((row) {
      return row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
    }).join('\n');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csvContent);

    await SharePlus.shareXFiles(
      [XFile(file.path)],
      subject: 'व्यवहार संपर्क सूची (CSV)',
      text: '${people.length} संपर्क व्यवहार ऐप से CSV में निर्यात किए गए।',
    );
  }

  // =========================================================================
  // External Action Launchers (Dialer, SMS, WhatsApp, Mail, System Share)
  // =========================================================================

  /// Open phone dialer with number
  static Future<bool> callPhone(String rawPhone) async {
    final clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Open SMS app with number and optional pre-filled text
  static Future<bool> sendSms(String rawPhone, {String? body}) async {
    final clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final uri = Uri(
      scheme: 'sms',
      path: clean,
      queryParameters: body != null && body.isNotEmpty ? {'body': body} : null,
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Open WhatsApp chat directly with phone number
  static Future<bool> openWhatsApp(String rawPhone, {String? message}) async {
    var clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    // Ensure Indian country code prefix if 10-digit number
    if (clean.length == 10) {
      clean = '91$clean';
    } else if (clean.startsWith('0') && clean.length == 11) {
      clean = '91${clean.substring(1)}';
    }

    // Attempt WhatsApp native URL first, then fallback to wa.me web redirect
    final nativeUri = Uri.parse('whatsapp://send?phone=$clean${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}');
    final webUri = Uri.parse('https://wa.me/$clean${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}');

    if (await canLaunchUrl(nativeUri)) {
      return launchUrl(nativeUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Open email client with recipient and optional subject/body
  static Future<bool> sendEmail(String email, {String? subject, String? body}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email.trim(),
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  /// Share person contact card via system share sheet
  static Future<void> sharePersonCard(Person p) async {
    final buffer = StringBuffer();
    buffer.writeln('📇 संपर्क विवरण: ${p.displayName}');
    if (p.relationshipLabel != null && p.relationshipLabel!.isNotEmpty) {
      buffer.writeln('रिश्ता: ${p.relationshipLabel}');
    }
    if (p.phoneNumber != null && p.phoneNumber!.isNotEmpty) {
      buffer.writeln('फ़ोन: ${p.phoneNumber}');
    }
    if (p.secondaryPhones.isNotEmpty) {
      buffer.writeln('अन्य फ़ोन: ${p.secondaryPhones.join(', ')}');
    }
    if (p.emails.isNotEmpty) {
      buffer.writeln('ईमेल: ${p.emails.join(', ')}');
    }
    if (p.fullAddress.isNotEmpty) {
      buffer.writeln('पता: ${p.fullAddress}');
    }
    buffer.writeln('\n— व्यवहार (Vyavahaar) डिजिटल फैमिली लेजर');

    await SharePlus.share(
      buffer.toString(),
      subject: 'संपर्क: ${p.fullName}',
    );
  }
}
