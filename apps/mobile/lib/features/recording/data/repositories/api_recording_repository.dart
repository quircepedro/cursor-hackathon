import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../../../core/providers/debug_date_provider.dart';
import '../../../goals/domain/entities/goal_entity.dart';
import '../../domain/entities/insight_entity.dart';
import '../../domain/entities/recording_entry_entity.dart';
import '../../domain/repositories/recording_repository.dart';

class ApiRecordingRepository implements RecordingRepository {
  const ApiRecordingRepository(this._dio, {this.debugOffset = 0});

  final Dio _dio;
  final int debugOffset;

  /// Real timezone offset (always the same regardless of debug).
  int get _tzOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  /// When debug offset is active, send the simulated date as ISO string.
  String? get _referenceDate =>
      debugOffset != 0 ? appNow().toUtc().toIso8601String() : null;

  @override
  Future<String> uploadAudio(
    String filePath, {
    String transcript = '',
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final defaultFileName = filePath.split('/').last;
    final bytes = fileBytes ?? await _maybeReadBytesFromWebBlob(filePath);
    final formData = FormData.fromMap({
      'audio': bytes != null
          ? MultipartFile.fromBytes(
              bytes,
              filename: fileName ?? defaultFileName,
            )
          : await MultipartFile.fromFile(
              filePath,
              filename: fileName ?? defaultFileName,
            ),
      if (transcript.isNotEmpty) 'transcript': transcript,
      'tzOffsetMinutes': _tzOffsetMinutes.toString(),
      if (_referenceDate != null) 'referenceDate': _referenceDate,
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
  Future<List<RecordingEntryEntity>> getRecordings() async {
    final response = await _dio.get<Map<String, dynamic>>('/audio');
    final raw = response.data!;
    final List<dynamic> list =
        raw['data'] is List ? raw['data'] as List<dynamic> : [];
    return list
        .map((e) => RecordingEntryEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TodayRecordingResponse?> getTodayRecording() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/audio/today',
      queryParameters: {
        'tzOffsetMinutes': _tzOffsetMinutes,
        if (_referenceDate != null) 'referenceDate': _referenceDate,
      },
    );
    final raw = response.data!;
    final dynamic data = raw['data'];
    if (data == null) return null;
    final body = data as Map<String, dynamic>;
    final insightRaw = body['insight'] as Map<String, dynamic>?;
    return TodayRecordingResponse(
      id: body['id'] as String,
      status: body['status'] as String,
      audioStreamUrl: body['audioStreamUrl'] as String?,
      insight: insightRaw != null ? InsightEntity.fromJson(insightRaw) : null,
    );
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
      data: {'transcript': transcript},
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final body = _unwrap(response.data!);
    return InsightEntity.fromAnalysisApi(body, goals: goals);
  }

  @override
  Future<bool> deleteTodayRecording() async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '/audio/today',
      queryParameters: {
        'tzOffsetMinutes': _tzOffsetMinutes,
        if (_referenceDate != null) 'referenceDate': _referenceDate,
      },
    );
    final body = _unwrap(response.data!);
    return body['deleted'] == true;
  }

  // The backend wraps responses in { success: true, data: { ... } }
  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  Future<List<int>?> _maybeReadBytesFromWebBlob(String path) async {
    // On web, record can return "blob:*" URLs that must be uploaded as bytes.
    if (!path.startsWith('blob:')) return null;
    final response = await http.get(Uri.parse(path));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw StateError('No se pudo leer el audio temporal del navegador');
  }
}
