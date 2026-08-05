import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Thin circular progress ring (white on coloured headers).
class SpendingRing extends StatelessWidget {
  const SpendingRing({
    super.key,
    required this.spent,
    required this.budget,
    this.size = 80,
  });

  final int spent;
  final int budget;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = math.min(spent / budget, 1).toDouble();
    final stroke = size * 0.075;
    final radius = (size - stroke) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(pct: pct, stroke: stroke, radius: radius),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.pct,
    required this.stroke,
    required this.radius,
  });

  final double pct;
  final double stroke;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.15);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85);

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.pct != pct || oldDelegate.radius != radius;
}
