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
      goalId: json['goalId'] as String,
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
    );
  }
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
    return AlignmentHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      overallScore: (json['overallScore'] as num).toDouble(),
      goals: rawGoals
          .map((g) => GoalScoreEntry.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}
