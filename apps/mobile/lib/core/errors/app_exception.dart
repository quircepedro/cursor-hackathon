/// Thrown by data layer when something goes wrong.
/// Converted to [Failure] at the repository boundary.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']) : super(code: 'NETWORK_ERROR');
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']) : super(code: 'UNAUTHORIZED');
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error']) : super(code: 'SERVER_ERROR');
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'No encontrado']) : super(code: 'NOT_FOUND');
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']) : super(code: 'CACHE_ERROR');
}
