/// Direction of transaction from the app owner's family perspective.
/// - given: money or items given by the user's family to the person (दिया)
/// - received: money or items received by the user's family from the person (मिला)
enum TransactionDirection {
  received('received', 'मिला'),
  given('given', 'दिया');

  final String value;
  final String labelHindi;
  const TransactionDirection(this.value, this.labelHindi);

  /// Convenient aliases for Hindi cultural terms
  static const TransactionDirection mila = TransactionDirection.received;
  static const TransactionDirection diya = TransactionDirection.given;

  static TransactionDirection fromString(String val) {
    val = val.trim().toLowerCase();
    if (val == 'given' || val == 'diya') {
      return TransactionDirection.given;
    }
    return TransactionDirection.received;
  }
}

/// Transaction type: cash only, physical gift item only, or both
enum TransactionType {
  cash('cash', 'नकद'),
  item('item', 'भेंट/सामान'),
  cashAndItem('cash_and_item', 'नकद और भेंट');

  final String value;
  final String labelHindi;
  const TransactionType(this.value, this.labelHindi);

  static TransactionType fromString(String val) {
    return switch (val.trim().toLowerCase()) {
      'item' => TransactionType.item,
      'cash_and_item' => TransactionType.cashAndItem,
      _ => TransactionType.cash,
    };
  }
}

/// Status of transaction
enum TransactionStatus {
  planned('planned', 'योजना'),
  recorded('recorded', 'दर्ज'),
  cancelled('cancelled', 'रद्द');

  final String value;
  final String labelHindi;
  const TransactionStatus(this.value, this.labelHindi);

  static TransactionStatus fromString(String val) {
    return switch (val.trim().toLowerCase()) {
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
  String get displayName => labelHindi;
  const EventType(this.labelHindi);

  static EventType fromString(String val) {
    for (final e in EventType.values) {
      if (e.labelHindi == val || e.name.toLowerCase() == val.toLowerCase()) return e;
    }
    return EventType.other;
  }
}
