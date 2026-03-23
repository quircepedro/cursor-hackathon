import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/journal_audio_storage.dart';
import '../../../../core/services/journal_insight_storage.dart';
import '../../../goals/domain/entities/goal_alignment_entity.dart';
import '../../../recording/application/providers/recording_provider.dart';
import '../../../recording/domain/entities/insight_entity.dart';
import '../../../recording/domain/entities/recording_entry_entity.dart';

// Height of the sticky glass weekly header
const _kWeekHeaderHeight = 130.0;

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _audioStorage = JournalAudioStorage();
  final _insightStorage = JournalInsightStorage();

  // Remote recordings keyed by date (yyyy-MM-dd)
  final Map<String, RecordingEntryEntity> _remoteByDate = {};
  final _player = AudioPlayer();

  // Monthly view state
  late DateTime _focusedMonth;

  // Weekly view state (after a day is selected)
  late DateTime _focusedWeekStart;
  DateTime? _selectedDate;

  Set<DateTime> _recordedDates = {};
  bool _loading = true;

  // Playback
  bool _isPlaying = false;
  bool _clipLoaded = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Insight
  InsightEntity? _selectedInsight;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _focusedWeekStart = _mondayOf(now);
    _loadRecordedDates();
    _loadRemoteRecordings();

    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() {
        _isPlaying = s.playing;
        if (s.processingState == ProcessingState.completed) _isPlaying = false;
      });
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ─── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadRecordedDates() async {
    final audioDates = await _audioStorage.getAllClipDates();
    final insightDates = await _insightStorage.getAllDates();
    if (!mounted) return;
    setState(() {
      _recordedDates = {
        ...audioDates.map((d) => DateTime(d.year, d.month, d.day)),
        ...insightDates.map((d) => DateTime(d.year, d.month, d.day)),
      };
      _loading = false;
    });
  }

  Future<void> _loadRemoteRecordings() async {
    try {
      final repo = ref.read(recordingRepositoryProvider);
      final recordings = await repo.getRecordings();
      if (!mounted) return;
      setState(() {
        for (final r in recordings) {
          final key = _dateKey(r.date);
          _remoteByDate[key] = r;
          final norm = DateTime(r.date.year, r.date.month, r.date.day);
          _recordedDates.add(norm);
        }
      });
    } catch (_) {
      // Silent fail — local data still shown
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _selectDate(DateTime date) async {
    final norm = DateTime(date.year, date.month, date.day);
    if (!_recordedDates.contains(norm)) return;

    // Tap same day again → return to monthly view
    if (_selectedDate != null && _isSameDay(norm, _selectedDate!)) {
      _goBack();
      return;
    }

    await _player.stop();

    // Try local file first, then remote stream URL
    final localPath = await _audioStorage.getClipPathForDate(date);
    bool loaded = false;
    if (localPath != null) {
      try {
        await _player.setFilePath(localPath);
        loaded = true;
      } catch (_) {}
    }

    if (!loaded) {
      final remote = _remoteByDate[_dateKey(date)];
      if (remote?.audioStreamUrl != null) {
        try {
          await _player.setUrl(remote!.audioStreamUrl!);
          loaded = true;
        } catch (_) {}
      }
    }

    // Try local insight first, then remote
    InsightEntity? insight = await _insightStorage.getForDate(date);
    insight ??= _remoteByDate[_dateKey(date)]?.insight;

    if (!mounted) return;
    setState(() {
      _selectedDate = norm;
      _focusedWeekStart = _mondayOf(date);
      _clipLoaded = loaded;
      _selectedInsight = insight;
      _position = Duration.zero;
    });
  }

  Future<void> _togglePlayback() async {
    if (!_clipLoaded) return;
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  int _daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

  int _firstWeekday(DateTime m) => DateTime(m.year, m.month, 1).weekday;

  String _monthLabel(DateTime m) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${months[m.month - 1]} ${m.year}';
  }

  String _weekRangeLabel(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    const mo = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    if (monday.month == sunday.month) {
      return '${monday.day}–${sunday.day} ${mo[monday.month - 1]} ${monday.year}';
    }
    return '${monday.day} ${mo[monday.month - 1]} – ${sunday.day} ${mo[sunday.month - 1]}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(DateTime date) {
    const days = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
    const months = ['enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  void _goBack() {
    setState(() {
      _selectedDate = null;
      _selectedInsight = null;
      _clipLoaded = false;
      _player.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Calendario', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              reverseDuration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                    ),
                    child: child,
                  ),
                );
              },
              child: _selectedDate == null
                  ? KeyedSubtree(key: const ValueKey('month'), child: _buildMonthView())
                  : KeyedSubtree(key: ValueKey('detail_$_selectedDate'), child: _buildDetailView()),
            ),
    );
  }

  // ─── Month view ──────────────────────────────────────────────────────────────


  Widget _buildMonthView() {
    return Column(
      children: [
        _buildMonthHeader(),
        _buildWeekdayLabels(),
        _buildMonthGrid(),
        Expanded(child: _buildMonthHint()),
        const SizedBox(height: 96.0),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navBtn(Icons.chevron_left,
              () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
          Text(_monthLabel(_focusedMonth),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          _navBtn(Icons.chevron_right,
              () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(l,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMonthGrid() {
    final dim = _daysInMonth(_focusedMonth);
    final blanks = _firstWeekday(_focusedMonth) - 1;
    final total = blanks + dim;
    final rows = (total / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(rows, (row) => Row(
          children: List.generate(7, (col) {
            final idx = row * 7 + col;
            if (idx < blanks || idx >= blanks + dim) {
              return const Expanded(child: SizedBox(height: 52));
            }
            final day = idx - blanks + 1;
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final norm = DateTime(date.year, date.month, date.day);
            final hasRec = _recordedDates.contains(norm);
            final isToday = _isToday(date);

            return Expanded(
              child: GestureDetector(
                onTap: hasRec ? () => _selectDate(date) : null,
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hasRec
                        ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isToday
                        ? Border.all(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                            width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: hasRec ? const Color(0xFFA5B4FC) : Colors.grey[600],
                          fontSize: 15,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: hasRec ? const Color(0xFF6366F1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        )),
      ),
    );
  }

  Widget _buildMonthHint() {
    final count = _recordedDates.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, color: Colors.grey[700], size: 32),
            const SizedBox(height: 10),
            Text(
              count > 0 ? 'Toca un día marcado para ver tu entrada' : 'Aún no tienes entradas grabadas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text('$count entrada${count == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Detail view (week strip + scrollable insight) ───────────────────────────

  Widget _buildDetailView() {
    return Stack(
      children: [
        // Scrollable content with padding so it starts below the glass header
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, _kWeekHeaderHeight + 12, 24, 96.0 + 16),
          child: _buildInsightContent(),
        ),

        // Glassmorphic sticky weekly strip pinned at top
        Positioned(
          top: 0, left: 0, right: 0,
          child: _buildGlassWeekStrip(),
        ),
      ],
    );
  }

  Widget _buildGlassWeekStrip() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: _kWeekHeaderHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF050505).withValues(alpha: 0.55),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Week range label + navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navBtn(Icons.chevron_left, () => setState(
                        () => _focusedWeekStart = _focusedWeekStart.subtract(const Duration(days: 7)))),
                    Text(
                      _weekRangeLabel(_focusedWeekStart),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    _navBtn(Icons.chevron_right, () => setState(
                        () => _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7)))),
                  ],
                ),
              ),

              // 7 day pills
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: List.generate(7, (i) {
                    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                    final date = _focusedWeekStart.add(Duration(days: i));
                    final norm = DateTime(date.year, date.month, date.day);
                    final hasRec = _recordedDates.contains(norm);
                    final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
                    final isToday = _isToday(date);

                    return Expanded(
                      child: GestureDetector(
                        onTap: hasRec ? () => _selectDate(date) : null,
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1)
                                : hasRec
                                    ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                    width: 1.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLabels[i],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.grey[600],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : hasRec
                                          ? const Color(0xFFA5B4FC)
                                          : Colors.grey[600],
                                  fontSize: 15,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: hasRec && !isSelected
                                      ? const Color(0xFF6366F1)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Insight content (scrolls under the glass header) ────────────────────────

  Widget _buildInsightContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date label
        Text(
          _formatDate(_selectedDate!),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        if (_clipLoaded) ...[_buildAudioPlayer(), const SizedBox(height: 16)],

        if (_selectedInsight != null) ...[
          _buildSentimentBadge(_selectedInsight!),
          const SizedBox(height: 12),
          _buildSummaryCard(_selectedInsight!),
          if (_selectedInsight!.keyThemes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildThemes(_selectedInsight!.keyThemes),
          ],
          if (_selectedInsight!.goalAlignments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAlignmentSection(_selectedInsight!),
          ],
          if (_selectedInsight!.emotionScores.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildEmotionScores(_selectedInsight!.emotionScores),
          ],
        ],

        if (_selectedInsight == null && !_clipLoaded)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text('No hay datos para este día',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
      ],
    );
  }

  // ─── Shared UI helpers ────────────────────────────────────────────────────────

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[400], size: 18),
        ),
      );

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Entrada de voz',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                    Text(_formatDuration(_duration),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentBadge(InsightEntity insight) {
    final (color, icon, label) = switch (insight.sentiment) {
      'POSITIVE' => (const Color(0xFF34D399), Icons.sentiment_very_satisfied, 'Positivo'),
      'NEGATIVE' => (const Color(0xFFEF4444), Icons.sentiment_very_dissatisfied, 'Negativo'),
      _ => (const Color(0xFF6366F1), Icons.sentiment_neutral, 'Neutral'),
    };
    final emotion = insight.dominantEmotion;
    final cap = emotion.isEmpty ? '' : emotion[0].toUpperCase() + emotion.substring(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        if (cap.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(cap, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(InsightEntity insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 14),
            const SizedBox(width: 6),
            Text('RESUMEN DEL DIA',
                style: TextStyle(color: Colors.grey[500], fontSize: 10,
                    fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 10),
          Text(insight.summary,
              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildThemes(List<String> themes) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: themes.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(t, style: const TextStyle(
            color: Color(0xFFA5B4FC), fontSize: 12, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  Widget _buildAlignmentSection(InsightEntity insight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('OBJETIVOS', style: TextStyle(
              color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const Spacer(),
          if (insight.overallAlignment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${(insight.overallAlignment! * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 12),
        ...insight.goalAlignments.map(_buildGoalCard),
      ],
    );
  }

  Widget _buildGoalCard(GoalAlignmentEntity a) {
    final (color, bgColor) = switch (a.level) {
      AlignmentLevel.clearProgress =>
        (const Color(0xFF34D399), const Color(0xFF34D399).withValues(alpha: 0.1)),
      AlignmentLevel.partialProgress =>
        (const Color(0xFFFBBF24), const Color(0xFFFBBF24).withValues(alpha: 0.1)),
      AlignmentLevel.deviation =>
        (const Color(0xFFEF4444), const Color(0xFFEF4444).withValues(alpha: 0.1)),
      AlignmentLevel.noEvidence =>
        (const Color(0xFF6B7280), const Color(0xFF6B7280).withValues(alpha: 0.1)),
    };
    final pct = a.score > 1 ? a.score.round() : (a.score * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(a.goalTitle,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Text('$pct%',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (a.score > 1 ? a.score / 100 : a.score).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Text(a.level.label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          if (a.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(a.reason,
                style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionScores(Map<String, double> scores) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EMOCIONES DETECTADAS', style: TextStyle(
            color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151518),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: sorted.map((e) {
              final label = e.key[0].toUpperCase() + e.key.substring(1);
              final v = e.value.clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 100,
                      child: Text(label,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 12),
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: v,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      minHeight: 6,
                    ),
                  )),
                  const SizedBox(width: 10),
                  SizedBox(width: 36,
                      child: Text('${(v * 100).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12,
                              fontWeight: FontWeight.w500))),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
