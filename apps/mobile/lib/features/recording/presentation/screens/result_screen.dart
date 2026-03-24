import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../goals/application/providers/goals_provider.dart';
import '../../../goals/domain/entities/alignment_history_entity.dart';
import '../../../goals/presentation/widgets/alignment_cards.dart';
import '../../../goals/presentation/widgets/alignment_bar_chart.dart';
import '../../../goals/presentation/widgets/alignment_radar_chart.dart';
import '../../../goals/presentation/widgets/alignment_trend_chart.dart';
import '../../application/providers/recording_provider.dart';
import '../../domain/entities/emotion_taxonomy.dart';
import '../../domain/entities/insight_entity.dart';
import '../widgets/journal_audio_player.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(recordingProvider).insight;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          unawaited(ref.read(todayRecordingProvider.notifier).refresh());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Your insight', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (insight != null) ...[
                        _SentimentBanner(insight: insight),
                        const SizedBox(height: 16),
                        const JournalAudioPlayer(),
                        const SizedBox(height: 16),
                        _SummaryCard(insight: insight),
                        const SizedBox(height: 16),
                        if (insight.keyThemes.isNotEmpty)
                          _ThemesRow(themes: insight.keyThemes),
                        if (insight.suggestedActions != null &&
                            insight.suggestedActions!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ActionsCard(actions: insight.suggestedActions!),
                        ],
                        // Goal Alignment Section
                        if (insight.goalAlignments.isNotEmpty) ...[
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
                          AlignmentBarChart(
                            alignments: insight.goalAlignments,
                            overallScore: insight.overallAlignment ?? 0,
                          ),
                          const SizedBox(height: 16),
                          AlignmentRadarChart(
                              alignments: insight.goalAlignments),
                          const SizedBox(height: 16),
                          const _TrendChartSection(),
                        ],
                      ] else
                        const _PlaceholderCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  unawaited(ref.read(todayRecordingProvider.notifier).refresh());
                  ref.read(recordingProvider.notifier).reset();
                  context.go(RouteNames.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SentimentBanner extends StatelessWidget {
  const _SentimentBanner({required this.insight});
  final InsightEntity insight;

  @override
  Widget build(BuildContext context) {
    final dominant = insight.dominantEmotion;
    final dominantLabel = EmotionTaxonomy.label(dominant);
    final dominantColor = EmotionTaxonomy.color(dominant);
    final visible = EmotionTaxonomy.visibleEmotions(insight.emotionScores);

    final (sentColor, sentIcon) = switch (insight.sentiment) {
      'POSITIVE' => (const Color(0xFF34D399), Icons.sentiment_satisfied_alt_rounded),
      'NEGATIVE' => (const Color(0xFFEF4444), Icons.sentiment_very_dissatisfied),
      _ => (const Color(0xFF6366F1), Icons.sentiment_neutral),
    };

    final sentLabel = switch (insight.sentiment) {
      'POSITIVE' => 'Positivo',
      'NEGATIVE' => 'Negativo',
      _ => 'Neutro',
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: dominant emotion + sentiment badge
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
                        dominantLabel,
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
                            decoration: BoxDecoration(
                              color: dominantColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (visible.isNotEmpty)
                            Text(
                              'emocion predominante · ${(visible.first.value * 100).round()}%',
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
                    color: sentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sentColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sentIcon, color: sentColor, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        sentLabel,
                        style: TextStyle(
                          color: sentColor,
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

          // Emotion spectrum bar
          if (visible.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: visible.map((e) {
                      return Expanded(
                        flex: (e.value * 100).round(),
                        child: Container(color: EmotionTaxonomy.color(e.key)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Emotion chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visible.map((e) {
                final color = EmotionTaxonomy.color(e.key);
                final label = EmotionTaxonomy.label(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(e.value * 100).round()}%',
                        style: TextStyle(
                          color: color,
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
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
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
                  const Icon(Icons.chevron_right, color: Color(0xFF6366F1), size: 18),
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

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, size: 64, color: Color(0xFF6366F1)),
      ),
    );
  }
}

class _TrendChartSection extends ConsumerStatefulWidget {
  const _TrendChartSection();

  @override
  ConsumerState<_TrendChartSection> createState() => _TrendChartSectionState();
}

class _TrendChartSectionState extends ConsumerState<_TrendChartSection> {
  List<AlignmentHistoryEntry>? _history;
  bool _loading = true;
  bool _loadTriggered = false;

  void _loadHistory() {
    if (_loadTriggered) return;
    _loadTriggered = true;
    final repo = ref.read(goalsRepositoryProvider);
    repo.getAlignmentHistory(days: 30).then((history) {
      if (mounted) setState(() { _history = history; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trigger load on first build (ref is available here, not in initState)
    _loadHistory();

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }
    if (_history == null || _history!.isEmpty) return const SizedBox.shrink();
    return AlignmentTrendChart(history: _history!);
  }
}
