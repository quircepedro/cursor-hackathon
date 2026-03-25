import '../../../../core/providers/debug_date_provider.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/journal_audio_storage.dart';

/// Compact audio player for today's journal clip.
/// Shows play/pause button, progress bar, and duration.
class JournalAudioPlayer extends StatefulWidget {
  const JournalAudioPlayer({super.key, this.date, this.audioUrl});

  /// Date of the clip to play. Defaults to today.
  final DateTime? date;
  final String? audioUrl;

  @override
  State<JournalAudioPlayer> createState() => _JournalAudioPlayerState();
}

class _JournalAudioPlayerState extends State<JournalAudioPlayer> {
  final _player = AudioPlayer();
  final _storage = JournalAudioStorage();

  bool _loading = true;
  bool _hasClip = false;

  @override
  void initState() {
    super.initState();
    _loadClip();
  }

  Future<void> _loadClip() async {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      try {
        await _player.setUrl(widget.audioUrl!);
        setState(() {
          _hasClip = true;
          _loading = false;
        });
      } catch (_) {
        setState(() => _loading = false);
      }
      return;
    }

    final date = widget.date ?? appNow();
    final path = await _storage.getClipPathForDate(date);
    if (!mounted) return;
    if (path != null) {
      try {
        if (JournalAudioStorage.canSetAsUrl(path)) {
          await _player.setUrl(path);
        } else {
          await _player.setFilePath(path);
        }
        setState(() {
          _hasClip = true;
          _loading = false;
        });
      } catch (_) {
        setState(() => _loading = false);
      }
      return;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 64,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
        ),
      );
    }

    if (!_hasClip) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Play/pause button
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data;
              final playing = state?.playing ?? false;
              final completed =
                  state?.processingState == ProcessingState.completed;

              return GestureDetector(
                onTap: () async {
                  if (completed) {
                    await _player.seek(Duration.zero);
                    await _player.play();
                  } else if (playing) {
                    await _player.pause();
                  } else {
                    await _player.play();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    completed || !playing
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),

          // Progress bar + times
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                final total = _player.duration ?? Duration.zero;
                final progress = total.inMilliseconds > 0
                    ? (position.inMilliseconds / total.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label
                    Text(
                      'Tu entrada de hoy',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Times
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _formatDuration(total),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
