import 'package:dio/dio.dart';

import '../../../goals/domain/entities/goal_entity.dart';
import '../../domain/entities/insight_entity.dart';
import '../../domain/repositories/recording_repository.dart';

class ApiRecordingRepository implements RecordingRepository {
  const ApiRecordingRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> uploadAudio(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/audio/upload',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    final body = _unwrap(response.data!);
    return body['id'] as String;
  }

  @override
  Future<RecordingStatusResponse> getStatus(String recordingId) async {
    final response = await _dio.get<Map<String, dynamic>>('/audio/$recordingId');
    final body = _unwrap(response.data!);

    final insightRaw = body['insight'] as Map<String, dynamic>?;
    final transcriptionRaw = body['transcription'] as Map<String, dynamic>?;
    return RecordingStatusResponse(
      id: body['id'] as String,
      status: body['status'] as String,
      transcript: transcriptionRaw?['text'] as String?,
      insight: insightRaw != null ? InsightEntity.fromJson(insightRaw) : null,
    );
  }

  @override
  Future<InsightEntity> analyseJournal(
    String transcript, {
    required List<GoalEntity> goals,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/analysis/journal',
      data: {
        'transcript': transcript,
        'goals': [
          for (final g in goals) {'title': g.title},
        ],
      },
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final body = _unwrap(response.data!);
    return InsightEntity.fromAnalysisApi(body, goals: goals);
  }

  // The backend wraps responses in { success: true, data: { ... } }
  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }
}
