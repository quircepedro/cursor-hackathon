import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votio_mobile/features/recording/application/providers/recording_provider.dart';

void main() {
  group('RecordingNotifier', () {
    test('initial status is idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(recordingProvider).status, RecordingStatus.idle);
    });

    test('startRecording changes status to recording', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingProvider.notifier).startRecording();
      expect(container.read(recordingProvider).status, RecordingStatus.recording);
    });

    test('reset returns to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recordingProvider.notifier).startRecording();
      container.read(recordingProvider.notifier).reset();
      expect(container.read(recordingProvider).status, RecordingStatus.idle);
    });
  });
}
