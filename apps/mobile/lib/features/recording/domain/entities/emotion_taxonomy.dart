import 'package:flutter/material.dart';

class EmotionInfo {
  const EmotionInfo({
    required this.key,
    required this.label,
    required this.color,
  });

  final String key;
  final String label;
  final Color color;
}

/// Fixed 12-emotion taxonomy based on Plutchik + common journaling emotions.
/// Keys match the backend analysis service exactly.
class EmotionTaxonomy {
  EmotionTaxonomy._();

  static const _data = <String, (String, Color)>{
    'joy': ('Alegria', Color(0xFF34D399)),
    'sadness': ('Tristeza', Color(0xFF60A5FA)),
    'anger': ('Ira', Color(0xFFEF4444)),
    'fear': ('Miedo', Color(0xFFA78BFA)),
    'surprise': ('Sorpresa', Color(0xFFF472B6)),
    'disgust': ('Asco', Color(0xFF6B7280)),
    'anxiety': ('Ansiedad', Color(0xFFFB923C)),
    'calm': ('Calma', Color(0xFF38BDF8)),
    'gratitude': ('Gratitud', Color(0xFF34D399)),
    'pride': ('Orgullo', Color(0xFFFBBF24)),
    'nostalgia': ('Nostalgia', Color(0xFFC084FC)),
    'frustration': ('Frustracion', Color(0xFFF87171)),
  };

  /// Get the label for an emotion key. Falls back to the key itself.
  static String label(String key) => _data[key]?.$1 ?? key;

  /// Get the color for an emotion key. Falls back to grey.
  static Color color(String key) =>
      _data[key]?.$2 ?? const Color(0xFF6B7280);

  /// Get full info for an emotion key.
  static EmotionInfo? info(String key) {
    final entry = _data[key];
    if (entry == null) return null;
    return EmotionInfo(key: key, label: entry.$1, color: entry.$2);
  }

  /// Filter and sort emotion scores: only those >= [threshold], sorted descending.
  static List<MapEntry<String, double>> visibleEmotions(
    Map<String, double> scores, {
    double threshold = 0.10,
  }) {
    return scores.entries
        .where((e) => e.value >= threshold && _data.containsKey(e.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}
