/// Gateway error body: `{ "status", "code", "message" }` (API_REFERENCE.md).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;

  /// Stable machine code, e.g. `TOKEN_EXPIRED`, `INVALID_CREDENTIALS`.
  final String? code;

  bool get isTokenExpired => code == 'TOKEN_EXPIRED';
  bool get isTokenInvalid => code == 'TOKEN_INVALID';
  bool get isInvalidCredentials => code == 'INVALID_CREDENTIALS';
  bool get isAccountDisabled => code == 'ACCOUNT_DISABLED';
  bool get isAccessDenied => code == 'ACCESS_DENIED';
  bool get isEmailExists => code == 'EMAIL_ALREADY_EXISTS';
  bool get isValidation => code == 'VALIDATION_ERROR';

  /// User-facing copy preferred over raw `message` where the guide specifies it.
  String get displayMessage {
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return 'Email or password is wrong';
      case 'ACCOUNT_DISABLED':
        return 'This account is disabled';
      case 'ACCESS_DENIED':
        return 'You are not allowed to do that';
      case 'EMAIL_ALREADY_EXISTS':
        return 'Email already registered';
      case 'STORE_CODE_EXISTS':
        return 'Store code already used';
      case 'TOKEN_EXPIRED':
        return 'Session expired';
      case 'TOKEN_INVALID':
        return 'Please sign in again';
      case 'NOT_FOUND':
        return 'Not found';
      case 'INTERNAL_ERROR':
        return 'Something went wrong. Please try again';
      default:
        return message;
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
