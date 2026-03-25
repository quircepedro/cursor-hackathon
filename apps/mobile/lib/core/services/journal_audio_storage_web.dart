import 'package:shared_preferences/shared_preferences.dart';

import '../providers/debug_date_provider.dart';
import 'journal_audio_storage_base.dart';

class JournalAudioStorageImpl implements JournalAudioStorageBase {
  static const _prefix = 'journal_audio_web_';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _keyForDate(DateTime date) => '$_prefix${_dateKey(date)}';

  @override
  Future<String> pathForDate(DateTime date) async {
    // On web we keep a logical path key; playback/upload resolve it to URL bytes.
    return _keyForDate(date);
  }

  @override
  Future<String> saveToday(String sourcePath) async {
    final prefs = await SharedPreferences.getInstance();
    final now = appNow();
    final key = _keyForDate(DateTime(now.year, now.month, now.day));
    await prefs.setString(key, sourcePath);
    return sourcePath;
  }

  @override
  Future<void> deleteForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForDate(date));
  }

  @override
  Future<bool> hasClipForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyForDate(date));
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> getClipPathForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyForDate(date));
  }

  @override
  Future<List<DateTime>> getAllClipDates() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = <DateTime>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final value = prefs.getString(key);
      if (value == null || value.isEmpty) continue;
      final dateRaw = key.substring(_prefix.length);
      final date = DateTime.tryParse(dateRaw);
      if (date != null) {
        dates.add(DateTime(date.year, date.month, date.day));
      }
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }
}
