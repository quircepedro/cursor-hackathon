enum AlignmentLevel {
  clearProgress,
  partialProgress,
  noEvidence,
  deviation;

  static AlignmentLevel fromString(String value) => switch (value) {
        'CLEAR_PROGRESS' => AlignmentLevel.clearProgress,
        'PARTIAL_PROGRESS' => AlignmentLevel.partialProgress,
        'NO_EVIDENCE' => AlignmentLevel.noEvidence,
        'DEVIATION' => AlignmentLevel.deviation,
        _ => AlignmentLevel.noEvidence,
      };

  String get label => switch (this) {
        AlignmentLevel.clearProgress => 'Avance claro',
        AlignmentLevel.partialProgress => 'Avance parcial',
        AlignmentLevel.noEvidence => 'Sin evidencia',
        AlignmentLevel.deviation => 'Desviacion',
      };
}

class GoalAlignmentEntity {
  const GoalAlignmentEntity({
    required this.goalId,
    required this.goalTitle,
    required this.score,
    required this.level,
    required this.reason,
  });

  final String goalId;
  final String goalTitle;
  final double score;
  final AlignmentLevel level;
  final String reason;

  factory GoalAlignmentEntity.fromJson(Map<String, dynamic> json) {
    final goal = json['goal'] as Map<String, dynamic>?;
    return GoalAlignmentEntity(
      goalId: goal?['id'] as String? ?? json['goalId'] as String? ?? '',
      goalTitle: goal?['title'] as String? ?? json['goalTitle'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      level: AlignmentLevel.fromString(json['level'] as String? ?? ''),
      reason: json['reason'] as String? ?? '',
    );
  }
}
