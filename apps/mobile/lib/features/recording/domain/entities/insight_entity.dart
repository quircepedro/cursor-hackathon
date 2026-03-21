import '../../../goals/domain/entities/goal_alignment_entity.dart';

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
}
