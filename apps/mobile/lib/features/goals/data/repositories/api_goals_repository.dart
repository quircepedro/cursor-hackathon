import 'package:dio/dio.dart';

import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/alignment_history_entity.dart';
import '../../domain/repositories/goals_repository.dart';

/// Goals repository backed by the backend API.
/// Goals are stored server-side so the analysis service can access them.
class ApiGoalsRepository implements GoalsRepository {
  const ApiGoalsRepository(this._dio);

  final Dio _dio;

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  List<dynamic> _unwrapList(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }
    return [];
  }

  @override
  Future<List<GoalEntity>> getActiveGoals() async {
    final response = await _dio.get<Map<String, dynamic>>('/goals');
    final list = _unwrapList(response.data!);
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) GoalEntity.fromJson(item)
        else if (item is Map) GoalEntity.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<GoalEntity> createGoal(String title) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: {'title': title.trim()},
    );
    final body = _unwrap(response.data!);
    return GoalEntity.fromJson(body);
  }

  @override
  Future<GoalEntity> updateGoal(String id, String title) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/goals/$id',
      data: {'title': title.trim()},
    );
    final body = _unwrap(response.data!);
    return GoalEntity.fromJson(body);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _dio.delete<Map<String, dynamic>>('/goals/$id');
  }

  @override
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/goals/alignment/history',
      queryParameters: {'days': days},
    );
    final list = _unwrapList(response.data!);
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          AlignmentHistoryEntry.fromJson(item)
        else if (item is Map)
          AlignmentHistoryEntry.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> appendAlignmentHistory(AlignmentHistoryEntry entry) async {
    // History is managed server-side via GoalAlignment records.
    // No-op: the backend appends history automatically when analysis completes.
  }
}
