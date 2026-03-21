class GoalScoreEntry {
  const GoalScoreEntry({
    required this.goalId,
    required this.title,
    required this.score,
  });

  final String goalId;
  final String title;
  final double score;

  factory GoalScoreEntry.fromJson(Map<String, dynamic> json) {
    return GoalScoreEntry(
      goalId: json['goalId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'title': title,
        'score': score,
      };
}

class AlignmentHistoryEntry {
  const AlignmentHistoryEntry({
    required this.date,
    required this.overallScore,
    required this.goals,
  });

  final DateTime date;
  final double overallScore;
  final List<GoalScoreEntry> goals;

  factory AlignmentHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'] as List<dynamic>? ?? [];
    final dateStr = json['date']?.toString();
    final parsed = dateStr != null ? DateTime.tryParse(dateStr) : null;
    return AlignmentHistoryEntry(
      date: parsed ?? DateTime.now(),
      overallScore:
          (json['overallScore'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0,
      goals: [
        for (final g in rawGoals)
          if (g is Map)
            GoalScoreEntry.fromJson(Map<String, dynamic>.from(g)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toUtc().toIso8601String(),
        'overallScore': overallScore,
        'goals': goals.map((g) => g.toJson()).toList(),
      };
}
