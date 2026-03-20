import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/core/errors/failure.dart';

void main() {
  group('Failure', () {
    test('NetworkFailure has correct default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'Network error occurred');
    });

    test('AuthFailure has correct default message', () {
      const failure = AuthFailure();
      expect(failure.message, 'Authentication required');
    });

    test('ValidationFailure preserves custom message', () {
      const failure = ValidationFailure('Email is invalid');
      expect(failure.message, 'Email is invalid');
    });

    test('Failures with same message and type are equal', () {
      const a = NetworkFailure();
      const b = NetworkFailure();
      expect(a, equals(b));
    });

    test('Different failure types are not equal', () {
      const a = NetworkFailure();
      const b = ServerFailure();
      expect(a, isNot(equals(b)));
    });
  });
}
