import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/alignment_history_entity.dart';

const _lineColors = [
  Color(0xFF6366F1), // overall / goal 0
  Color(0xFF34D399), // goal 1
  Color(0xFFFBBF24), // goal 2
  Color(0xFFEF4444), // goal 3
];

class AlignmentTrendChart extends StatelessWidget {
  const AlignmentTrendChart({super.key, required this.history});
  final List<AlignmentHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final maxX = history.length <= 1
        ? 1.0
        : (history.length - 1).toDouble();

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
            'TENDENCIA',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: 1,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value * 100).toInt()}%',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxX > 0 ? maxX / 4 : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.round().clamp(0, history.length - 1);
                        if (history.isEmpty) return const SizedBox.shrink();
                        // Show label for first, last, and middle
                        if (idx != 0 &&
                            idx != history.length - 1 &&
                            idx != history.length ~/ 2) {
                          return const SizedBox.shrink();
                        }
                        final d = history[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: _buildLines(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('Global', _lineColors[0]),
              if (history.first.goals.isNotEmpty)
                for (var i = 0; i < history.first.goals.length && i < 4; i++)
                  _legend(
                    history.first.goals[i].title,
                    _lineColors[(i + 1) % _lineColors.length],
                  ),
            ],
          ),
        ],
      ),
    );
  }

  double _clampScore(double v) => v.clamp(0.0, 1.0);

  List<FlSpot> _overallSpots() {
    if (history.isEmpty) return [];
    if (history.length == 1) {
      final y = _clampScore(history[0].overallScore);
      return [FlSpot(0, y), FlSpot(1, y)];
    }
    return List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), _clampScore(history[i].overallScore)),
    );
  }

  List<FlSpot> _goalSpots(int g) {
    if (history.isEmpty) return [];
    if (history.length == 1) {
      final score = g < history[0].goals.length
          ? _clampScore(history[0].goals[g].score)
          : 0.0;
      return [FlSpot(0, score), FlSpot(1, score)];
    }
    return List.generate(history.length, (i) {
      if (g < history[i].goals.length) {
        return FlSpot(i.toDouble(), _clampScore(history[i].goals[g].score));
      }
      return FlSpot(i.toDouble(), 0);
    });
  }

  List<LineChartBarData> _buildLines() {
    final lines = <LineChartBarData>[];
    final canCurve = history.length >= 2;

    lines.add(LineChartBarData(
      spots: _overallSpots(),
      isCurved: canCurve,
      color: _lineColors[0],
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: _lineColors[0].withValues(alpha: 0.1),
      ),
    ));

    if (history.isNotEmpty) {
      final goalCount = history.first.goals.length;
      for (var g = 0; g < goalCount && g < 4; g++) {
        lines.add(LineChartBarData(
          spots: _goalSpots(g),
          isCurved: canCurve,
          color: _lineColors[(g + 1) % _lineColors.length].withValues(alpha: 0.6),
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          dashArray: [5, 3],
        ));
      }
    }

    return lines;
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label.length > 15 ? '${label.substring(0, 15)}...' : label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }
}
