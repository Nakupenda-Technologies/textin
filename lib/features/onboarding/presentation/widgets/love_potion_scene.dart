import 'dart:math';

import 'package:flutter/material.dart';

class LovePotionScene extends StatefulWidget {
  const LovePotionScene({super.key});

  @override
  State<LovePotionScene> createState() => _LovePotionSceneState();
}

class _LovePotionSceneState extends State<LovePotionScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _LovePotionPainter.loopMs),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 846 / 1024,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/love_potion.png',
                fit: BoxFit.fill,
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _LovePotionPainter(progress: _controller.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LovePotionPainter extends CustomPainter {
  const _LovePotionPainter({required this.progress});

  final double progress;

  static const int loopMs = 6000;
  static const Color _green = Color(0xFF3ECF8E);

  static const _hearts = [
    (x: 0.38, y: 0.58, size: 13.0, durationMs: 3200, delayMs: 0),
    (x: 0.44, y: 0.60, size: 10.0, durationMs: 2800, delayMs: 700),
    (x: 0.35, y: 0.56, size: 11.0, durationMs: 3500, delayMs: 1400),
    (x: 0.48, y: 0.58, size: 9.0, durationMs: 2600, delayMs: 2100),
    (x: 0.41, y: 0.62, size: 12.0, durationMs: 3000, delayMs: 350),
  ];

  static const _sparkles = [
    (x: 0.52, y: 0.565, durationMs: 1200, delayMs: 0),
    (x: 0.45, y: 0.535, durationMs: 1500, delayMs: 400),
    (x: 0.38, y: 0.575, durationMs: 1000, delayMs: 800),
    (x: 0.55, y: 0.600, durationMs: 1300, delayMs: 200),
    (x: 0.34, y: 0.545, durationMs: 1100, delayMs: 600),
    (x: 0.50, y: 0.515, durationMs: 1400, delayMs: 1000),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final elapsedMs = progress * loopMs;
    final scale = size.width / 440;

    for (final heart in _hearts) {
      final t =
          ((elapsedMs + heart.delayMs) % heart.durationMs) / heart.durationMs;
      final alpha = t < 0.15
          ? t / 0.15
          : t < 0.75
          ? 1.0 - (t - 0.15) * 0.4
          : max(0.0, 1.0 - (t - 0.75) / 0.25);

      _drawHeart(
        canvas,
        Offset(
          heart.x * size.width,
          heart.y * size.height - t * size.height * 0.32,
        ),
        heart.size * scale,
        alpha,
      );
    }

    for (final sparkle in _sparkles) {
      final t =
          ((elapsedMs + sparkle.delayMs) % sparkle.durationMs) /
          sparkle.durationMs;
      final alpha = t < 0.25
          ? t / 0.25
          : t < 0.55
          ? 1.0
          : t < 0.80
          ? 1.0 - (t - 0.55) / 0.25
          : 0.0;

      _drawSparkle(
        canvas,
        Offset(sparkle.x * size.width, sparkle.y * size.height),
        7 * scale * (0.7 + 0.6 * sin(t * pi)),
        alpha,
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double size, double alpha) {
    if (alpha <= 0) return;
    final path = Path()
      ..moveTo(c.dx, c.dy + size * 0.95)
      ..cubicTo(
        c.dx - size,
        c.dy + size * 0.6,
        c.dx - size,
        c.dy - size * 0.1,
        c.dx,
        c.dy + size * 0.25,
      )
      ..cubicTo(
        c.dx + size,
        c.dy - size * 0.1,
        c.dx + size,
        c.dy + size * 0.6,
        c.dx,
        c.dy + size * 0.95,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = _green.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
  }

  void _drawSparkle(Canvas canvas, Offset c, double size, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()
      ..color = _green.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..strokeWidth = max(1.0, size * 0.18)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final angle = (pi / 2) * i;
      canvas.drawLine(
        c,
        c + Offset(cos(angle) * size, sin(angle) * size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LovePotionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
