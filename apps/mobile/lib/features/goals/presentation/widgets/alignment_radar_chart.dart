import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/goal_alignment_entity.dart';

class AlignmentRadarChart extends StatelessWidget {
  const AlignmentRadarChart({super.key, required this.alignments});
  final List<GoalAlignmentEntity> alignments;

  @override
  Widget build(BuildContext context) {
    if (alignments.length < 3) return const SizedBox.shrink();

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
          Text(
            'PERFIL DE ALINEACION',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    dataEntries: alignments
                        .map((a) => RadarEntry(value: a.score))
                        .toList(),
                    fillColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderColor: const Color(0xFF6366F1),
                    borderWidth: 2,
                    entryRadius: 4,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                tickBorderData:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                gridBorderData:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                tickCount: 4,
                ticksTextStyle: const TextStyle(fontSize: 0),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
                getTitle: (index, angle) {
                  if (index >= alignments.length) return const RadarChartTitle(text: '');
                  final title = alignments[index].goalTitle;
                  return RadarChartTitle(
                    text: title.length > 10
                        ? '${title.substring(0, 10)}...'
                        : title,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
