/// Direction of transaction
enum TransactionDirection {
  mila('mila', 'मिला'),
  diya('diya', 'दिया');

  final String value;
  final String labelHindi;
  const TransactionDirection(this.value, this.labelHindi);

  static TransactionDirection fromString(String val) {
    return val == 'diya' ? TransactionDirection.diya : TransactionDirection.mila;
  }
}

/// Status of transaction
enum TransactionStatus {
  recorded('recorded', 'दर्ज किया गया'),
  planned('planned', 'योजना'),
  cancelled('cancelled', 'रद्द');

  final String value;
  final String labelHindi;
  const TransactionStatus(this.value, this.labelHindi);

  static TransactionStatus fromString(String val) {
    return switch (val) {
      'planned' => TransactionStatus.planned,
      'cancelled' => TransactionStatus.cancelled,
      _ => TransactionStatus.recorded,
    };
  }
}

/// Types of cultural events
enum EventType {
  shaadi('शादी'),
  tilak('तिलक'),
  mundan('मुंडन'),
  baraat('बरात'),
  sagai('सगाई'),
  anniversary('वर्षगांठ'),
  grihaPravesh('गृह प्रवेश'),
  other('अन्य');

  final String labelHindi;
  const EventType(this.labelHindi);

  static EventType fromString(String val) {
    for (final e in EventType.values) {
      if (e.labelHindi == val) return e;
    }
    return EventType.other;
  }
}
