import 'package:dio/dio.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/alignment_history_entity.dart';
import '../../domain/repositories/goals_repository.dart';

class ApiGoalsRepository implements GoalsRepository {
  const ApiGoalsRepository(this._dio);
  final Dio _dio;

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    if (response.containsKey('data') && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }
    return response;
  }

  @override
  Future<List<GoalEntity>> getActiveGoals() async {
    final response = await _dio.get<Map<String, dynamic>>('/goals');
    final data = response.data!;
    // Backend wraps in { success, data } — data is the array
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => GoalEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GoalEntity> createGoal(String title) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/goals',
      data: {'title': title},
    );
    return GoalEntity.fromJson(_unwrap(response.data!));
  }

  @override
  Future<GoalEntity> updateGoal(String id, String title) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/goals/$id',
      data: {'title': title},
    );
    return GoalEntity.fromJson(_unwrap(response.data!));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _dio.delete('/goals/$id');
  }

  @override
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/goals/alignment/history',
      queryParameters: {'days': days},
    );
    final data = response.data!;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AlignmentHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
