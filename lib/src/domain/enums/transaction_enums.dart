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
  engagement('सगाई'),
  haldi('हल्दी'),
  mehndi('मेहंदी'),
  reception('प्रीतिभोज / रिसेप्शन'),
  birthday('जन्मदिन'),
  religiousCeremony('धार्मिक अनुष्ठान'),
  festival('त्योहार / पर्व'),
  familyGathering('पारिवारिक मिलन'),
  funeral('श्राद्ध / शोक सभा'),
  communityEvent('सामाजिक सम्मेलन'),
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

/// Lifecycle status for events
enum EventStatus {
  draft('ड्राफ़्ट', 'Draft'),
  planned('नियोजित', 'Planned'),
  confirmed('पुष्ट', 'Confirmed'),
  inProgress('प्रगति पर', 'In Progress'),
  completed('सम्पन्न', 'Completed'),
  cancelled('रद्द', 'Cancelled'),
  archived('संग्रहीत', 'Archived');

  final String labelHindi;
  final String labelEnglish;
  const EventStatus(this.labelHindi, this.labelEnglish);

  static EventStatus fromString(String? val) {
    if (val == null) return EventStatus.planned;
    for (final s in EventStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase() ||
          s.labelHindi == val ||
          s.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return EventStatus.planned;
  }
}

/// Priority rating for events and event tasks
enum EventPriority {
  low('कम', 'Low'),
  normal('मध्यम', 'Normal'),
  high('उच्च', 'High'),
  urgent('अति आवश्यक', 'Urgent');

  final String labelHindi;
  final String labelEnglish;
  const EventPriority(this.labelHindi, this.labelEnglish);

  static EventPriority fromString(String? val) {
    if (val == null) return EventPriority.normal;
    for (final p in EventPriority.values) {
      if (p.name.toLowerCase() == val.toLowerCase() ||
          p.labelHindi == val ||
          p.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return p;
      }
    }
    return EventPriority.normal;
  }
}

/// Role assigned to a participant in an event
enum ParticipantRole {
  host('मेजबान', 'Host'),
  organizer('आयोजक', 'Organizer'),
  bride('दुल्हन', 'Bride'),
  groom('दूल्हा', 'Groom'),
  guestOfHonour('विशिष्ट अतिथि', 'Guest of Honour'),
  familyMember('पारिवारिक सदस्य', 'Family Member'),
  other('अन्य', 'Other');

  final String labelHindi;
  final String labelEnglish;
  const ParticipantRole(this.labelHindi, this.labelEnglish);

  static ParticipantRole fromString(String? val) {
    if (val == null) return ParticipantRole.other;
    for (final r in ParticipantRole.values) {
      if (r.name.toLowerCase() == val.toLowerCase() ||
          r.labelHindi == val ||
          r.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return r;
      }
    }
    return ParticipantRole.other;
  }
}

/// Invitation status for event guests
enum InvitationStatus {
  notSent('नहीं भेजा', 'Not Sent'),
  sent('भेज दिया', 'Sent'),
  accepted('स्वीकार किया', 'Accepted'),
  declined('अस्वीकार', 'Declined'),
  maybe('संभावित', 'Maybe');

  final String labelHindi;
  final String labelEnglish;
  const InvitationStatus(this.labelHindi, this.labelEnglish);

  static InvitationStatus fromString(String? val) {
    if (val == null) return InvitationStatus.notSent;
    for (final s in InvitationStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase() ||
          s.labelHindi == val ||
          s.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return InvitationStatus.notSent;
  }
}

/// Actual attendance status for event guests
enum AttendanceStatus {
  notConfirmed('अपुष्ट', 'Not Confirmed'),
  attending('उपस्थित होंगे', 'Attending'),
  notAttending('नहीं आ सकेंगे', 'Not Attending'),
  attended('उपस्थित रहे', 'Attended');

  final String labelHindi;
  final String labelEnglish;
  const AttendanceStatus(this.labelHindi, this.labelEnglish);

  static AttendanceStatus fromString(String? val) {
    if (val == null) return AttendanceStatus.notConfirmed;
    for (final s in AttendanceStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase() ||
          s.labelHindi == val ||
          s.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return AttendanceStatus.notConfirmed;
  }
}

/// Status for event tasks and checklist items
enum TaskStatus {
  pending('लंबित', 'Pending'),
  inProgress('प्रगति पर', 'In Progress'),
  completed('पूर्ण', 'Completed'),
  cancelled('रद्द', 'Cancelled');

  final String labelHindi;
  final String labelEnglish;
  const TaskStatus(this.labelHindi, this.labelEnglish);

  static TaskStatus fromString(String? val) {
    if (val == null) return TaskStatus.pending;
    for (final s in TaskStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase() ||
          s.labelHindi == val ||
          s.labelEnglish.toLowerCase() == val.toLowerCase()) {
        return s;
      }
    }
    return TaskStatus.pending;
  }
}
