/// Base domain exception for व्यवहार (Vyavahaar)
class AppException implements Exception {
  final String messageHindi;
  final String? technicalDetails;
  final dynamic originalError;

  const AppException({
    required this.messageHindi,
    this.technicalDetails,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $messageHindi ($technicalDetails)';
}

class DatabaseException extends AppException {
  const DatabaseException({
    super.messageHindi = 'डेटाबेस में त्रुटि हुई। कृपया पुनः प्रयास करें।',
    super.technicalDetails,
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.messageHindi,
    super.technicalDetails,
  });
}

class SecurityException extends AppException {
  const SecurityException({
    super.messageHindi = 'पासवर्ड गलत है या बैकअप दूषित है।',
    super.technicalDetails,
    super.originalError,
  });
}
