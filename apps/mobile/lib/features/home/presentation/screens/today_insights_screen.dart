import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../goals/domain/entities/goal_alignment_entity.dart';
import '../../../recording/application/providers/recording_provider.dart';
import '../../../recording/domain/entities/insight_entity.dart';
import '../../../recording/presentation/widgets/emotion_daily_widget.dart';

class TodayInsightsScreen extends ConsumerWidget {
  const TodayInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayRecordingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Insights de hoy', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: todayAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (_, __) => _buildEmpty(),
        data: (today) {
          if (today == null || !today.isComplete || today.insight == null) {
            return _buildEmpty();
          }
          return _buildContent(ref, today.insight!);
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.grey[700], size: 48),
            const SizedBox(height: 16),
            Text(
              'Aún no has grabado tu día',
              style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Graba tu entrada de voz para ver tus insights y métricas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WidgetRef ref, InsightEntity insight) {
    final streakData = ref.watch(streakProvider).valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmotionDailyWidget(insight: insight),
          const SizedBox(height: 16),

          if (insight.dailySummary != null) ...[
            _DailySummaryCard(dailySummary: insight.dailySummary!),
            const SizedBox(height: 12),
          ],

          _DayAnalysisCard(insight: insight),
          const SizedBox(height: 16),

          // Racha & Comparativa
          if (streakData != null)
            Row(
              children: [
                Expanded(child: _StreakCard(data: streakData)),
                const SizedBox(width: 12),
                const Expanded(child: _ComparativeCard()),
              ],
            ),
          const SizedBox(height: 16),

          if (insight.keyThemes.isNotEmpty) ...[
            _ThemesWidget(themes: insight.keyThemes),
            const SizedBox(height: 20),
          ],

          if (insight.goalAlignments.isNotEmpty) ...[
            _AlignmentSection(insight: insight),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _DayAnalysisCard extends StatelessWidget {
  const _DayAnalysisCard({required this.insight});
  final InsightEntity insight;

  /// Truncate summary to ~2-3 sentences.
  String _shortSummary() {
    final text = insight.summary;
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 3) return text;
    return sentences.take(3).join(' ');
  }

  /// Compute a simple emotional productivity score (0–100) from emotion scores.
  /// Positive emotions add, negative emotions subtract.
  int _emotionalScore() {
    const positive = {'alegría', 'confianza', 'anticipación', 'serenidad', 'interés', 'gratitud'};
    const negative = {'tristeza', 'ira', 'miedo', 'asco', 'culpa'};
    double pos = 0, neg = 0;
    for (final e in insight.emotionScores.entries) {
      if (positive.contains(e.key)) {
        pos += e.value;
      } else if (negative.contains(e.key)) {
        neg += e.value;
      }
    }
    final total = pos + neg;
    if (total == 0) return 50;
    return ((pos / total) * 100).round().clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final score = _emotionalScore();
    final (scoreColor, scoreLabel) = score >= 70
        ? (const Color(0xFF34D399), 'Buen equilibrio emocional')
        : score >= 40
            ? (const Color(0xFFFBBF24), 'Equilibrio moderado')
            : (const Color(0xFFEF4444), 'Día emocionalmente intenso');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Análisis del día', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _shortSummary(),
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.65),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: scoreColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$scoreLabel: $score/100',
                    style: TextStyle(color: scoreColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemesWidget extends StatelessWidget {
  const _ThemesWidget({required this.themes});
  final List<String> themes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: themes
          .map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(t,
                    style: const TextStyle(
                        color: Color(0xFFA5B4FC), fontSize: 12, fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }
}

class _AlignmentSection extends StatelessWidget {
  const _AlignmentSection({required this.insight});
  final InsightEntity insight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'OBJETIVOS',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            if (insight.overallAlignment != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(insight.overallAlignment! * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...insight.goalAlignments.map(_buildGoalCard),
      ],
    );
  }

  Widget _buildGoalCard(GoalAlignmentEntity a) {
    final (color, bgColor) = switch (a.level) {
      AlignmentLevel.clearProgress => (
          const Color(0xFF34D399),
          const Color(0xFF34D399).withValues(alpha: 0.1),
        ),
      AlignmentLevel.partialProgress => (
          const Color(0xFFFBBF24),
          const Color(0xFFFBBF24).withValues(alpha: 0.1),
        ),
      AlignmentLevel.deviation => (
          const Color(0xFFEF4444),
          const Color(0xFFEF4444).withValues(alpha: 0.1),
        ),
      AlignmentLevel.noEvidence => (
          const Color(0xFF6B7280),
          const Color(0xFF6B7280).withValues(alpha: 0.1),
        ),
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
          Row(
            children: [
              Expanded(
                  child: Text(a.goalTitle,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Text('$pct%',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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
            Text(a.reason, style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.4)),
          ],
        ],
      ),
    );
  }
}


class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.data});
  final StreakData data;

  @override
  Widget build(BuildContext context) {
    final isBest = data.isCurrentBest && data.current > 0;
    final streakColor = isBest ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);

    String subtitle;
    if (data.current == 0) {
      subtitle = 'Graba hoy para empezar';
    } else if (isBest) {
      subtitle = '¡Tu mejor racha!';
    } else {
      subtitle = 'Mejor: ${data.best} días';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: streakColor.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, color: streakColor, size: 16),
              const SizedBox(width: 6),
              Text('RACHA', style: TextStyle(
                color: Colors.grey[500], fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${data.current}', style: TextStyle(
                color: streakColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('días', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(
            color: isBest ? streakColor.withValues(alpha: 0.8) : Colors.grey[500],
            fontSize: 12, fontWeight: isBest ? FontWeight.w600 : FontWeight.normal)),
          if (data.recordedToday) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 12),
              const SizedBox(width: 4),
              Text('Hoy registrado', style: TextStyle(
                color: const Color(0xFF34D399).withValues(alpha: 0.8), fontSize: 11)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ComparativeCard extends StatelessWidget {
  const _ComparativeCard();

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.grey[500], size: 16),
              const SizedBox(width: 6),
              Text('COMPARATIVA', style: TextStyle(
                color: Colors.grey[500], fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('--', style: TextStyle(
                color: Colors.grey[600], fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('%', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('vs. semana anterior', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 6),
          Text('Próximamente', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.dailySummary});
  final String dailySummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'RESUMEN DEL DÍA',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dailySummary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
