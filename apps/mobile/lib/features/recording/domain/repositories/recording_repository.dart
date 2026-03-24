import '../../../goals/domain/entities/goal_entity.dart';
import '../entities/insight_entity.dart';
import '../entities/recording_entry_entity.dart';

class RecordingStatusResponse {
  const RecordingStatusResponse({
    required this.id,
    required this.status,
    this.transcript,
    this.insight,
  });

  final String id;
  final String status;
  final String? transcript;
  final InsightEntity? insight;

  bool get isTerminal => status == 'COMPLETE' || status == 'FAILED';
  bool get isComplete => status == 'COMPLETE';
}

class TodayRecordingResponse {
  const TodayRecordingResponse({
    required this.id,
    required this.status,
    this.audioStreamUrl,
    this.insight,
  });

  final String id;
  final String status;
  final String? audioStreamUrl;
  final InsightEntity? insight;

  bool get isComplete => status == 'COMPLETE';
}

abstract class RecordingRepository {
  Future<String> uploadAudio(String filePath, {String transcript});
  Future<RecordingStatusResponse> getStatus(String recordingId);
  Future<List<RecordingEntryEntity>> getRecordings();
  Future<TodayRecordingResponse?> getTodayRecording();

  /// Analiza el transcript con la IA (emociones + alineación con objetivos).
  Future<InsightEntity> analyseJournal(
    String transcript, {
    required List<GoalEntity> goals,
  });

  /// Borra la grabación del día actual (respetando debug offset).
  Future<bool> deleteTodayRecording();
}
