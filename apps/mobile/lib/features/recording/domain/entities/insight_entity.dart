import '../../../goals/domain/entities/alignment_history_entity.dart';
import '../../../goals/domain/entities/goal_alignment_entity.dart';
import '../../../goals/domain/entities/goal_entity.dart';

class InsightEntity {
  const InsightEntity({
    required this.summary,
    required this.emotionScores,
    required this.keyThemes,
    required this.sentiment,
    this.suggestedActions,
    this.overallAlignment,
    this.goalAlignments = const [],
  });

  final String summary;
  final Map<String, double> emotionScores;
  final List<String> keyThemes;
  final String sentiment; // POSITIVE | NEUTRAL | NEGATIVE
  final List<Map<String, String>>? suggestedActions;
  final double? overallAlignment;
  final List<GoalAlignmentEntity> goalAlignments;

  /// Snapshot para historial local de alineación (sin goals no hay serie temporal).
  AlignmentHistoryEntry? toAlignmentHistorySnapshot() {
    if (goalAlignments.isEmpty) return null;
    double norm(double s) {
      if (s > 1.0) return (s / 100).clamp(0.0, 1.0);
      return s.clamp(0.0, 1.0);
    }

    final overall = overallAlignment != null ? norm(overallAlignment!) : 0.0;
    return AlignmentHistoryEntry(
      date: DateTime.now(),
      overallScore: overall,
      goals: [
        for (final a in goalAlignments)
          GoalScoreEntry(
            goalId: a.goalId,
            title: a.goalTitle,
            score: norm(a.score),
          ),
      ],
    );
  }

  /// The dominant emotion (highest score).
  String get dominantEmotion {
    if (emotionScores.isEmpty) return 'neutral';
    return emotionScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  factory InsightEntity.fromJson(Map<String, dynamic> json) {
    final rawScores = json['emotionScores'] as Map<String, dynamic>? ?? {};
    final rawThemes = json['keyThemes'] as List<dynamic>? ?? [];
    final rawActions = json['suggestedActions'] as List<dynamic>?;
    final rawAlignments = json['goalAlignments'] as List<dynamic>? ?? [];

    return InsightEntity(
      summary: json['summary'] as String? ?? '',
      emotionScores: rawScores.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      keyThemes: rawThemes.map((e) => e.toString()).toList(),
      sentiment: json['sentiment'] as String? ?? 'NEUTRAL',
      suggestedActions: rawActions
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList(),
      overallAlignment: (json['overallAlignment'] as num?)?.toDouble(),
      goalAlignments: rawAlignments
          .map((e) => GoalAlignmentEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Respuesta de `POST /analysis/journal` (emotion + goalAlignment por índice).
  factory InsightEntity.fromAnalysisApi(
    Map<String, dynamic> json, {
    required List<GoalEntity> goals,
  }) {
    final emotion = json['emotion'] as Map<String, dynamic>? ?? {};
    final goalAlignment = json['goalAlignment'] as Map<String, dynamic>? ?? {};
    final rawScores = emotion['emotionScores'] as Map<String, dynamic>? ?? {};
    final rawThemes = emotion['keyThemes'] as List<dynamic>? ?? [];
    final rawGoals = goalAlignment['goals'] as List<dynamic>? ?? [];

    final alignments = <GoalAlignmentEntity>[];
    for (final item in rawGoals) {
      final g = item as Map<String, dynamic>;
      final idx = (g['goalIndex'] as num?)?.toInt() ?? -1;
      if (idx < 0 || idx >= goals.length) continue;
      final goal = goals[idx];
      alignments.add(
        GoalAlignmentEntity(
          goalId: goal.id,
          goalTitle: goal.title,
          score: (g['score'] as num?)?.toDouble() ?? 0,
          level: AlignmentLevel.fromString(g['level'] as String? ?? ''),
          reason: g['reason'] as String? ?? '',
        ),
      );
    }

    return InsightEntity(
      summary: emotion['summary'] as String? ?? '',
      emotionScores: rawScores.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
      keyThemes: rawThemes.map((e) => e.toString()).toList(),
      sentiment: emotion['sentiment'] as String? ?? 'NEUTRAL',
      suggestedActions: null,
      overallAlignment:
          (goalAlignment['overallScore'] as num?)?.toDouble(),
      goalAlignments: alignments,
    );
  }
}
