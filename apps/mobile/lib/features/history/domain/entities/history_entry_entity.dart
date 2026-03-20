import 'package:equatable/equatable.dart';

class HistoryEntryEntity extends Equatable {
  const HistoryEntryEntity({
    required this.id,
    required this.createdAt,
    this.primaryEmotion,
    this.summary,
    this.clipUrl,
    this.durationMs,
  });

  final String id;
  final DateTime createdAt;
  final String? primaryEmotion;
  final String? summary;
  final String? clipUrl;
  final int? durationMs;

  @override
  List<Object?> get props => [id, createdAt];
}
