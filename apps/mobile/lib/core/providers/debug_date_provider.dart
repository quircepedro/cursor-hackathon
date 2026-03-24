import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global date override for testing. When set, the app behaves as if
/// "today" is [DateTime.now() + offsetDays].
/// Affects tzOffsetMinutes sent to the backend so it resolves the
/// overridden day as "today".
final debugDateOffsetProvider = StateProvider<int>((ref) => 0);

/// Returns the effective "now" considering the debug offset.
DateTime debugNow(int offsetDays) =>
    DateTime.now().add(Duration(days: offsetDays));

/// Returns a fake tzOffsetMinutes that tricks the backend into thinking
/// "today" is [offsetDays] days from real today.
int debugTzOffset(int offsetDays) {
  final realOffset = DateTime.now().timeZoneOffset.inMinutes;
  // Each day = 1440 minutes. We shift the tz offset so the backend
  // computes "today" = real_today + offsetDays.
  return realOffset - (offsetDays * 1440);
}
