/**
 * Base class for all domain-level exceptions.
 * Domain exceptions are thrown by business logic and caught by the global exception filter,
 * which maps them to appropriate HTTP responses.
 */
export abstract class DomainException extends Error {
  /**
   * HTTP status code for this exception.
   */
  abstract readonly statusCode: number;

  /**
   * Machine-readable error code.
   */
  abstract readonly code: string;

  constructor(message: string) {
    super(message);
    Object.setPrototypeOf(this, DomainException.prototype);
  }
}

/**
 * Thrown when a requested recording is not found.
 */
export class RecordingNotFoundException extends DomainException {
  readonly statusCode = 404;
  readonly code = 'RECORDING_NOT_FOUND';

  constructor(recordingId: string) {
    super(`Recording with ID ${recordingId} not found`);
    Object.setPrototypeOf(this, RecordingNotFoundException.prototype);
  }
}

/**
 * Thrown when an audio file exceeds the maximum allowed size.
 */
export class AudioTooLargeException extends DomainException {
  readonly statusCode = 413;
  readonly code = 'AUDIO_TOO_LARGE';

  constructor(size: number, maxSize: number) {
    super(
      `Audio file size (${size} bytes) exceeds maximum allowed size (${maxSize} bytes)`,
    );
    Object.setPrototypeOf(this, AudioTooLargeException.prototype);
  }
}

/**
 * Thrown when authentication credentials are invalid.
 */
export class InvalidCredentialsException extends DomainException {
  readonly statusCode = 401;
  readonly code = 'INVALID_CREDENTIALS';

  constructor() {
    super('Invalid email or password');
    Object.setPrototypeOf(this, InvalidCredentialsException.prototype);
  }
}

/**
 * Thrown when a user attempts to register with an email that already exists.
 */
export class EmailAlreadyExistsException extends DomainException {
  readonly statusCode = 409;
  readonly code = 'EMAIL_ALREADY_EXISTS';

  constructor(email: string) {
    super(`A user with email ${email} already exists`);
    Object.setPrototypeOf(this, EmailAlreadyExistsException.prototype);
  }
}

/**
 * Thrown when a user is not found.
 */
export class UserNotFoundException extends DomainException {
  readonly statusCode = 404;
  readonly code = 'USER_NOT_FOUND';

  constructor(userId: string) {
    super(`User with ID ${userId} not found`);
    Object.setPrototypeOf(this, UserNotFoundException.prototype);
  }
}

/**
 * Thrown when an operation fails due to invalid input.
 */
export class ValidationException extends DomainException {
  readonly statusCode = 400;
  readonly code = 'VALIDATION_ERROR';

  constructor(message: string) {
    super(message);
    Object.setPrototypeOf(this, ValidationException.prototype);
  }
}

/**
 * Thrown when an operation is not allowed (e.g., unauthorized action).
 */
export class UnauthorizedException extends DomainException {
  readonly statusCode = 403;
  readonly code = 'UNAUTHORIZED';

  constructor(message: string = 'Operation not allowed') {
    super(message);
    Object.setPrototypeOf(this, UnauthorizedException.prototype);
  }
}
