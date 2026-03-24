import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global date override for testing.
final debugDateOffsetProvider = StateProvider<int>((ref) => 0);

/// Singleton offset accessible without ref (for non-widget code).
int _globalOffset = 0;

/// Call this whenever debugDateOffsetProvider changes.
void syncGlobalOffset(int offset) => _globalOffset = offset;

/// Drop-in replacement for DateTime.now() across the entire app.
/// When offset is 0, returns real now. Otherwise shifts by N days.
DateTime appNow() => DateTime.now().add(Duration(days: _globalOffset));

/// Returns the effective "now" considering a given offset.
DateTime debugNow(int offsetDays) =>
    DateTime.now().add(Duration(days: offsetDays));

/// Fake tzOffsetMinutes so the backend thinks "today" is the shifted day.
int debugTzOffset(int offsetDays) {
  final realOffset = DateTime.now().timeZoneOffset.inMinutes;
  return realOffset - (offsetDays * 1440);
}
