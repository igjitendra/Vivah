import 'package:drift/drift.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Type converter for TransactionDirection enum
class TransactionDirectionConverter extends TypeConverter<TransactionDirection, String> {
  const TransactionDirectionConverter();

  @override
  TransactionDirection fromSql(String fromDb) {
    return TransactionDirection.fromString(fromDb);
  }

  @override
  String toSql(TransactionDirection value) {
    return value.value;
  }
}
