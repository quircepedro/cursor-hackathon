import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../providers/debug_date_provider.dart';
import '../../features/recording/domain/entities/insight_entity.dart';
import 'journal_insight_storage_base.dart';

class JournalInsightStorageImpl implements JournalInsightStorageBase {
  static const _prefix = 'journal_insight_web_';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _keyForDate(DateTime date) => '$_prefix${_dateKey(date)}';

  @override
  Future<void> saveToday(InsightEntity insight) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(insight.toJson());
    await prefs.setString(_keyForDate(appNow()), payload);
  }

  @override
  Future<InsightEntity?> getForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForDate(date));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return InsightEntity.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForDate(date));
  }

  @override
  Future<List<DateTime>> getAllDates() async {
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
