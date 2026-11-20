import 'package:drift/drift.dart';
import '../../../domain/enums/transaction_enums.dart';

/// Type converter for TransactionStatus enum
class TransactionStatusConverter extends TypeConverter<TransactionStatus, String> {
  const TransactionStatusConverter();

  @override
  TransactionStatus fromSql(String fromDb) {
    return TransactionStatus.fromString(fromDb);
  }

  @override
  String toSql(TransactionStatus value) {
    return value.value;
  }
}
