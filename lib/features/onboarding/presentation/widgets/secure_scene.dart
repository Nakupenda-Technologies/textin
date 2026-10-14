import 'dart:math';

import 'package:flutter/material.dart';

class SecureScene extends StatefulWidget {
  const SecureScene({super.key});

  @override
  State<SecureScene> createState() => _SecureSceneState();
}

class _SecureSceneState extends State<SecureScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
        aspectRatio:
            _HexGlowPainter.naturalWidth / _HexGlowPainter.naturalHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/secure_animation.png',
                fit: BoxFit.fill,
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _HexGlowPainter(progress: _controller.value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _Hex = ({
  double cx,
  double cy,
  double r,
  double speed,
  double arcFraction,
  double delay,
});

class _HexGlowPainter extends CustomPainter {
  const _HexGlowPainter({required this.progress});

  final double progress;

  static const double naturalWidth = 720;
  static const double naturalHeight = 1003;
  static const double _rotation = pi / 6;
  static const int _steps = 60;

  // Hexagon centres and radii are measured from secure_animation.png at its
  // natural 720x1003 size so the glowing arcs trace the drawn outlines.
  static const List<_Hex> _hexes = [
    (cx: 490, cy: 268, r: 215, speed: 0.55, arcFraction: 0.25, delay: 0.0),
    (cx: 200, cy: 631, r: 112, speed: 1.0, arcFraction: 0.35, delay: 0.33),
    (cx: 100, cy: 801, r: 111, speed: 1.0, arcFraction: 0.35, delay: 0.66),
    (cx: 200, cy: 973, r: 111.5, speed: 1.0, arcFraction: 0.35, delay: 0.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / naturalWidth;
    final scaleY = size.height / naturalHeight;

    for (final hex in _hexes) {
      final points = List.generate(6, (i) {
        final angle = (pi / 3) * i + _rotation;
        return Offset(
          hex.cx * scale + hex.r * scale * cos(angle),
          hex.cy * scaleY + hex.r * scale * sin(angle),
        );
      });
      final segments = [
        for (var i = 0; i < points.length; i++)
          (points[(i + 1) % points.length] - points[i]).distance,
      ];
      final perimeter = segments.reduce((a, b) => a + b);
      final start = ((progress * hex.speed) + hex.delay) % 1.0 * perimeter;
      final arcLength = perimeter * hex.arcFraction;

      final path = Path();
      for (var s = 0; s <= _steps; s++) {
        final t = s / _steps;
        final position = _pointAt(
          points,
          segments,
          perimeter,
          start + t * arcLength,
        );
        final alpha = pow(t, 0.3).toDouble();
        final glowRadius = scale + t * scale * 6;

        canvas.drawCircle(
          position,
          glowRadius,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    Color.fromRGBO(255, 60, 60, alpha * 0.9),
                    Color.fromRGBO(255, 60, 60, alpha * 0.4),
                    const Color.fromRGBO(255, 60, 60, 0),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ).createShader(
                  Rect.fromCircle(center: position, radius: glowRadius),
                ),
        );

        s == 0
            ? path.moveTo(position.dx, position.dy)
            : path.lineTo(position.dx, position.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = const Color.fromRGBO(255, 100, 100, 0.95)
          ..strokeWidth = scale * 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  Offset _pointAt(
    List<Offset> points,
    List<double> segments,
    double perimeter,
    double distance,
  ) {
    var d = distance % perimeter;
    for (var i = 0; i < points.length; i++) {
      if (d <= segments[i]) {
        return Offset.lerp(
          points[i],
          points[(i + 1) % points.length],
          d / segments[i],
        )!;
      }
      d -= segments[i];
    }
    return points.first;
  }

  @override
  bool shouldRepaint(_HexGlowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
