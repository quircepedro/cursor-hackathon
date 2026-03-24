import '../../../core/providers/debug_date_provider.dart';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/recording/domain/entities/insight_entity.dart';

/// Persistent storage for daily journal insights (AI analysis).
/// Stores one JSON file per day in the app's documents directory.
class JournalInsightStorage {
  static const _dirName = 'journal_insights';

  Future<Directory> _insightDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<String> _pathForDate(DateTime date) async {
    final dir = await _insightDir();
    return '${dir.path}/${_dateKey(date)}.json';
  }

  /// Saves an insight for today. Overwrites if one already exists.
  Future<void> saveToday(InsightEntity insight) async {
    final path = await _pathForDate(appNow());
    final json = jsonEncode(insight.toJson());
    await File(path).writeAsString(json);
  }

  /// Loads the insight for a given date, or null if none exists.
  Future<InsightEntity?> getForDate(DateTime date) async {
    final path = await _pathForDate(date);
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return InsightEntity.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Deletes the insight file for a given date.
  Future<void> deleteForDate(DateTime date) async {
    final path = await _pathForDate(date);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Returns all dates that have saved insights (sorted descending).
  Future<List<DateTime>> getAllDates() async {
    final dir = await _insightDir();
    if (!await dir.exists()) return [];
    final files = await dir.list().toList();
    final dates = <DateTime>[];
    for (final f in files) {
      if (f is! File) continue;
      final name = f.path.split('/').last.replaceAll('.json', '');
      final date = DateTime.tryParse(name);
      if (date != null) dates.add(date);
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }
}
