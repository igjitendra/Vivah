import 'package:drift/drift.dart';

/// App Settings table for storing user application preferences (theme, language, date format).
/// Part 6 Specification: key, value, updated_at.
/// Never stores passwords, secrets, or keys.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt =>
      text().named('updated_at').clientDefault(() => DateTime.now().toIso8601String())();

  @override
  Set<Column> get primaryKey => {key};
}
