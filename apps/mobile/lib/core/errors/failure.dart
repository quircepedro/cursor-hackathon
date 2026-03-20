import 'package:equatable/equatable.dart';

/// Base class for all domain failures.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Network-related failures (no connection, timeout, etc.)
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

/// Server returned an unexpected error (5xx)
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
  const ServerFailure.withMessage(super.message);
}

/// Request not authorized (401/403)
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required']);
}

/// Resource not found (404)
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

/// Input validation failure
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Local storage failure
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error']);
}

/// Unknown / unhandled failure
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred']);
}
