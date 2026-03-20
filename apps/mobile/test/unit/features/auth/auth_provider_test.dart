import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/recording/application/providers/recording_provider.dart';

void main() {
  group('AuthState', () {
    test('default status is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith updates fields', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        userId: 'u1',
      );
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.userId, 'u1');
      expect(updated.isAuthenticated, isTrue);
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
