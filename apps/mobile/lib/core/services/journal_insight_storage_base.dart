import '../../features/recording/domain/entities/insight_entity.dart';

abstract class JournalInsightStorageBase {
  Future<void> saveToday(InsightEntity insight);
  Future<InsightEntity?> getForDate(DateTime date);
  Future<void> deleteForDate(DateTime date);
  Future<List<DateTime>> getAllDates();
}
