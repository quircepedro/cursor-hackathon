import 'package:flutter/material.dart';

import '../../domain/entities/emotion_taxonomy.dart';
import '../../domain/entities/insight_entity.dart';

/// Widget que muestra la emoción diaria: emoción dominante, barra espectro
/// y chips de emociones visibles (>= 10% normalizado).
/// Usa la taxonomía fija de 12 emociones del backend.
class EmotionDailyWidget extends StatelessWidget {
  const EmotionDailyWidget({super.key, required this.insight});

  final InsightEntity insight;

  @override
  Widget build(BuildContext context) {
    final dominant = insight.dominantEmotion;
    final dominantLabel = EmotionTaxonomy.label(dominant);
    final dominantColor = EmotionTaxonomy.color(dominant);
    final visible = EmotionTaxonomy.visibleEmotions(insight.emotionScores);

    final (sentColor, sentIcon) = switch (insight.sentiment) {
      'POSITIVE' => (
          const Color(0xFF34D399),
          Icons.sentiment_satisfied_alt_rounded,
        ),
      'NEGATIVE' => (
          const Color(0xFFEF4444),
          Icons.sentiment_very_dissatisfied,
        ),
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
          // ── Dominant emotion + sentiment badge ──────────────────────────
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
                              'emoción predominante · ${(visible.first.value * 100).round()}%',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: sentColor.withValues(alpha: 0.25)),
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

          // ── Emotion spectrum bar ─────────────────────────────────────────
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
                        child:
                            Container(color: EmotionTaxonomy.color(e.key)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Emotion chips ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visible.map((e) {
                final color = EmotionTaxonomy.color(e.key);
                final label = EmotionTaxonomy.label(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
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
