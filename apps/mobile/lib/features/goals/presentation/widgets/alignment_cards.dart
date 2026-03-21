import 'package:flutter/material.dart';
import '../../domain/entities/goal_alignment_entity.dart';

class AlignmentCards extends StatelessWidget {
  const AlignmentCards({super.key, required this.alignments});
  final List<GoalAlignmentEntity> alignments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final a in alignments) ...[
          _AlignmentCard(alignment: a),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _AlignmentCard extends StatelessWidget {
  const _AlignmentCard({required this.alignment});
  final GoalAlignmentEntity alignment;

  Color get _color => switch (alignment.level) {
        AlignmentLevel.clearProgress => const Color(0xFF34D399),
        AlignmentLevel.partialProgress => const Color(0xFFFBBF24),
        AlignmentLevel.noEvidence => const Color(0xFF6B7280),
        AlignmentLevel.deviation => const Color(0xFFEF4444),
      };

  IconData get _icon => switch (alignment.level) {
        AlignmentLevel.clearProgress => Icons.check_circle,
        AlignmentLevel.partialProgress => Icons.timelapse,
        AlignmentLevel.noEvidence => Icons.help_outline,
        AlignmentLevel.deviation => Icons.warning_amber,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151518),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alignment.goalTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alignment.level.label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alignment.reason,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
