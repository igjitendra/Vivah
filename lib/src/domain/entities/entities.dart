import '../enums/transaction_enums.dart';

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
  final String? phoneNumber;
  final String? relationshipLabel;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  const Person({
    required this.id,
    this.familyId,
    required this.fullName,
    this.phoneNumber,
    this.relationshipLabel,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  bool get isArchived => archivedAt != null;

  // Backward compatibility getters
  String get name => fullName;
  String? get phone => phoneNumber;
  String? get village => address;
  String? get relationship => relationshipLabel;
}

/// Ceremonial Event Entity (सामाजिक व पारिवारिक कार्यक्रम)
class Event {
  final String id;
  final String title;
  final EventType eventType;
  final String eventDate; // ISO Date YYYY-MM-DD
  final String? venue;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final int? totalReceivedPaise;
  final int? totalGivenPaise;
  final int? totalEntriesCount;

  const Event({
    required this.id,
    required this.title,
    required this.eventType,
    required this.eventDate,
    this.venue,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.totalReceivedPaise,
    this.totalGivenPaise,
    this.totalEntriesCount,
  });

  bool get isArchived => archivedAt != null;

  // Backward compatibility aliases
  int? get totalMilaPaise => totalReceivedPaise;
  int? get totalDiyaPaise => totalGivenPaise;
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
