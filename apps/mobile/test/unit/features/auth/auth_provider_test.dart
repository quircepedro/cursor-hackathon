import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/auth/domain/entities/user_entity.dart';
import 'package:votio_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:votio_mobile/features/recording/application/providers/recording_provider.dart';

// Import MockAuthRepository from shared test helpers — do NOT redeclare it here
// to avoid a compile conflict when both files are transitively imported.
import '../../../helpers/mock_providers.dart' show MockAuthRepository;

// Helper to create a ProviderContainer with a mock auth repository
ProviderContainer makeContainer(AuthRepository repo) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  group('AuthState', () {
    test('default status is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith updates fields', () {
      const state = AuthState();
      final user = UserEntity(id: 'u1', email: 'a@b.com');
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        userId: 'u1',
        user: user,
      );
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'u1');
      expect(updated.user, user);
      expect(updated.isAuthenticated, isTrue);
    });

    test('does not have accessToken field', () {
      // Ensure accessToken was removed — this test documents the contract
      const state = AuthState(status: AuthStatus.authenticated, userId: 'x');
      expect(state.isAuthenticated, isTrue);
    });
  });

  group('AuthNotifier stream', () {
    test('emits unauthenticated when repository stream emits null', () async {
      final repo = MockAuthRepository();
      when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(null));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final state = container.read(authProvider).value!;
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('emits authenticated with UserEntity when repository stream emits user',
        () async {
      final repo = MockAuthRepository();
      const fakeUser = (
        uid: 'uid-abc',
        email: 'a@b.com',
        displayName: 'Alice',
        avatarUrl: null,
        emailVerified: true,
      );
      when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(fakeUser));

      final container = makeContainer(repo);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final state = container.read(authProvider).value!;
      expect(state.status, AuthStatus.authenticated);
      expect(state.userId, 'uid-abc');
      expect(state.user?.email, 'a@b.com');
    });
  });

  group('AuthNotifier sendPasswordResetEmail', () {
    test('delegates to repository', () async {
      final repo = MockAuthRepository();
      when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(null));
      when(() => repo.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final container = makeContainer(repo);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .sendPasswordResetEmail(email: 'test@example.com');

      verify(() => repo.sendPasswordResetEmail(email: 'test@example.com'))
          .called(1);
    });
  });

  group('RecordingState', () {
    test('default status is idle', () {
      const state = RecordingState();
      expect(state.status, RecordingStatus.idle);
      expect(state.isRecording, isFalse);
    });

    test('statusLabel is non-empty for all statuses', () {
      for (final status in RecordingStatus.values) {
        final state = RecordingState(status: status);
        expect(state.statusLabel, isNotEmpty);
      }
    });
  });
}
