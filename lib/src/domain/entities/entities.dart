import 'package:characters/characters.dart';
import '../enums/transaction_enums.dart';
export 'family_profile.dart';

/// Family Entity (परिवार / कुल)
class Family {
  final String id;
  final String name;
  final String? description;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Family({
    required this.id,
    required this.name,
    this.description,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
}

/// Person Entity (व्यक्ति / रिश्तेदार / परिचित)
class Person {
  final String id;
  final String? familyId;
  final String fullName;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? nickname;
  final String? gender; // 'male', 'female', 'other'
  final String? dateOfBirth; // YYYY-MM-DD
  final String? photoPath;

  // Contact Info
  final String? phoneNumber; // Primary phone
  final List<String> secondaryPhones;
  final String? whatsappNumber;
  final List<String> emails;

  // Address
  final String? address;
  final String? village;
  final String? city;
  final String? district;
  final String? state;
  final String? pinCode;

  // Relationship & Notes
  final String? relationshipLabel;
  final String? relationshipNotes;
  final String? notes;

  // Professional & Metadata
  final String? occupation;
  final String? company;
  final List<String> tags;
  final String contactSource; // 'manual' or 'phone_import'
  final String? externalContactId;
  final DateTime? importedAt;
  final bool isAppEditedAfterImport;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Person({
    required this.id,
    this.familyId,
    required this.fullName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.nickname,
    this.gender,
    this.dateOfBirth,
    this.photoPath,
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
    this.relationshipLabel,
    this.relationshipNotes,
    this.notes,
    this.occupation,
    this.company,
    this.tags = const [],
    this.contactSource = 'manual',
    this.externalContactId,
    this.importedAt,
    this.isAppEditedAfterImport = false,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;
  bool get isPhoneImported => contactSource == 'phone_import';

  // Backward compatibility getters
  String get name => fullName;
  String? get phone => phoneNumber;
  String? get relationship => relationshipLabel;

  String get displayName => (nickname != null && nickname!.trim().isNotEmpty)
      ? '$fullName ($nickname)'
      : fullName;

  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'व्य';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final p1 = parts[0].isNotEmpty ? parts[0].characters.first : '';
      final p2 = parts[1].isNotEmpty ? parts[1].characters.first : '';
      return '$p1$p2';
    }
    return trimmed.characters.take(2).toString();
  }

  String? get primaryOrAnyPhone {
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      return phoneNumber!.trim();
    }
    if (secondaryPhones.isNotEmpty && secondaryPhones.first.trim().isNotEmpty) {
      return secondaryPhones.first.trim();
    }
    return null;
  }

  List<String> get allPhoneNumbers {
    final list = <String>[];
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      list.add(phoneNumber!.trim());
    }
    for (final p in secondaryPhones) {
      final trimmed = p.trim();
      if (trimmed.isNotEmpty && !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    return list;
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.trim().isNotEmpty) parts.add(address!.trim());
    if (village != null && village!.trim().isNotEmpty && village != address) parts.add(village!.trim());
    if (city != null && city!.trim().isNotEmpty) parts.add(city!.trim());
    if (district != null && district!.trim().isNotEmpty) parts.add(district!.trim());
    if (state != null && state!.trim().isNotEmpty) parts.add(state!.trim());
    if (pinCode != null && pinCode!.trim().isNotEmpty) parts.add(pinCode!.trim());
    return parts.join(', ');
  }

  Person copyWith({
    String? id,
    String? familyId,
    String? fullName,
    String? firstName,
    String? middleName,
    String? lastName,
    String? nickname,
    String? gender,
    String? dateOfBirth,
    String? photoPath,
    String? phoneNumber,
    List<String>? secondaryPhones,
    String? whatsappNumber,
    List<String>? emails,
    String? address,
    String? village,
    String? city,
    String? district,
    String? state,
    String? pinCode,
    String? relationshipLabel,
    String? relationshipNotes,
    String? notes,
    String? occupation,
    String? company,
    List<String>? tags,
    String? contactSource,
    String? externalContactId,
    DateTime? importedAt,
    bool? isAppEditedAfterImport,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return Person(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoPath: photoPath ?? this.photoPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondaryPhones: secondaryPhones ?? this.secondaryPhones,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      emails: emails ?? this.emails,
      address: address ?? this.address,
      village: village ?? this.village,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      relationshipLabel: relationshipLabel ?? this.relationshipLabel,
      relationshipNotes: relationshipNotes ?? this.relationshipNotes,
      notes: notes ?? this.notes,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      tags: tags ?? this.tags,
      contactSource: contactSource ?? this.contactSource,
      externalContactId: externalContactId ?? this.externalContactId,
      importedAt: importedAt ?? this.importedAt,
      isAppEditedAfterImport: isAppEditedAfterImport ?? this.isAppEditedAfterImport,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

/// Normalized Secondary Phone record
class PersonPhone {
  final String id;
  final String personId;
  final String phoneNumber;
  final String? label;
  final bool isPrimary;

  const PersonPhone({
    required this.id,
    required this.personId,
    required this.phoneNumber,
    this.label,
    this.isPrimary = false,
  });
}

/// Normalized Email record
class PersonEmail {
  final String id;
  final String personId;
  final String email;
  final String? label;
  final bool isPrimary;

  const PersonEmail({
    required this.id,
    required this.personId,
    required this.email,
    this.label,
    this.isPrimary = false,
  });
}

/// Draft Contact representing a phone contact or vCard entry before database persistence
class ContactDraft {
  final String id;
  final String name;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? nickname;
  final List<String> phones;
  final List<String> emails;
  final String? address;
  final String? village;
  final String? city;
  final String? district;
  final String? state;
  final String? pinCode;
  final String? company;
  final String? jobTitle;
  final String? birthday;
  final String? photoPath;
  final String? externalId;
  final String source; // 'phone_contacts' or 'vcard_file'
  final String? notes;

  const ContactDraft({
    required this.id,
    required this.name,
    this.firstName,
    this.middleName,
    this.lastName,
    this.nickname,
    this.phones = const [],
    this.emails = const [],
    this.address,
    this.village,
    this.city,
    this.district,
    this.state,
    this.pinCode,
    this.company,
    this.jobTitle,
    this.birthday,
    this.photoPath,
    this.externalId,
    this.source = 'phone_contacts',
    this.notes,
  });

  String? get primaryPhone => phones.isNotEmpty ? phones.first : null;
  List<String> get secondaryPhones => phones.length > 1 ? phones.sublist(1) : const [];
}

/// Ceremonial Event Entity (सामाजिक व पारिवारिक कार्यक्रम)
class Event {
  final String id;
  final String title;
  final EventType eventType;
  final String? category;
  final String eventDate; // ISO Date YYYY-MM-DD
  final String? endDate; // ISO Date YYYY-MM-DD
  final String? startTime; // HH:mm
  final String? endTime; // HH:mm
  final bool isAllDay;
  final String? venue;
  final String? address;
  final String? villageCity;
  final String? landmark;
  final String? mapLink;
  final String? description;
  final String? notes;
  final EventStatus status;
  final EventPriority priority;
  final int? budgetEstimatedPaise;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  // Financial aggregates
  final int? totalReceivedPaise;
  final int? totalGivenPaise;
  final int? totalEntriesCount;

  // Sub-entities
  final List<EventFunction> functions;
  final List<EventParticipant> participants;
  final List<EventGuest> guests;
  final List<EventTask> tasks;
  final List<EventScheduleItem> schedule;
  final List<EventBudgetCategory> budgetCategories;
  final List<EventNote> notesList;
  final List<EventAttachment> attachments;
  final List<EventActivityLog> activityLogs;
  final List<EventReminder> reminders;

  const Event({
    required this.id,
    required this.title,
    required this.eventType,
    this.category,
    required this.eventDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.venue,
    this.address,
    this.villageCity,
    this.landmark,
    this.mapLink,
    this.description,
    this.notes,
    this.status = EventStatus.planned,
    this.priority = EventPriority.normal,
    this.budgetEstimatedPaise,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.totalReceivedPaise,
    this.totalGivenPaise,
    this.totalEntriesCount,
    this.functions = const [],
    this.participants = const [],
    this.guests = const [],
    this.tasks = const [],
    this.schedule = const [],
    this.budgetCategories = const [],
    this.notesList = const [],
    this.attachments = const [],
    this.activityLogs = const [],
    this.reminders = const [],
  });

  bool get isArchived => archivedAt != null;

  /// Returns custom category if specified by user, else default Hindi label
  String get displayTypeName {
    if (category != null && category!.trim().isNotEmpty) {
      return category!.trim();
    }
    return eventType.labelHindi;
  }

  // Backward compatibility aliases
  int? get totalMilaPaise => totalReceivedPaise;
  int? get totalDiyaPaise => totalGivenPaise;
  int get actualExpensePaise {
    if (budgetCategories.isNotEmpty) {
      return budgetCategories.fold<int>(0, (sum, c) => sum + c.actualAmountPaise);
    }
    return totalGivenPaise ?? 0;
  }
  int get remainingBudgetPaise => (budgetEstimatedPaise ?? 0) - actualExpensePaise;
  double get budgetUtilizationPercent =>
      (budgetEstimatedPaise != null && budgetEstimatedPaise! > 0)
          ? ((actualExpensePaise / budgetEstimatedPaise!) * 100).clamp(0.0, 500.0)
          : 0.0;

  int get completedTasksCount =>
      tasks.where((t) => t.status == TaskStatus.completed).length;
  double get taskCompletionPercentage =>
      tasks.isEmpty ? 0.0 : (completedTasksCount / tasks.length) * 100;

  int get totalGuestCount =>
      guests.fold<int>(0, (sum, g) => sum + 1 + g.accompanyingCount);
  int get confirmedGuestCount => guests
      .where((g) =>
          g.attendanceStatus == AttendanceStatus.attending ||
          g.attendanceStatus == AttendanceStatus.attended)
      .fold<int>(0, (sum, g) => sum + 1 + g.accompanyingCount);

  Event copyWith({
    String? id,
    String? title,
    EventType? eventType,
    String? category,
    String? eventDate,
    String? endDate,
    String? startTime,
    String? endTime,
    bool? isAllDay,
    String? venue,
    String? address,
    String? villageCity,
    String? landmark,
    String? mapLink,
    String? description,
    String? notes,
    EventStatus? status,
    EventPriority? priority,
    int? budgetEstimatedPaise,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    int? totalReceivedPaise,
    int? totalGivenPaise,
    int? totalEntriesCount,
    List<EventFunction>? functions,
    List<EventParticipant>? participants,
    List<EventGuest>? guests,
    List<EventTask>? tasks,
    List<EventScheduleItem>? schedule,
    List<EventBudgetCategory>? budgetCategories,
    List<EventNote>? notesList,
    List<EventAttachment>? attachments,
    List<EventActivityLog>? activityLogs,
    List<EventReminder>? reminders,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      venue: venue ?? this.venue,
      address: address ?? this.address,
      villageCity: villageCity ?? this.villageCity,
      landmark: landmark ?? this.landmark,
      mapLink: mapLink ?? this.mapLink,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      budgetEstimatedPaise: budgetEstimatedPaise ?? this.budgetEstimatedPaise,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      totalReceivedPaise: totalReceivedPaise ?? this.totalReceivedPaise,
      totalGivenPaise: totalGivenPaise ?? this.totalGivenPaise,
      totalEntriesCount: totalEntriesCount ?? this.totalEntriesCount,
      functions: functions ?? this.functions,
      participants: participants ?? this.participants,
      guests: guests ?? this.guests,
      tasks: tasks ?? this.tasks,
      schedule: schedule ?? this.schedule,
      budgetCategories: budgetCategories ?? this.budgetCategories,
      notesList: notesList ?? this.notesList,
      attachments: attachments ?? this.attachments,
      activityLogs: activityLogs ?? this.activityLogs,
      reminders: reminders ?? this.reminders,
    );
  }
}

/// Ceremony or sub-function under a parent event (e.g. Haldi, Mehndi, Reception)
class EventFunction {
  final String id;
  final String eventId;
  final String title;
  final String functionDate; // YYYY-MM-DD
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? description;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventFunction({
    required this.id,
    required this.eventId,
    required this.title,
    required this.functionDate,
    this.startTime,
    this.endTime,
    this.venue,
    this.description,
    this.status = EventStatus.planned,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// People associated with an event in specific roles
class EventParticipant {
  final String id;
  final String eventId;
  final String? personId;
  final String? familyId;
  final String name;
  final ParticipantRole role;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  const EventParticipant({
    required this.id,
    required this.eventId,
    this.personId,
    this.familyId,
    required this.name,
    this.role = ParticipantRole.other,
    this.phone,
    this.notes,
    required this.createdAt,
  });
}

/// Guest and RSVP management
class EventGuest {
  final String id;
  final String eventId;
  final String? personId;
  final String name;
  final String? familyOrGroup;
  final String? phoneNumber;
  final InvitationStatus invitationStatus;
  final AttendanceStatus attendanceStatus;
  final int accompanyingCount;
  final String? notes;
  final String? invitationDate;
  final DateTime createdAt;

  const EventGuest({
    required this.id,
    required this.eventId,
    this.personId,
    required this.name,
    this.familyOrGroup,
    this.phoneNumber,
    this.invitationStatus = InvitationStatus.notSent,
    this.attendanceStatus = AttendanceStatus.notConfirmed,
    this.accompanyingCount = 0,
    this.notes,
    this.invitationDate,
    required this.createdAt,
  });
}

/// Task & checklist items for planning
class EventTask {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final String? assignedPersonName;
  final String? dueDate;
  final EventPriority priority;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  const EventTask({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    this.assignedPersonName,
    this.dueDate,
    this.priority = EventPriority.normal,
    this.status = TaskStatus.pending,
    this.completedAt,
    required this.createdAt,
  });
}

/// Scheduled activities chronologically ordered
class EventScheduleItem {
  final String id;
  final String eventId;
  final String? functionId;
  final String title;
  final String activityDate;
  final String startTime;
  final int durationMinutes;
  final String? venue;
  final String? responsiblePerson;
  final String? description;
  final String status;
  final int sortOrder;

  const EventScheduleItem({
    required this.id,
    required this.eventId,
    this.functionId,
    required this.title,
    required this.activityDate,
    required this.startTime,
    this.durationMinutes = 60,
    this.venue,
    this.responsiblePerson,
    this.description,
    this.status = 'scheduled',
    this.sortOrder = 0,
  });
}

/// Budget categories for planning and tracking expenses
class EventBudgetCategory {
  final String id;
  final String eventId;
  final String categoryName;
  final int estimatedAmountPaise;
  final int actualAmountPaise;
  final String? notes;
  final DateTime createdAt;

  const EventBudgetCategory({
    required this.id,
    required this.eventId,
    required this.categoryName,
    this.estimatedAmountPaise = 0,
    this.actualAmountPaise = 0,
    this.notes,
    required this.createdAt,
  });

  int get differencePaise => estimatedAmountPaise - actualAmountPaise;
  bool get isOverBudget => actualAmountPaise > estimatedAmountPaise;
}

/// General event notes and instructions
class EventNote {
  final String id;
  final String eventId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventNote({
    required this.id,
    required this.eventId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Attached documents and images
class EventAttachment {
  final String id;
  final String eventId;
  final String fileName;
  final String filePath;
  final String? fileType;
  final int fileSizeBytes;
  final DateTime createdAt;

  const EventAttachment({
    required this.id,
    required this.eventId,
    required this.fileName,
    required this.filePath,
    this.fileType,
    this.fileSizeBytes = 0,
    required this.createdAt,
  });
}

/// Audit activity log for event history
class EventActivityLog {
  final String id;
  final String eventId;
  final String action;
  final String? details;
  final DateTime timestamp;

  const EventActivityLog({
    required this.id,
    required this.eventId,
    required this.action,
    this.details,
    required this.timestamp,
  });
}

/// Event-specific offline reminder
class EventReminder {
  final String id;
  final String eventId;
  final String title;
  final String reminderDate;
  final String? reminderTime;
  final String? preset;
  final bool isEnabled;
  final bool isCompleted;
  final DateTime createdAt;

  const EventReminder({
    required this.id,
    required this.eventId,
    required this.title,
    required this.reminderDate,
    this.reminderTime,
    this.preset,
    this.isEnabled = true,
    this.isCompleted = false,
    required this.createdAt,
  });
}

/// Physical Gift Item Entity (भेंट / सामान)
class EntryItem {
  final String id;
  final String entryId;
  final String itemName;
  final double quantity;
  final String? unit;
  final int? estimatedValuePaise; // Strictly separate from cash totals!
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EntryItem({
    required this.id,
    required this.entryId,
    required this.itemName,
    this.quantity = 1.0,
    this.unit = 'संख्या',
    this.estimatedValuePaise,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility alias
  String? get condition => notes;
}

/// Transaction Entry Entity (व्यवहार प्रविष्टि)
class TransactionEntry {
  final String id;
  final String personId;
  final String? eventId;
  final TransactionDirection direction; // 'given' | 'received'
  final TransactionType transactionType; // 'cash' | 'item' | 'cash_and_item'
  final TransactionStatus status; // 'planned' | 'recorded' | 'cancelled'
  final int? amountPaise; // Integer Paise (nullable for item-only entries)
  final String transactionDate; // ISO Date YYYY-MM-DD
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? recordedAt;
  final DateTime? cancelledAt;
  final DateTime? archivedAt;

  // Hydrated helper fields
  final String? personName;
  final String? personAddress;
  final String? personRelationship;
  final String? eventTitle;
  final String? eventDate;
  final List<EntryItem> items;

  const TransactionEntry({
    required this.id,
    required this.personId,
    this.eventId,
    required this.direction,
    this.transactionType = TransactionType.cash,
    this.status = TransactionStatus.recorded,
    this.amountPaise,
    required this.transactionDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.recordedAt,
    this.cancelledAt,
    this.archivedAt,
    this.personName,
    this.personAddress,
    this.personRelationship,
    this.eventTitle,
    this.eventDate,
    this.items = const [],
  });

  bool get isCompleted => status == TransactionStatus.recorded;
  bool get isPlanned => status == TransactionStatus.planned;
  bool get isCancelled => status == TransactionStatus.cancelled;
  bool get isArchived => archivedAt != null;

  /// Returns custom category if specified by user, else default Hindi label
  String get displayTypeName {
    if (category != null && category!.trim().isNotEmpty) {
      return category!.trim();
    }
    return eventType.labelHindi;
  }

  // Backward compatibility aliases
  int get cashAmountPaise => amountPaise ?? 0;
  String? get expectedDate => isPlanned ? transactionDate : null;
  DateTime? get deletedAt => archivedAt;
  String? get householdId => null;
  String? get personVillage => personAddress;
}

/// Reminder Entity (आगामी व्यवहार अनुस्मारक)
class Reminder {
  final String id;
  final String? entryId;
  final String reminderDate; // ISO Date YYYY-MM-DD
  final String title;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    this.entryId,
    required this.reminderDate,
    required this.title,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// App Setting Entity (अनुप्रयोग प्राथमिकताएं)
class AppSetting {
  final String key;
  final String value;
  final DateTime updatedAt;

  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
}

/// Dashboard Financial & Statistics Summary
class DashboardSummary {
  final int totalReceivedPaise;
  final int totalGivenPaise;
  final int totalEntries;
  final int totalPlannedEntries;
  final int totalEvents;
  final int totalPeople;
  final String? recentEventId;
  final String? recentEventTitle;
  final String? recentEventDate;

  const DashboardSummary({
    required this.totalReceivedPaise,
    required this.totalGivenPaise,
    required this.totalEntries,
    required this.totalPlannedEntries,
    required this.totalEvents,
    required this.totalPeople,
    this.recentEventId,
    this.recentEventTitle,
    this.recentEventDate,
  });

  // Backward compatibility aliases
  int get totalMilaPaise => totalReceivedPaise;
  int get totalDiyaPaise => totalGivenPaise;

  factory DashboardSummary.empty() => const DashboardSummary(
        totalReceivedPaise: 0,
        totalGivenPaise: 0,
        totalEntries: 0,
        totalPlannedEntries: 0,
        totalEvents: 0,
        totalPeople: 0,
      );
}
