import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/api_goals_repository.dart';
import '../../domain/entities/goal_entity.dart';
import '../../domain/repositories/goals_repository.dart';

// Repository provider
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiGoalsRepository(dio);
});

// Goals state
enum GoalsStatus { loading, hasGoals, noGoals, error }

class GoalsState {
  const GoalsState({
    this.status = GoalsStatus.loading,
    this.goals = const [],
    this.error,
  });

  final GoalsStatus status;
  final List<GoalEntity> goals;
  final String? error;

  GoalsState copyWith({
    GoalsStatus? status,
    List<GoalEntity>? goals,
    String? error,
  }) =>
      GoalsState(
        status: status ?? this.status,
        goals: goals ?? this.goals,
        error: error,
      );
}

class GoalsNotifier extends Notifier<GoalsState> {
  @override
  GoalsState build() => const GoalsState(status: GoalsStatus.loading);

  GoalsRepository get _repo => ref.read(goalsRepositoryProvider);

  Future<void> loadGoals() async {
    state = state.copyWith(status: GoalsStatus.loading);
    try {
      final goals = await _repo.getActiveGoals();
      state = GoalsState(
        status: goals.isEmpty ? GoalsStatus.noGoals : GoalsStatus.hasGoals,
        goals: goals,
      );
    } catch (e) {
      state = GoalsState(status: GoalsStatus.error, error: e.toString());
    }
  }

  Future<void> addGoal(String title) async {
    final goal = await _repo.createGoal(title);
    final updated = [...state.goals, goal];
    state = GoalsState(status: GoalsStatus.hasGoals, goals: updated);
  }

  Future<void> updateGoal(String id, String title) async {
    final updated = await _repo.updateGoal(id, title);
    final goals = state.goals.map((g) => g.id == id ? updated : g).toList();
    state = state.copyWith(goals: goals);
  }

  Future<void> removeGoal(String id) async {
    await _repo.deleteGoal(id);
    final goals = state.goals.where((g) => g.id != id).toList();
    state = GoalsState(
      status: goals.isEmpty ? GoalsStatus.noGoals : GoalsStatus.hasGoals,
      goals: goals,
    );
  }
}

final goalsProvider =
    NotifierProvider<GoalsNotifier, GoalsState>(GoalsNotifier.new);
