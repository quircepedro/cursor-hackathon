import 'insight_entity.dart';

class RecordingEntryEntity {
  const RecordingEntryEntity({
    required this.id,
    required this.date,
    this.audioStreamUrl,
    this.insight,
  });

  final String id;
  final DateTime date;
  final String? audioStreamUrl;
  final InsightEntity? insight;

  factory RecordingEntryEntity.fromJson(Map<String, dynamic> json) {
    final insightRaw = json['insight'] as Map<String, dynamic>?;
    return RecordingEntryEntity(
      id: json['id'] as String,
      date: DateTime.parse(json['createdAt'] as String),
      audioStreamUrl: json['audioStreamUrl'] as String?,
      insight: insightRaw != null ? InsightEntity.fromJson(insightRaw) : null,
    );
  }
}
