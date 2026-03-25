import '../providers/debug_date_provider.dart';
import 'journal_audio_storage_io.dart'
    if (dart.library.html) 'journal_audio_storage_web.dart';

/// Persistent storage for daily journal audio clips.
class JournalAudioStorage extends JournalAudioStorageImpl {
  static bool canSetAsUrl(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:') ||
        path.startsWith('data:');
  }

  Future<String> pathForToday() => pathForDate(appNow());
  Future<bool> hasTodayClip() => hasClipForDate(appNow());
  Future<String?> getTodayClipPath() => getClipPathForDate(appNow());
}
