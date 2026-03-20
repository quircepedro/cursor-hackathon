import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum RecordingStatus {
  idle,
  recording,
  stopped,
  uploading,
  transcribing,
  analysing,
  generatingClip,
  complete,
  error,
}

class RecordingState {
  const RecordingState({
    this.status = RecordingStatus.idle,
    this.durationSeconds = 0,
    this.audioFilePath,
    this.recordingId,
    this.error,
  });

  final RecordingStatus status;
  final int durationSeconds;
  final String? audioFilePath;
  final String? recordingId;
  final String? error;

  bool get isRecording => status == RecordingStatus.recording;
  bool get isProcessing => switch (status) {
        RecordingStatus.uploading ||
        RecordingStatus.transcribing ||
        RecordingStatus.analysing ||
        RecordingStatus.generatingClip =>
          true,
        _ => false,
      };

  String get statusLabel => switch (status) {
        RecordingStatus.idle => 'Ready to record',
        RecordingStatus.recording => 'Recording...',
        RecordingStatus.stopped => 'Processing...',
        RecordingStatus.uploading => 'Uploading...',
        RecordingStatus.transcribing => 'Transcribing...',
        RecordingStatus.analysing => 'Analysing...',
        RecordingStatus.generatingClip => 'Creating your clip...',
        RecordingStatus.complete => 'Done!',
        RecordingStatus.error => 'Something went wrong',
      };

  RecordingState copyWith({
    RecordingStatus? status,
    int? durationSeconds,
    String? audioFilePath,
    String? recordingId,
    String? error,
  }) =>
      RecordingState(
        status: status ?? this.status,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        audioFilePath: audioFilePath ?? this.audioFilePath,
        recordingId: recordingId ?? this.recordingId,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => const RecordingState();

  void startRecording() {
    // TODO: call AudioService.startRecording()
    state = state.copyWith(status: RecordingStatus.recording, durationSeconds: 0);
  }

  void updateDuration(int seconds) {
    state = state.copyWith(durationSeconds: seconds);
  }

  Future<void> stopAndProcess() async {
    // TODO: call AudioService.stopRecording(), upload, track pipeline status
    state = state.copyWith(status: RecordingStatus.uploading);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(status: RecordingStatus.transcribing);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(status: RecordingStatus.analysing);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(status: RecordingStatus.generatingClip);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(status: RecordingStatus.complete);
  }

  void reset() => state = const RecordingState();
}

final recordingProvider = NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);
