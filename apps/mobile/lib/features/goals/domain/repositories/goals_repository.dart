import '../entities/goal_entity.dart';
import '../entities/alignment_history_entity.dart';

abstract class GoalsRepository {
  Future<List<GoalEntity>> getActiveGoals();
  Future<GoalEntity> createGoal(String title);
  Future<GoalEntity> updateGoal(String id, String title);
  Future<void> deleteGoal(String id);
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30});

  /// Persiste un punto en el historial de alineación (p. ej. tras un análisis).
  Future<void> appendAlignmentHistory(AlignmentHistoryEntry entry);
}
