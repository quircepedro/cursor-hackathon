import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../providers/debug_date_provider.dart';
import 'journal_audio_storage_base.dart';

class JournalAudioStorageImpl implements JournalAudioStorageBase {
  static const _dirName = 'journal_audio';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Directory> _audioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<String> pathForDate(DateTime date) async {
    final dir = await _audioDir();
    return '${dir.path}/${_dateKey(date)}.m4a';
  }

  @override
  Future<String> saveToday(String sourcePath) async {
    final dest = await pathForDate(appNow());
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Source audio file not found: $sourcePath');
    }
    await sourceFile.copy(dest);
    return dest;
  }

  @override
  Future<void> deleteForDate(DateTime date) async {
    final path = await pathForDate(date);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<bool> hasClipForDate(DateTime date) async {
    final path = await pathForDate(date);
    return File(path).exists();
  }

  @override
  Future<String?> getClipPathForDate(DateTime date) async {
    final path = await pathForDate(date);
    if (await File(path).exists()) return path;
    return null;
  }

  @override
  Future<List<DateTime>> getAllClipDates() async {
    final dir = await _audioDir();
    if (!await dir.exists()) return [];
    final files = await dir.list().toList();
    final dates = <DateTime>[];
    for (final f in files) {
      if (f is! File) continue;
      final name = f.path.split('/').last.replaceAll('.m4a', '');
      final date = DateTime.tryParse(name);
      if (date != null) dates.add(date);
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }
}
