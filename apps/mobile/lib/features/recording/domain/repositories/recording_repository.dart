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

abstract class RecordingRepository {
  Future<String> uploadAudio(String filePath);
  Future<RecordingStatusResponse> getStatus(String recordingId);
  Future<List<RecordingEntryEntity>> getRecordings();

  /// Analiza el transcript con la IA (emociones + alineación con objetivos).
  Future<InsightEntity> analyseJournal(
    String transcript, {
    required List<GoalEntity> goals,
  });
}
