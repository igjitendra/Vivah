/// Generic Result monad for clean, exception-free functional error handling
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String messageHindi, [String? technicalDetails]) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        Failure<T>() => null,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(String messageHindi, String? details) failure,
  }) =>
      switch (this) {
        Success<T>(data: final d) => success(d),
        Failure<T>(messageHindi: final m, technicalDetails: final det) => failure(m, det),
      };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final String messageHindi;
  final String? technicalDetails;
  const Failure(this.messageHindi, [this.technicalDetails]);
}
