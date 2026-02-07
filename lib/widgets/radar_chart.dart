import 'dart:math';
import 'package:flutter/material.dart';
import '../models/skill.dart';

class RadarChart extends StatelessWidget {
  final List<Skill> skills;
  final double maxValue;

  const RadarChart({super.key, required this.skills, this.maxValue = 10.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 300),
      painter: _RadarChartPainter(
        skills: skills,
        maxValue: maxValue,
        colorScheme: Theme.of(context).colorScheme,
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<Skill> skills;
  final double maxValue;
  final ColorScheme colorScheme;

  _RadarChartPainter({
    required this.skills,
    required this.maxValue,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (skills.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.8;
    final angleStep = (2 * pi) / skills.length;

    // Draw background concentric polygons
    final bgPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 5; i++) {
      final currentRadius = radius * (i / 5);
      final path = Path();
      for (var j = 0; j < skills.length; j++) {
        final angle = j * angleStep - pi / 2;
        final x = center.dx + currentRadius * cos(angle);
        final y = center.dy + currentRadius * sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, bgPaint);
    }

    // Draw axis lines and labels
    final axisPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < skills.length; i++) {
      final angle = i * angleStep - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label
      textPainter.text = TextSpan(
        text: skills[i].name,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final labelX =
          center.dx + (radius + 20) * cos(angle) - textPainter.width / 2;
      final labelY =
          center.dy + (radius + 20) * sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    // Draw the skill area
    final areaPaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final areaPath = Path();
    for (var i = 0; i < skills.length; i++) {
      final skillValue = min(
        skills[i].level.toDouble() + skills[i].progressInLevel,
        maxValue,
      );
      final currentRadius = radius * (skillValue / maxValue);
      final angle = i * angleStep - pi / 2;
      final x = center.dx + currentRadius * cos(angle);
      final y = center.dy + currentRadius * sin(angle);

      if (i == 0) {
        areaPath.moveTo(x, y);
      } else {
        areaPath.lineTo(x, y);
      }
    }
    areaPath.close();
    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(areaPath, borderPaint);

    // Draw points
    final pointPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < skills.length; i++) {
      final skillValue = min(
        skills[i].level.toDouble() + skills[i].progressInLevel,
        maxValue,
      );
      final currentRadius = radius * (skillValue / maxValue);
      final angle = i * angleStep - pi / 2;
      final x = center.dx + currentRadius * cos(angle);
      final y = center.dy + currentRadius * sin(angle);

      pointPaint.color = skills[i].color;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
