abstract class JournalAudioStorageBase {
  Future<String> pathForDate(DateTime date);
  Future<String> saveToday(String sourcePath);
  Future<void> deleteForDate(DateTime date);
  Future<bool> hasClipForDate(DateTime date);
  Future<String?> getClipPathForDate(DateTime date);
  Future<List<DateTime>> getAllClipDates();
}
