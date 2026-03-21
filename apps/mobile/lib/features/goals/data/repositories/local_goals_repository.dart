import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/goal_entity.dart';
import '../../domain/entities/alignment_history_entity.dart';
import '../../domain/repositories/goals_repository.dart';

/// Objetivos e historial de alineación en el dispositivo (sin API).
/// [scopeKey] suele ser el UID de Firebase para no mezclar cuentas.
class LocalGoalsRepository implements GoalsRepository {
  LocalGoalsRepository(this.scopeKey);

  final String scopeKey;
  static const _maxHistoryEntries = 500;

  String get _kGoals => 'votio_local_goals_v1_$scopeKey';
  String get _kHistory => 'votio_local_alignment_history_v1_$scopeKey';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _newGoalId() =>
      'local_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 30)}';

  Future<List<GoalEntity>> _readGoals() async {
    final raw = (await _prefs).getString(_kGoals);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list)
        if (e is Map<String, dynamic>)
          GoalEntity.fromJson(e)
        else if (e is Map)
          GoalEntity.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  Future<void> _writeGoals(List<GoalEntity> goals) async {
    final encoded =
        jsonEncode(goals.map((g) => g.toJson()).toList(growable: false));
    await (await _prefs).setString(_kGoals, encoded);
  }

  Future<List<AlignmentHistoryEntry>> _readHistory() async {
    final raw = (await _prefs).getString(_kHistory);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final out = <AlignmentHistoryEntry>[];
    for (final e in list) {
      if (e is! Map) continue;
      try {
        out.add(AlignmentHistoryEntry.fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {}
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  Future<void> _writeHistory(List<AlignmentHistoryEntry> entries) async {
    final trimmed = entries.length <= _maxHistoryEntries
        ? entries
        : entries.sublist(entries.length - _maxHistoryEntries);
    final encoded =
        jsonEncode(trimmed.map((e) => e.toJson()).toList(growable: false));
    await (await _prefs).setString(_kHistory, encoded);
  }

  @override
  Future<List<GoalEntity>> getActiveGoals() async {
    final all = await _readGoals();
    return all.where((g) => g.active).toList();
  }

  @override
  Future<GoalEntity> createGoal(String title) async {
    final goals = await _readGoals();
    final goal = GoalEntity(
      id: _newGoalId(),
      title: title.trim(),
      active: true,
    );
    await _writeGoals([...goals, goal]);
    return goal;
  }

  @override
  Future<GoalEntity> updateGoal(String id, String title) async {
    final goals = await _readGoals();
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx < 0) {
      throw StateError('Goal not found: $id');
    }
    final updated = GoalEntity(
      id: id,
      title: title.trim(),
      active: goals[idx].active,
    );
    final next = [...goals];
    next[idx] = updated;
    await _writeGoals(next);
    return updated;
  }

  @override
  Future<void> deleteGoal(String id) async {
    final goals = await _readGoals();
    await _writeGoals(goals.where((g) => g.id != id).toList());
  }

  @override
  Future<List<AlignmentHistoryEntry>> getAlignmentHistory({int days = 30}) async {
    final all = await _readHistory();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => !e.date.isBefore(cutoff)).toList();
  }

  @override
  Future<void> appendAlignmentHistory(AlignmentHistoryEntry entry) async {
    final all = await _readHistory();
    await _writeHistory([...all, entry]);
  }
}
