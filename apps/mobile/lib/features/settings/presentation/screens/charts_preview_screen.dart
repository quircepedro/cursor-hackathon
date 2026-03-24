import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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
        'Hoy has reflexionado sobre la presión que sientes en el trabajo con '
        'la fecha límite del viernes. A pesar del estrés, reconoces que el '
        'ejercicio por la mañana te ayudó a mantener la calma.',
    emotionScores: {
      'anxiety': 0.35,
      'gratitude': 0.25,
      'determination': 0.20,
      'calm': 0.12,
      'frustration': 0.08,
    },
    keyThemes: [
      'Estrés laboral',
      'Ejercicio matutino',
      'Hábitos digitales',
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
        goalTitle: 'Reducir estrés',
        score: 0.85,
        level: AlignmentLevel.clearProgress,
        reason:
            'Hacer ejercicio por la mañana es una estrategia activa contra '
            'el estrés. Reconocer las fuentes de presión demuestra autoconciencia.',
      ),
      GoalAlignmentEntity(
        goalId: 'g2',
        goalTitle: 'Leer más libros',
        score: 0.45,
        level: AlignmentLevel.partialProgress,
        reason:
            'Mencionas la intención de leer antes de dormir, pero aún no '
            'lo estás haciendo de forma consistente.',
      ),
      GoalAlignmentEntity(
        goalId: 'g3',
        goalTitle: 'Mejorar relaciones',
        score: 0.78,
        level: AlignmentLevel.clearProgress,
        reason:
            'La conversación con tu madre muestra conexión activa con la familia.',
      ),
      GoalAlignmentEntity(
        goalId: 'g4',
        goalTitle: 'Desconectar del móvil',
        score: 0.20,
        level: AlignmentLevel.deviation,
        reason:
            'Reconoces que sigues mirando el móvil antes de dormir en lugar de leer.',
      ),
    ],
  );

  static final _mockHistory = [
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 6)),
      overallScore: 0.45,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.40),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.20),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.55),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.10),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 5)),
      overallScore: 0.50,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.50),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.25),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.60),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.15),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 4)),
      overallScore: 0.55,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.55),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.30),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.65),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.12),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 3)),
      overallScore: 0.60,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.65),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.35),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.70),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.18),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      overallScore: 0.68,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.75),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.40),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.72),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.15),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      overallScore: 0.65,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.70),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.38),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.75),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.22),
      ],
    ),
    AlignmentHistoryEntry(
      date: DateTime.now(),
      overallScore: 0.72,
      goals: [
        const GoalScoreEntry(goalId: 'g1', title: 'Reducir estrés', score: 0.85),
        const GoalScoreEntry(goalId: 'g2', title: 'Leer más libros', score: 0.45),
        const GoalScoreEntry(goalId: 'g3', title: 'Mejorar relaciones', score: 0.78),
        const GoalScoreEntry(goalId: 'g4', title: 'Desconectar del móvil', score: 0.20),
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
        title: const Text('Charts preview', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Emoción diaria ─────────────────────────────────────────────
              _sectionLabel('EMOCIÓN DIARIA'),
              const SizedBox(height: 12),
              const _EmotionDailyCard(insight: insight),
              const SizedBox(height: 24),

              // ── Resumen diario ─────────────────────────────────────────────
              _sectionLabel('RESUMEN DIARIO'),
              const SizedBox(height: 12),
              const _SummaryCard(insight: insight),
              const SizedBox(height: 12),
              _sectionLabel('ALINEACIÓN'),
              const SizedBox(height: 12),
              _AlignmentRingsChart(
                alignments: insight.goalAlignments,
                overallScore: insight.overallAlignment ?? 0,
              ),
              const SizedBox(height: 24),

              // ── Insight texto ──────────────────────────────────────────────
              _sectionLabel('INSIGHT DEL DÍA'),
              const SizedBox(height: 12),
              const _InsightTextCard(),
              const SizedBox(height: 24),

              // ── Racha ──────────────────────────────────────────────────────
              _sectionLabel('RACHA & COMPARATIVA'),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    Expanded(child: _StreakCard()),
                    SizedBox(width: 12),
                    Expanded(child: _VsYesterdayCard()),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Alerta ─────────────────────────────────────────────────────
              _sectionLabel('ALERTAS'),
              const SizedBox(height: 12),
              const _AlertsCard(),
              const SizedBox(height: 24),

              // ── Alineación por objetivo ────────────────────────────────────
              _sectionLabel('ALINEACIÓN CON TUS OBJETIVOS'),
              const SizedBox(height: 12),
              AlignmentCards(alignments: insight.goalAlignments),
              const SizedBox(height: 12),
              AlignmentRadarChart(alignments: insight.goalAlignments),
              const SizedBox(height: 24),

              // ── Momento destacado ──────────────────────────────────────────
              _sectionLabel('MOMENTO DESTACADO DEL DÍA'),
              const SizedBox(height: 12),
              const _HighlightMomentCard(),
              const SizedBox(height: 24),

              // ── Direccional ────────────────────────────────────────────────
              _sectionLabel('HACIA DÓNDE VAS'),
              const SizedBox(height: 12),
              const _DirectionalCard(),
              const SizedBox(height: 24),

              // ── Métricas de estrés ─────────────────────────────────────────
              _sectionLabel('LO QUE MÁS TE ESTRESA'),
              const SizedBox(height: 12),
              const _StressTriggersCard(),
              const SizedBox(height: 24),

              // ── Tendencias ─────────────────────────────────────────────────
              _sectionLabel('TENDENCIAS'),
              const SizedBox(height: 12),
              const _DailyImprovementTrendCard(),
              const SizedBox(height: 12),
              AlignmentTrendChart(history: _mockHistory),
              const SizedBox(height: 12),
              const _SevenDayProductivityCard(),
              const SizedBox(height: 24),

              // ── Feedback acciones ──────────────────────────────────────────
              _sectionLabel('ACCIONES RECOMENDADAS'),
              const SizedBox(height: 12),
              if (insight.suggestedActions != null &&
                  insight.suggestedActions!.isNotEmpty)
                _FeedbackActionsCard(actions: insight.suggestedActions!),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.4,
        ),
      );
}

// ─── Emoción diaria ────────────────────────────────────────────────────────────

class _EmotionDailyCard extends StatelessWidget {
  const _EmotionDailyCard({required this.insight});
  final InsightEntity insight;

  static const _emotions = [
    ('Ansiedad', 0.35, Color(0xFFEF4444)),
    ('Gratitud', 0.25, Color(0xFF34D399)),
    ('Determinación', 0.20, Color(0xFF818CF8)),
    ('Calma', 0.12, Color(0xFF38BDF8)),
    ('Frustración', 0.08, Color(0xFFFBBF24)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Dominant emotion hero ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ansiedad',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'emoción predominante · 35%',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.sentiment_satisfied_alt_rounded,
                          color: Color(0xFF34D399), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Positivo',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Emotion spectrum bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: _emotions.map((e) {
                    return Expanded(
                      flex: (e.$2 * 100).round(),
                      child: Container(color: e.$3),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Emotion chips grid ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emotions.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: e.$3.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: e.$3.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: e.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        e.$1,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(e.$2 * 100).round()}%',
                        style: TextStyle(
                          color: e.$3,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Resumen diario ────────────────────────────────────────────────────────────

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insight.keyThemes
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            insight.summary,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Insight texto ─────────────────────────────────────────────────────────────

class _InsightTextCard extends StatelessWidget {
  const _InsightTextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF6366F1), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Análisis del día',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Hoy tu patrón emocional revela una tensión entre la responsabilidad laboral y el bienestar personal. '
            'El ejercicio matutino actuó como regulador emocional, reduciendo el impacto del estrés laboral. '
            'La llamada con tu madre fue un punto de anclaje que te devolvió perspectiva. '
            'Tu mente está procesando activamente cómo equilibrar compromisos y descanso.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF34D399).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFF34D399), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu productividad emocional hoy: 74/100',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

// ─── Alertas ───────────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  static const _alerts = [
    (
      Icons.warning_amber_rounded,
      Color(0xFFFBBF24),
      'Llevas 3 días evitando tu objetivo principal',
      '"Desconectar del móvil" no ha tenido progreso en 3 días consecutivos.',
    ),
    (
      Icons.trending_up_rounded,
      Color(0xFFEF4444),
      'Tu nivel de estrés está subiendo',
      'Estrés laboral aparece en tus últimas 4 entradas. Semana intensa.',
    ),
    (
      Icons.local_fire_department_rounded,
      Color(0xFF6366F1),
      'Racha en riesgo',
      'Mañana es el último día para mantener tu racha de 7 días.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _alerts
          .map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: a.$2.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: a.$2.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: a.$2.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a.$1, color: a.$2, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.$3,
                          style: TextStyle(
                            color: a.$2,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          a.$4,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Momento destacado ─────────────────────────────────────────────────────────

class _HighlightMomentCard extends StatelessWidget {
  const _HighlightMomentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.15),
            const Color(0xFF312E81).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Momento del día',
                style: TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '"La conversación con mi madre me recordó que lo que realmente importa no es el plazo del viernes."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Perspectiva',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Familia',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Direccional ───────────────────────────────────────────────────────────────

class _DirectionalCard extends StatelessWidget {
  const _DirectionalCard();

  static const _projections = [
    ('Reducir estrés', 0.85, 0.92, Color(0xFF34D399)),
    ('Leer más libros', 0.45, 0.60, Color(0xFF6366F1)),
    ('Mejorar relaciones', 0.78, 0.85, Color(0xFF38BDF8)),
    ('Desconectar del móvil', 0.20, 0.25, Color(0xFFEF4444)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_rounded,
                  color: Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Si mantienes este ritmo en 30 días...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Proyección basada en tu tendencia actual',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 18),
          ..._projections.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.$1,
                          style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                      Row(
                        children: [
                          Text(
                            '${(p.$2 * 100).round()}%',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: p.$4, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${(p.$3 * 100).round()}%',
                            style: TextStyle(
                              color: p.$4,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.$3,
                          backgroundColor: p.$4.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              p.$4.withValues(alpha: 0.25)),
                          minHeight: 6,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.$2,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(p.$4),
                          minHeight: 6,
                        ),
                      ),
                    ],
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

// ─── Stress triggers ───────────────────────────────────────────────────────────

class _StressTriggersCard extends StatelessWidget {
  const _StressTriggersCard();

  static const _triggers = [
    ('Fechas límite laborales', 0.82, Color(0xFFEF4444)),
    ('Falta de sueño', 0.68, Color(0xFFFBBF24)),
    ('Uso del móvil nocturno', 0.55, Color(0xFFFBBF24)),
    ('Conflictos interpersonales', 0.34, Color(0xFF6366F1)),
    ('Desorganización', 0.28, Color(0xFF6B7280)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Siempre te estresa...',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Basado en los últimos 30 días de entradas',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 16),
          ..._triggers.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.$1,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: t.$3.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: t.$2,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: t.$3,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(t.$2 * 100).round()}%',
                    style: TextStyle(
                      color: t.$3,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

// ─── Tendencia de mejora diaria ────────────────────────────────────────────────

class _DailyImprovementTrendCard extends StatelessWidget {
  const _DailyImprovementTrendCard();

  static const _scores = [58.0, 60.0, 55.0, 63.0, 68.0, 65.0, 74.0];
  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      _scores.length,
      (i) => FlSpot(i.toDouble(), _scores[i]),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tendencia de mejora diaria',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Últimos 7 días',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.trending_up, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+27%',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _days[i],
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 40,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6366F1),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final isLast = index == spots.length - 1;
                        return FlDotCirclePainter(
                          radius: isLast ? 5 : 3,
                          color: isLast
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF6366F1).withValues(alpha: 0.6),
                          strokeWidth: isLast ? 2 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
                          const Color(0xFF6366F1).withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

// ─── 7 días productividad ──────────────────────────────────────────────────────

class _SevenDayProductivityCard extends StatelessWidget {
  const _SevenDayProductivityCard();

  static const _data = [0.60, 0.55, 0.70, 0.65, 0.80, 0.72, 0.74];
  static const _days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productividad — últimos 7 días',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Energía disponible para tus objetivos',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= _days.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _days[i],
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  _data.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _data[i],
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: i == _data.length - 1
                              ? [
                                  const Color(0xFF6366F1),
                                  const Color(0xFF818CF8),
                                ]
                              : [
                                  const Color(0xFF6366F1).withValues(alpha: 0.5),
                                  const Color(0xFF6366F1).withValues(alpha: 0.3),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 1.0,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Racha ────────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  static const int _current = 7;
  static const int _best = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot grid — 7 cols × 2 rows
          _DotGrid(filled: _current),
          const SizedBox(height: 16),
          // Number
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '$_current',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'días',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'racha activa 🔥',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Best streak bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'récord: $_best días',
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _current / _best,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFBBF24)),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    const total = 14; // 7 cols × 2 rows
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(total, (i) {
        final active = i < filled;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFFBBF24)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Vs ayer ───────────────────────────────────────────────────────────────────

class _VsYesterdayCard extends StatelessWidget {
  const _VsYesterdayCard();

  static const _metrics = [
    ('Alineación', '+10%', true),
    ('Estrés', '+8%', false),
    ('Ánimo', '+5%', true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.compare_arrows_rounded,
                  color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 6),
              Text(
                'vs. ayer',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._metrics.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.$1,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  Row(
                    children: [
                      Icon(
                        m.$3 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: m.$3
                            ? const Color(0xFF34D399)
                            : const Color(0xFFEF4444),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        m.$2,
                        style: TextStyle(
                          color: m.$3
                              ? const Color(0xFF34D399)
                              : const Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Mejor día de la semana',
              style: TextStyle(
                  color: Color(0xFF34D399),
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feedback acciones ─────────────────────────────────────────────────────────

class _FeedbackActionsCard extends StatelessWidget {
  const _FeedbackActionsCard({required this.actions});
  final List<Map<String, String>> actions;

  static const _priorities = [
    Color(0xFFEF4444),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
  ];

  @override
  Widget build(BuildContext context) {
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
            children: const [
              Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text(
                'Qué hacer ahora',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Acciones recomendadas por tu IA personal',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 16),
          ...List.generate(actions.length, (i) {
            final color = _priorities[i.clamp(0, _priorities.length - 1)];
            final priorityLabel = i == 0
                ? 'Alta'
                : i == 1
                    ? 'Media'
                    : 'Baja';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      actions[i]['action'] ?? '',
                      style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
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
                'ALINEACIÓN',
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
              SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(
                  painter: _RingsPainter(
                    alignments: alignments,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(width: 20),
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

  static const double _ringStroke = 12.0;
  static const double _ringGap = 7.0;

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
