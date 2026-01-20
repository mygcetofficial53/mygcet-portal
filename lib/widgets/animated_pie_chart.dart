import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

/// Animated Pie Chart Widget for displaying attendance data
class AnimatedPieChart extends StatefulWidget {
  final List<PieChartItem> items;
  final double size;
  final bool showLabels;
  final bool showPercentage;
  final Widget? centerWidget;

  const AnimatedPieChart({
    super.key,
    required this.items,
    this.size = 200,
    this.showLabels = true,
    this.showPercentage = true,
    this.centerWidget,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: widget.size * 0.25,
                      sections: _buildSections(),
                    ),
                  ),
                  if (widget.centerWidget != null) widget.centerWidget!,
                ],
              ),
            ),
            if (widget.showLabels) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.items.map((item) {
                  return _Legend(
                    color: item.color,
                    label: item.label,
                    value: widget.showPercentage
                        ? '${(item.value * _animation.value).toStringAsFixed(1)}%'
                        : null,
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(widget.items.length, (index) {
      final item = widget.items[index];
      final isTouched = index == _touchedIndex;
      final radius = isTouched ? widget.size * 0.28 : widget.size * 0.22;

      return PieChartSectionData(
        color: item.color,
        value: item.value * _animation.value,
        title: widget.showPercentage && isTouched
            ? '${item.value.toStringAsFixed(1)}%'
            : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? _Badge(
                label: item.label,
                color: item.color,
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    });
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String? value;

  const _Legend({
    required this.color,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value != null ? '$label: $value' : label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Data model for pie chart items
class PieChartItem {
  final String label;
  final double value;
  final Color color;

  const PieChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Helper to create attendance-based pie chart items
List<PieChartItem> createAttendanceChartItems({
  required double attendedPercentage,
}) {
  return [
    PieChartItem(
      label: 'Attended',
      value: attendedPercentage,
      color: AppTheme.successGreen,
    ),
    PieChartItem(
      label: 'Missed',
      value: 100 - attendedPercentage,
      color: AppTheme.dangerRed.withOpacity(0.6),
    ),
  ];
}
