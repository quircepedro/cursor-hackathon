import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/history_entry_entity.dart';

// ─── Notifier ────────────────────────────────────────────────────────────────

class HistoryNotifier extends AsyncNotifier<List<HistoryEntryEntity>> {
  @override
  Future<List<HistoryEntryEntity>> build() async {
    return _fetchHistory();
  }

  Future<List<HistoryEntryEntity>> _fetchHistory() async {
    // TODO: wire to HistoryRepository
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return []; // Empty list until repository is wired
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchHistory);
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<HistoryEntryEntity>>(HistoryNotifier.new);
