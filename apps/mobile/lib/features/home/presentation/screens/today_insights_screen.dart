import 'package:flutter/material.dart';

import '../../../../core/services/journal_insight_storage.dart';
import '../../../goals/domain/entities/goal_alignment_entity.dart';
import '../../../recording/domain/entities/insight_entity.dart';

class TodayInsightsScreen extends StatefulWidget {
  const TodayInsightsScreen({super.key});

  @override
  State<TodayInsightsScreen> createState() => _TodayInsightsScreenState();
}

class _TodayInsightsScreenState extends State<TodayInsightsScreen> {
  final _storage = JournalInsightStorage();
  InsightEntity? _insight;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final insight = await _storage.getForDate(DateTime.now());
    if (mounted) setState(() { _insight = insight; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Insights de hoy', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _insight == null
              ? _buildEmpty()
              : _buildContent(_insight!),
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

  Widget _buildContent(InsightEntity insight) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sentiment banner
          _buildSentimentBanner(insight),
          const SizedBox(height: 16),

          // Summary
          _buildSummaryCard(insight),
          const SizedBox(height: 12),

          // Themes
          if (insight.keyThemes.isNotEmpty) ...[
            _buildThemes(insight.keyThemes),
            const SizedBox(height: 20),
          ],

          // Goal alignment
          if (insight.goalAlignments.isNotEmpty) ...[
            _buildAlignmentSection(insight),
            const SizedBox(height: 20),
          ],

          // Emotion scores
          if (insight.emotionScores.isNotEmpty)
            _buildEmotionScores(insight.emotionScores),
        ],
      ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildSentimentBanner(InsightEntity insight) {
    final (color, icon) = switch (insight.sentiment) {
      'POSITIVE' => (const Color(0xFF34D399), Icons.sentiment_very_satisfied),
      'NEGATIVE' => (const Color(0xFFEF4444), Icons.sentiment_very_dissatisfied),
      _ => (const Color(0xFF6366F1), Icons.sentiment_neutral),
    };
    final emotion = insight.dominantEmotion;
    final label = emotion.isEmpty ? '' : emotion[0].toUpperCase() + emotion.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
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
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 10),
          Text(
            'EMOCION DEL DIA',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 14),
              const SizedBox(width: 6),
              Text(
                'RESUMEN',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.summary,
            style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildThemes(List<String> themes) {
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

  Widget _buildAlignmentSection(InsightEntity insight) {
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

  Widget _buildEmotionScores(Map<String, double> scores) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMOCIONES DETECTADAS',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
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
                child: Row(
                  children: [
                    SizedBox(
                        width: 100,
                        child: Text(label,
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: v,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                        width: 36,
                        child: Text('${(v * 100).round()}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
