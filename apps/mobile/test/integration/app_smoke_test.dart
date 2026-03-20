import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/recording/application/providers/recording_provider.dart';

/// Smoke tests — validate core state logic without platform channels or dotenv.
void main() {
  group('App smoke tests', () {
    test('AuthState default is unknown', () {
      const state = AuthState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, isFalse);
    });

    test('AuthState authenticated flag works', () {
      const state = AuthState(status: AuthStatus.authenticated, userId: 'u1');
      expect(state.isAuthenticated, isTrue);
    });

    test('RecordingState pipeline transitions are correct', () {
      const idle = RecordingState();
      final recording = idle.copyWith(status: RecordingStatus.recording);
      final uploading = recording.copyWith(status: RecordingStatus.uploading);

      expect(idle.isRecording, isFalse);
      expect(idle.isProcessing, isFalse);
      expect(recording.isRecording, isTrue);
      expect(uploading.isProcessing, isTrue);
    });

    test('All RecordingStatus values have non-empty statusLabel', () {
      for (final status in RecordingStatus.values) {
        final state = RecordingState(status: status);
        expect(state.statusLabel, isNotEmpty, reason: 'Status $status has empty label');
      }
    });
  });
}
