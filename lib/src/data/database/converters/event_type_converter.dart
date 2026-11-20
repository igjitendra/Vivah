import 'package:drift/drift.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Type converter for EventType enum
class EventTypeConverter extends TypeConverter<EventType, String> {
  const EventTypeConverter();

  @override
  EventType fromSql(String fromDb) {
    return EventType.fromString(fromDb);
  }

  @override
  String toSql(EventType value) {
    return value.labelHindi;
  }
}
