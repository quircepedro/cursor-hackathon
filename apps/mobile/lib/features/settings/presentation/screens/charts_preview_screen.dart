import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../goals/domain/entities/alignment_history_entity.dart';
import '../../../goals/domain/entities/goal_alignment_entity.dart';
import '../../../goals/presentation/widgets/alignment_cards.dart';
import '../../../goals/presentation/widgets/alignment_radar_chart.dart';
import '../../../goals/presentation/widgets/alignment_trend_chart.dart';
import '../../../recording/domain/entities/insight_entity.dart';

/// Preview screen with hardcoded realistic data so you can tweak chart styles
/// without needing the full recording → analysis flow.
class ChartsPreviewScreen extends StatelessWidget {
  const ChartsPreviewScreen({super.key});

  // ── Mock data ──────────────────────────────────────────────────────────────

  static const _mockInsight = InsightEntity(
    summary:
        'Hoy has reflexionado sobre la presion que sientes en el trabajo con '
        'la fecha limite del viernes. A pesar del estres, reconoces que el '
        'ejercicio por la manana te ayudo a mantener la calma. Mencionas que '
        'quieres dedicar mas tiempo a leer antes de dormir en vez de mirar '
        'el movil, y que la conversacion con tu madre te dio perspectiva '
        'sobre priorizar lo que realmente importa.',
    emotionScores: {
      'anxiety': 0.35,
      'gratitude': 0.25,
      'determination': 0.20,
      'calm': 0.12,
      'frustration': 0.08,
    },
    keyThemes: [
      'Estres laboral',
      'Ejercicio matutino',
      'Habitos digitales',
      'Familia',
    ],
    sentiment: 'POSITIVE',
    suggestedActions: [
      {'action': 'Bloquea 30 min de lectura antes de dormir esta semana'},
      {'action': 'Planifica las tareas del viernes hoy para reducir ansiedad'},
      {'action': 'Agenda una llamada semanal con tu madre'},
    ],
    overallAlignment: 0.72,
    goalAlignments: [
      GoalAlignmentEntity(
        goalId: 'g1',
        goalTitle: 'Reducir estres',
        score: 0.85,
        level: AlignmentLevel.clearProgress,
        reason:
            'Hacer ejercicio por la manana es una estrategia activa contra '
            'el estres. Reconocer las fuentes de presion demuestra autoconciencia.',
      ),
      GoalAlignmentEntity(
        goalId: 'g2',
        goalTitle: 'Leer mas libros',
        score: 0.45,
        level: AlignmentLevel.partialProgress,
        reason:
            'Mencionas la intencion de leer antes de dormir, pero aun no '
            'lo estas haciendo de forma consistente. Es un primer paso.',
      ),
      GoalAlignmentEntity(
        goalId: 'g3',
        goalTitle: 'Mejorar relaciones',
        score: 0.78,
        level: AlignmentLevel.clearProgress,
        reason:
            'La conversacion con tu madre muestra conexion activa con la '
            'familia. Valoras su perspectiva y buscas ese contacto.',
      ),
      GoalAlignmentEntity(
        goalId: 'g4',
        goalTitle: 'Desconectar del movil',
        score: 0.20,
        level: AlignmentLevel.deviation,
        reason:
            'Reconoces que sigues mirando el movil antes de dormir en lugar '
            'de leer. El habito aun no ha cambiado.',
      ),
    ],
  );

  static final _mockHistory = [
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 6)),
      overallScore: 0.45,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.40),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.20),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.55),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.10),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 5)),
      overallScore: 0.50,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.50),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.25),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.60),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.15),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 4)),
      overallScore: 0.55,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.55),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.30),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.65),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.12),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 3)),
      overallScore: 0.60,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.65),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.35),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.70),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.18),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      overallScore: 0.68,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.75),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.40),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.72),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.15),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      overallScore: 0.65,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.70),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.38),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.75),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.22),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now(),
      overallScore: 0.72,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estres', score: 0.85),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer mas libros', score: 0.45),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.78),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del movil', score: 0.20),
      ],
    ),
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const insight = _mockInsight;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            const Text('Charts preview', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sentiment banner
              const _SentimentBanner(insight: insight),
              const SizedBox(height: 16),

              // Summary
              const _SummaryCard(insight: insight),
              const SizedBox(height: 16),

              // Themes
              _ThemesRow(themes: insight.keyThemes),
              const SizedBox(height: 16),

              // Suggested actions
              if (insight.suggestedActions != null &&
                  insight.suggestedActions!.isNotEmpty)
                _ActionsCard(actions: insight.suggestedActions!),

              // ── Goal Alignment Section ───────────────────────────────────
              const SizedBox(height: 32),
              Text(
                'ALINEACION CON TUS OBJETIVOS',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              AlignmentCards(alignments: insight.goalAlignments),
              const SizedBox(height: 16),
              _AlignmentRingsChart(
                alignments: insight.goalAlignments,
                overallScore: insight.overallAlignment ?? 0,
              ),
              const SizedBox(height: 16),
              AlignmentRadarChart(alignments: insight.goalAlignments),
              const SizedBox(height: 16),
              AlignmentTrendChart(history: _mockHistory),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Private widgets (copied from result_screen to keep this self-contained) ─

class _SentimentBanner extends StatelessWidget {
  const _SentimentBanner({required this.insight});
  final InsightEntity insight;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.sentiment) {
      'POSITIVE' => (const Color(0xFF34D399), Icons.sentiment_very_satisfied),
      'NEGATIVE' => (const Color(0xFFEF4444), Icons.sentiment_very_dissatisfied),
      _ => (const Color(0xFF6366F1), Icons.sentiment_neutral),
    };

    final emotion = _capitalise(insight.dominantEmotion);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), const Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            'TODAY\'S EMOTION',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emotion,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.insight});
  final InsightEntity insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        insight.summary,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ThemesRow extends StatelessWidget {
  const _ThemesRow({required this.themes});
  final List<String> themes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: themes
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                border:
                    Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                t,
                style: const TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.actions});
  final List<Map<String, String>> actions;

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
          const Text(
            'SUGGESTED ACTIONS',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF6366F1), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a['action'] ?? '',
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Apple Activity-style rings chart ─────────────────────────────────────────

class _AlignmentRingsChart extends StatelessWidget {
  const _AlignmentRingsChart({
    required this.alignments,
    required this.overallScore,
  });

  final List<GoalAlignmentEntity> alignments;
  final double overallScore;

  static Color _ringColor(AlignmentLevel level) => switch (level) {
        AlignmentLevel.clearProgress => const Color(0xFF34D399),
        AlignmentLevel.partialProgress => const Color(0xFFFBBF24),
        AlignmentLevel.noEvidence => const Color(0xFF6B7280),
        AlignmentLevel.deviation => const Color(0xFFEF4444),
      };

  @override
  Widget build(BuildContext context) {
    final colors = alignments.map<Color>((a) => _ringColor(a.level)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALINEACION',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(overallScore * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rings canvas
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _RingsPainter(
                    alignments: alignments,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < alignments.length; i++) ...[
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alignments[i].goalTitle,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(alignments[i].score * 100).round()}%',
                            style: TextStyle(
                              color: colors[i],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (i < alignments.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.alignments,
    required this.colors,
  });

  final List<GoalAlignmentEntity> alignments;
  final List<Color> colors;

  static const double _ringStroke = 14.0;
  static const double _ringGap = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - _ringStroke / 2;

    for (int i = 0; i < alignments.length && i < 4; i++) {
      final radius = maxRadius - i * (_ringStroke + _ringGap);
      if (radius <= _ringStroke / 2) break;

      final score = alignments[i].score.clamp(0.0, 1.0);
      final color = colors[i];
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Background track
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringStroke
          ..strokeCap = StrokeCap.round,
      );

      if (score <= 0) continue;

      // Glow shadow under the arc for depth (Apple-like effect)
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * score,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringStroke + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Main colored arc
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * score,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringStroke
          ..strokeCap = StrokeCap.round,
      );

      // Bright end-cap highlight (gives the 3-D pop)
      if (score > 0.01 && score < 0.995) {
        final endAngle = -math.pi / 2 + 2 * math.pi * score;
        final capX = center.dx + radius * math.cos(endAngle);
        final capY = center.dy + radius * math.sin(endAngle);
        canvas.drawCircle(
          Offset(capX, capY),
          _ringStroke / 2,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        // Tiny specular on top of cap
        canvas.drawCircle(
          Offset(capX - 1.5, capY - 1.5),
          2.5,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.alignments != alignments || old.colors != colors;
}
