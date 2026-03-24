import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/debug_date_provider.dart';
import '../../../../core/services/journal_audio_storage.dart';
import '../../../../core/services/journal_insight_storage.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../recording/application/providers/recording_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
            padding: const EdgeInsets.only(bottom: 104),
            children: [
              ListTile(
                leading: const Icon(Icons.star_outline, color: Color(0xFF6366F1)),
                title: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () => context.push(RouteNames.paywall),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: Colors.grey[400]),
                title: const Text(
                  'Account',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: Colors.grey[400]),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: Colors.grey[400]),
                title: const Text(
                  'Privacy',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.bar_chart_rounded, color: Colors.grey[400]),
                title: const Text(
                  'Charts preview',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Preview charts with mock data',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: () => context.push(RouteNames.chartsPreview),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              _DebugDateTile(),
              _DeleteTodayTile(),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
                onTap: () => ref.read(authProvider.notifier).signOut(),
              ),
            ],
          ),
    );
  }
}

class _DebugDateTile extends ConsumerWidget {
  void _applyOffset(WidgetRef ref, int newOffset) {
    ref.read(debugDateOffsetProvider.notifier).state = newOffset;
    syncGlobalOffset(newOffset);
    // Reset in-memory recording state so the home screen doesn't keep old data
    ref.read(recordingProvider.notifier).reset();
    // Force re-fetch from server with the new simulated date
    ref.invalidate(todayRecordingProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(debugDateOffsetProvider);
    final fakeDate = debugNow(offset);
    final label = offset == 0
        ? 'Hoy (real)'
        : '${fakeDate.day}/${fakeDate.month}/${fakeDate.year} (${offset > 0 ? "+$offset" : "$offset"}d)';

    return ListTile(
      leading: Icon(Icons.bug_report, color: Colors.orange[400]),
      title: const Text('Debug: fecha simulada', style: TextStyle(color: Colors.white)),
      subtitle: Text(label, style: TextStyle(color: Colors.orange[300], fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 20),
            onPressed: () => _applyOffset(ref, offset - 1),
          ),
          if (offset != 0)
            IconButton(
              icon: Icon(Icons.restore, color: Colors.orange[300], size: 20),
              onPressed: () => _applyOffset(ref, 0),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
            onPressed: () => _applyOffset(ref, offset + 1),
          ),
        ],
      ),
    );
  }
}

class _DeleteTodayTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeleteTodayTile> createState() => _DeleteTodayTileState();
}

class _DeleteTodayTileState extends ConsumerState<_DeleteTodayTile> {
  bool _deleting = false;

  Future<void> _deleteToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        title: const Text('Borrar datos del día', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se eliminará la grabación, transcripción, insights y análisis del día seleccionado. Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      // 1. Delete on server (cascade deletes transcription, insight, alignments)
      final repo = ref.read(recordingRepositoryProvider);
      final deleted = await repo.deleteTodayRecording();

      // 2. Delete local cached files for this day
      final today = appNow();
      await JournalAudioStorage().deleteForDate(today);
      await JournalInsightStorage().deleteForDate(today);

      // 3. Reset all in-memory providers so every screen updates
      ref.read(recordingProvider.notifier).reset();
      ref.invalidate(todayRecordingProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleted
                ? 'Datos del día eliminados'
                : 'No hay datos para este día'),
            backgroundColor: deleted ? const Color(0xFF34D399) : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.delete_outline, color: Colors.red[400]),
      title: const Text(
        'Borrar datos del día actual',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        'Elimina audio, insights y análisis',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: _deleting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
            )
          : Icon(Icons.chevron_right, color: Colors.grey[600]),
      onTap: _deleting ? null : _deleteToday,
    );
  }
}
