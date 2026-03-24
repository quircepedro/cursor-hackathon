import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/debug_date_provider.dart';
import '../../../../core/services/journal_insight_storage.dart';
import '../../../goals/application/providers/goals_provider.dart';
import '../../data/repositories/api_recording_repository.dart';
import '../../domain/entities/insight_entity.dart';
import '../../domain/repositories/recording_repository.dart';

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
    this.transcript,
    this.insight,
    this.error,
  });

  final RecordingStatus status;
  final int durationSeconds;
  final String? audioFilePath;
  final String? recordingId;
  final String? transcript;
  final InsightEntity? insight;
  final String? error;

  bool get isRecording => status == RecordingStatus.recording;

  String get statusLabel => switch (status) {
        RecordingStatus.idle => 'Ready to record',
        RecordingStatus.recording => 'Recording...',
        RecordingStatus.stopped => 'Processing...',
        RecordingStatus.uploading => 'Uploading...',
        RecordingStatus.transcribing => 'Transcribing your voice...',
        RecordingStatus.analysing => 'Analysing your emotions...',
        RecordingStatus.generatingClip => 'Creating your clip...',
        RecordingStatus.complete => 'Done!',
        RecordingStatus.error => 'Something went wrong',
      };

  RecordingState copyWith({
    RecordingStatus? status,
    int? durationSeconds,
    String? audioFilePath,
    String? recordingId,
    String? transcript,
    InsightEntity? insight,
    String? error,
  }) =>
      RecordingState(
        status: status ?? this.status,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        audioFilePath: audioFilePath ?? this.audioFilePath,
        recordingId: recordingId ?? this.recordingId,
        transcript: transcript ?? this.transcript,
        insight: insight ?? this.insight,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => const RecordingState();

  RecordingRepository get _repo => ref.read(recordingRepositoryProvider);

  final _insightStorage = JournalInsightStorage();

  void _persistAlignmentSnapshot() {
    final insight = state.insight;
    if (insight == null) return;

    // Persist full insight for calendar/history view
    unawaited(_insightStorage.saveToday(insight));

    final snapshot = insight.toAlignmentHistorySnapshot();
    if (snapshot == null) return;
    unawaited(
      ref.read(goalsRepositoryProvider).appendAlignmentHistory(snapshot),
    );
  }

  void updateDuration(int seconds) =>
      state = state.copyWith(durationSeconds: seconds);

  /// Step 1: upload audio + wait for transcription only.
  /// Called from TranscriptionReviewScreen.
  Future<void> uploadAndTranscribe(String audioPath) async {
    state = state.copyWith(
      status: RecordingStatus.uploading,
      audioFilePath: audioPath,
    );

    try {
      final recordingId = await _repo.uploadAudio(audioPath);
      state = state.copyWith(
        status: RecordingStatus.transcribing,
        recordingId: recordingId,
      );

      // Poll until transcription is ready
      while (true) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final response = await _repo.getStatus(recordingId);

        // Keep polling while still in early stages
        if (response.status == 'PENDING' ||
            response.status == 'UPLOADING' ||
            response.status == 'TRANSCRIBING') {
          continue;
        }

        // Pipeline failed before transcription finished
        if (response.status == 'FAILED') {
          state = state.copyWith(
            status: RecordingStatus.error,
            error: 'Transcription failed. Please check your API key.',
          );
          return;
        }

        // Transcription is done (ANALYZING or COMPLETE)
        state = state.copyWith(
          status: RecordingStatus.analysing,
          transcript: response.transcript,
          insight: response.insight,
        );
        break;
      }
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Step 2: continue polling for analysis on an existing recordingId.
  /// Called from ProcessingScreen after user taps "Analyse".
  Future<void> continueAnalysis(String recordingId) async {
    state = state.copyWith(
      status: RecordingStatus.analysing,
      recordingId: recordingId,
    );

    try {
      while (true) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final response = await _repo.getStatus(recordingId);
        final mapped = _mapBackendStatus(response.status);

        state = state.copyWith(
          status: mapped,
          transcript: response.transcript ?? state.transcript,
          insight: response.insight,
        );

        if (response.isTerminal) break;
      }

      if (state.status != RecordingStatus.complete) {
        state = state.copyWith(
          status: RecordingStatus.error,
          error: 'Processing failed. Please try again.',
        );
      } else {
        _persistAlignmentSnapshot();
      }
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Full pipeline (upload → transcribe → analyse). Used when skipping review.
  Future<void> stopAndProcess(String audioPath) async {
    state = state.copyWith(
      status: RecordingStatus.uploading,
      audioFilePath: audioPath,
    );
    try {
      final recordingId = await _repo.uploadAudio(audioPath);
      state = state.copyWith(
        status: RecordingStatus.transcribing,
        recordingId: recordingId,
      );
      while (true) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final response = await _repo.getStatus(recordingId);
        final mapped = _mapBackendStatus(response.status);
        state = state.copyWith(
          status: mapped,
          transcript: response.transcript ?? state.transcript,
          insight: response.insight,
        );
        if (response.isTerminal) break;
      }
      if (state.status != RecordingStatus.complete) {
        state = state.copyWith(
          status: RecordingStatus.error,
          error: 'Processing failed. Please try again.',
        );
      } else {
        _persistAlignmentSnapshot();
      }
    } catch (e) {
      state = state.copyWith(
        status: RecordingStatus.error,
        error: e.toString(),
      );
    }
  }

  /// Tras analizar desde la revisión de transcripción (sin subir audio).
  void setAnalysedInsight(InsightEntity insight, {String? transcript}) {
    state = state.copyWith(
      status: RecordingStatus.complete,
      insight: insight,
      transcript: transcript ?? state.transcript,
    );
    _persistAlignmentSnapshot();
  }

  void setPendingServerAnalysis({
    required String recordingId,
    required String transcript,
  }) {
    state = state.copyWith(
      status: RecordingStatus.analysing,
      recordingId: recordingId,
      transcript: transcript,
    );
  }

  void reset() => state = const RecordingState();

  RecordingStatus _mapBackendStatus(String s) => switch (s) {
        'UPLOADING' => RecordingStatus.uploading,
        'TRANSCRIBING' => RecordingStatus.transcribing,
        'ANALYZING' => RecordingStatus.analysing,
        'GENERATING_CLIP' => RecordingStatus.generatingClip,
        'COMPLETE' => RecordingStatus.complete,
        _ => RecordingStatus.error,
      };
}

final recordingProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final offset = ref.watch(debugDateOffsetProvider);
  return ApiRecordingRepository(dio, debugOffset: offset);
});

// ─── Today Recording (server-based) ─────────────────────────────────────────

class TodayRecordingNotifier extends AsyncNotifier<TodayRecordingResponse?> {
  @override
  Future<TodayRecordingResponse?> build() async {
    // watch so that changing debugDateOffsetProvider auto-rebuilds this provider
    final repo = ref.watch(recordingRepositoryProvider);
    return repo.getTodayRecording();
  }

  /// Re-fetch from server. Keeps the previous value visible during load
  /// to avoid a flash of "no recording" while the request is in flight.
  Future<void> refresh() async {
    final previous = state;
    state = const AsyncValue<TodayRecordingResponse?>.loading()
        .copyWithPrevious(previous);
    state = await AsyncValue.guard(
      () => ref.read(recordingRepositoryProvider).getTodayRecording(),
    );
  }

  /// Optimistically mark that a recording exists for today (before server
  /// confirms COMPLETE). This avoids the "no recording" flash when returning
  /// to the home screen right after uploading.
  void markUploaded(String recordingId) {
    state = AsyncValue.data(
      TodayRecordingResponse(
        id: recordingId,
        status: 'UPLOADING',
      ),
    );
  }
}

final todayRecordingProvider =
    AsyncNotifierProvider<TodayRecordingNotifier, TodayRecordingResponse?>(
  TodayRecordingNotifier.new,
);

// ─── Streak ──────────────────────────────────────────────────────────────────

/// Calculates the current streak: consecutive days with a recording
/// ending at today (appNow). If today has no recording yet, the streak
/// counts backwards from yesterday.
final streakProvider = FutureProvider<int>((ref) async {
  // Re-compute when today's recording changes (new upload / delete)
  ref.watch(todayRecordingProvider);
  final repo = ref.read(recordingRepositoryProvider);

  final recordings = await repo.getRecordings();
  if (recordings.isEmpty) return 0;

  // Collect unique dates (normalised to midnight)
  final dates = recordings
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a)); // newest first

  final today = appNow();
  final todayNorm = DateTime(today.year, today.month, today.day);

  // Find starting point: today or yesterday
  DateTime cursor;
  if (dates.contains(todayNorm)) {
    cursor = todayNorm;
  } else {
    final yesterday = todayNorm.subtract(const Duration(days: 1));
    if (dates.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }
  }

  // Count consecutive days backwards
  int streak = 0;
  while (dates.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
});
