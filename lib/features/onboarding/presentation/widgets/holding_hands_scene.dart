import 'package:flutter/material.dart';

class HoldingHandsScene extends StatefulWidget {
  const HoldingHandsScene({super.key});

  @override
  State<HoldingHandsScene> createState() => _HoldingHandsSceneState();
}

class _HoldingHandsSceneState extends State<HoldingHandsScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  static const _hearts = [
    (left: 0.44, top: 0.13, size: 28.0, stroke: 1.4, phase: 0.0),
    (left: 0.10, top: 0.40, size: 48.0, stroke: 1.8, phase: 0.32),
    (left: 0.72, top: 0.46, size: 36.0, stroke: 1.6, phase: 0.64),
    (left: 0.68, top: 0.58, size: 24.0, stroke: 1.3, phase: 0.16),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 932 / 1104,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/holding_hands.png',
                  fit: BoxFit.contain,
                ),
              ),
              for (final heart in _hearts)
                Positioned(
                  left: constraints.maxWidth * heart.left,
                  top: constraints.maxHeight * heart.top,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final t = (_controller.value + heart.phase) % 1.0;
                      return Transform.scale(
                        scale: _scale(t),
                        child: Opacity(opacity: _opacity(t), child: child),
                      );
                    },
                    child: CustomPaint(
                      size: Size.square(heart.size),
                      painter: _HeartOutlinePainter(strokeWidth: heart.stroke),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _opacity(double t) {
    if (t < 0.12) return t / 0.12;
    if (t < 0.80) return 1.0;
    return 1.0 - (t - 0.80) / 0.20;
  }

  double _scale(double t) {
    if (t < 0.15) return _lerp(0.3, 1.3, t / 0.15);
    if (t < 0.28) return _lerp(1.3, 0.85, (t - 0.15) / 0.13);
    if (t < 0.42) return _lerp(0.85, 1.15, (t - 0.28) / 0.14);
    if (t < 0.56) return _lerp(1.15, 0.95, (t - 0.42) / 0.14);
    if (t < 0.70) return _lerp(0.95, 1.05, (t - 0.56) / 0.14);
    if (t < 0.85) return 1.0;
    return _lerp(1.0, 0.5, (t - 0.85) / 0.15);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _HeartOutlinePainter extends CustomPainter {
  const _HeartOutlinePainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..cubicTo(w * 0.0, h * 0.65, w * 0.0, h * 0.20, w * 0.25, h * 0.10)
      ..cubicTo(w * 0.38, h * 0.03, w * 0.50, h * 0.18, w * 0.50, h * 0.30)
      ..cubicTo(w * 0.50, h * 0.18, w * 0.62, h * 0.03, w * 0.75, h * 0.10)
      ..cubicTo(w * 1.0, h * 0.20, w * 1.0, h * 0.65, w * 0.5, h * 0.95)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8A0B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_HeartOutlinePainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}
