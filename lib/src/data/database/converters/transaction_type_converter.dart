import 'package:drift/drift.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Type converter for TransactionType enum
class TransactionTypeConverter extends TypeConverter<TransactionType, String> {
  const TransactionTypeConverter();

  @override
  TransactionType fromSql(String fromDb) {
    return TransactionType.fromString(fromDb);
  }

  @override
  String toSql(TransactionType value) {
    return value.value;
  }
}
