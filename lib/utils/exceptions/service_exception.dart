enum ServiceErrorCode {
  unknown,
  network,
  authentication,
  authorization,
  notFound,
  serverError,
  validation,
  // Add auth-specific error codes
  invalidCredentials,
  emailInUse,
  providerError,
  userCancelled
}

enum AuthProvider { email, google, github }

class ServiceException implements Exception {
  final String message;
  final ServiceErrorCode code;
  final dynamic originalError;
  final AuthProvider? provider;

  const ServiceException(
    this.message, {
    this.code = ServiceErrorCode.unknown,
    this.originalError,
    this.provider,
  });

  bool get isAuthError =>
      code == ServiceErrorCode.authentication ||
      code == ServiceErrorCode.authorization ||
      code == ServiceErrorCode.invalidCredentials;

  @override
  String toString() => 'ServiceException: $message';

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code.toString(),
        'provider': provider?.toString(),
        'originalError': originalError?.toString(),
      };
}
