import '../../../core/providers/debug_date_provider.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persistent storage for daily journal audio clips.
/// Stores one audio file per day in the app's documents directory.
class JournalAudioStorage {
  static const _dirName = 'journal_audio';

  /// Returns the directory used for storing journal audio clips.
  Future<Directory> _audioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Date key in yyyy-MM-dd format.
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Returns the file path for a given date's audio clip.
  Future<String> pathForDate(DateTime date) async {
    final dir = await _audioDir();
    return '${dir.path}/${_dateKey(date)}.m4a';
  }

  /// Returns the file path for today's audio clip.
  Future<String> pathForToday() => pathForDate(appNow());

  /// Saves an audio file as today's journal clip.
  /// If a clip already exists for today, it is overwritten.
  Future<String> saveToday(String sourcePath) async {
    final dest = await pathForToday();
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Source audio file not found: $sourcePath');
    }
    await sourceFile.copy(dest);
    return dest;
  }

  /// Returns true if a clip exists for the given date.
  Future<bool> hasClipForDate(DateTime date) async {
    final path = await pathForDate(date);
    return File(path).exists();
  }

  /// Returns true if today's clip already exists.
  Future<bool> hasTodayClip() => hasClipForDate(appNow());

  /// Returns the file path for today's clip, or null if it doesn't exist.
  Future<String?> getTodayClipPath() async {
    final path = await pathForToday();
    if (await File(path).exists()) return path;
    return null;
  }

  /// Returns the file path for a given date's clip, or null if it doesn't exist.
  Future<String?> getClipPathForDate(DateTime date) async {
    final path = await pathForDate(date);
    if (await File(path).exists()) return path;
    return null;
  }

  /// Returns all stored clip dates (sorted descending).
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
