import '../enums/transaction_enums.dart';

/// Household Entity (हमारा परिवार)
class Household {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Household({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Person Entity (रिश्तेदार या मित्र)
class Person {
  final String id;
  final String householdId;
  final String? familyId;
  final String name;
  final String? village;
  final String? relationship;
  final String? phone;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Person({
    required this.id,
    required this.householdId,
    this.familyId,
    required this.name,
    this.village,
    this.relationship,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Ceremonial Event Entity (शादी, मुंडन आदि)
class Event {
  final String id;
  final String householdId;
  final String title;
  final EventType eventType;
  final String eventDate; // YYYY-MM-DD
  final String? personId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? totalMilaPaise;
  final int? totalDiyaPaise;
  final int? totalEntriesCount;

  const Event({
    required this.id,
    required this.householdId,
    required this.title,
    required this.eventType,
    required this.eventDate,
    this.personId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.totalMilaPaise,
    this.totalDiyaPaise,
    this.totalEntriesCount,
  });
}

/// Physical Gift Item (भेंट / सामान)
class EntryItem {
  final String id;
  final String entryId;
  final String itemName;
  final double quantity;
  final String unit;
  final int? estimatedValuePaise; // Strictly separate from cash totals!
  final String? condition;
  final DateTime createdAt;

  const EntryItem({
    required this.id,
    required this.entryId,
    required this.itemName,
    this.quantity = 1.0,
    this.unit = 'संख्या',
    this.estimatedValuePaise,
    this.condition,
    required this.createdAt,
  });
}

/// Transaction Entry Entity (व्यवहार प्रविष्टि)
class TransactionEntry {
  final String id;
  final String householdId;
  final String eventId;
  final String personId;
  final TransactionDirection direction;
  final int cashAmountPaise; // Integer Paise (1 Rupee = 100 Paise)
  final TransactionStatus status; // 'planned' | 'recorded' | 'cancelled'
  final String? expectedDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? personName;
  final String? personVillage;
  final String? personRelationship;
  final String? eventTitle;
  final String? eventDate;
  final List<EntryItem> items;

  const TransactionEntry({
    required this.id,
    required this.householdId,
    required this.eventId,
    required this.personId,
    required this.direction,
    required this.cashAmountPaise,
    this.status = TransactionStatus.recorded,
    this.expectedDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.personName,
    this.personVillage,
    this.personRelationship,
    this.eventTitle,
    this.eventDate,
    this.items = const [],
  });

  bool get isCompleted => status == TransactionStatus.recorded;
  bool get isPlanned => status == TransactionStatus.planned;
  bool get isCancelled => status == TransactionStatus.cancelled;
}

/// Dashboard Financial & Statistics Summary
class DashboardSummary {
  final int totalMilaPaise;
  final int totalDiyaPaise;
  final int totalEntries;
  final int totalPlannedEntries;
  final int totalEvents;
  final int totalPeople;
  final String? recentEventId;
  final String? recentEventTitle;
  final String? recentEventDate;

  const DashboardSummary({
    required this.totalMilaPaise,
    required this.totalDiyaPaise,
    required this.totalEntries,
    required this.totalPlannedEntries,
    required this.totalEvents,
    required this.totalPeople,
    this.recentEventId,
    this.recentEventTitle,
    this.recentEventDate,
  });

  factory DashboardSummary.empty() => const DashboardSummary(
        totalMilaPaise: 0,
        totalDiyaPaise: 0,
        totalEntries: 0,
        totalPlannedEntries: 0,
        totalEvents: 0,
        totalPeople: 0,
      );
}
