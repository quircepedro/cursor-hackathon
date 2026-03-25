import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../providers/debug_date_provider.dart';
import '../../features/recording/domain/entities/insight_entity.dart';
import 'journal_insight_storage_base.dart';

class JournalInsightStorageImpl implements JournalInsightStorageBase {
  static const _dirName = 'journal_insights';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Directory> _insightDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> _pathForDate(DateTime date) async {
    final dir = await _insightDir();
    return '${dir.path}/${_dateKey(date)}.json';
  }

  @override
  Future<void> saveToday(InsightEntity insight) async {
    final path = await _pathForDate(appNow());
    final json = jsonEncode(insight.toJson());
    await File(path).writeAsString(json);
  }

  @override
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

  @override
  Future<void> deleteForDate(DateTime date) async {
    final path = await _pathForDate(date);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
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
