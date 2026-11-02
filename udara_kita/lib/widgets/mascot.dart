import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../aqi_utils.dart';

/// Maskot awan "Awan" — ekspresinya berubah mengikuti kualitas udara.
class Mascot extends StatefulWidget {
  final int aqi;
  final double size;
  const Mascot({super.key, required this.aqi, this.size = 110});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final float = math.sin(_c.value * 2 * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, float),
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _MascotPainter(widget.aqi, _c.value),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final int aqi;
  final double t;
  _MascotPainter(this.aqi, this.t);

  static const _bodyColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF6DD),
    Color(0xFFF0E2D0),
    Color(0xFFCFD2DC),
    Color(0xFFB0A8C4),
    Color(0xFF948096),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lv = levelIndex(aqi);
    const inkColor = Color(0xFF2B2D42);
    final ink = Paint()..color = inkColor;
    final stroke = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    // Bayangan
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.93), width: w * 0.5, height: h * 0.07),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Badan awan
    final base = _bodyColors[lv];
    final body = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.30, h * 0.58), radius: w * 0.20))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.50, h * 0.44), radius: w * 0.27))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.72, h * 0.58), radius: w * 0.21))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.18, h * 0.56, w * 0.84, h * 0.80),
        Radius.circular(w * 0.12),
      ));
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, Color.lerp(base, Colors.black, 0.14)!],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Mata
    final ey = h * 0.58;
    final blink = t > 0.93 && t < 0.97;
    for (final s in [-1.0, 1.0]) {
      final cx = w * (0.5 + s * 0.10);
      if (lv >= 4) {
        final p = Path()
          ..moveTo(cx + s * w * 0.025, ey - h * 0.03)
          ..lineTo(cx - s * w * 0.02, ey)
          ..lineTo(cx + s * w * 0.025, ey + h * 0.03);
        canvas.drawPath(p, stroke);
      } else {
        final eh = blink ? h * 0.01 : h * 0.075;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, ey), width: w * 0.055, height: eh), ink);
        if (!blink) {
          canvas.drawCircle(
              Offset(cx + w * 0.008, ey - h * 0.018), w * 0.011, Paint()..color = Colors.white);
        }
      }
    }

    // Alis khawatir
    if (lv == 3) {
      canvas.drawLine(Offset(w * 0.35, h * 0.53), Offset(w * 0.44, h * 0.50), stroke);
      canvas.drawLine(Offset(w * 0.56, h * 0.50), Offset(w * 0.65, h * 0.53), stroke);
    }

    // Pipi
    if (lv <= 1) {
      final cheek = Paint()..color = const Color(0xFFFF8FA3).withOpacity(0.55);
      canvas.drawCircle(Offset(w * 0.32, h * 0.66), w * 0.035, cheek);
      canvas.drawCircle(Offset(w * 0.68, h * 0.66), w * 0.035, cheek);
    }

    // Mulut / masker
    if (lv == 0) {
      final r = Rect.fromCenter(center: Offset(w * 0.5, h * 0.645), width: w * 0.13, height: h * 0.09);
      canvas.drawArc(r, 0.2, math.pi - 0.4, false, stroke);
    } else if (lv == 1) {
      final r = Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.09, height: h * 0.05);
      canvas.drawArc(r, 0.2, math.pi - 0.4, false, stroke);
    } else {
      final mask = RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.35, h * 0.625, w * 0.65, h * 0.76),
        Radius.circular(w * 0.04),
      );
      const line = Color(0xFF8CC7E8);
      canvas.drawRRect(mask, Paint()..color = const Color(0xFFDDF3FF));
      canvas.drawRRect(
        mask,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012,
      );
      final pleat = Paint()
        ..color = line
        ..strokeWidth = w * 0.008;
      for (final dy in [0.665, 0.695, 0.725]) {
        canvas.drawLine(Offset(w * 0.37, h * dy), Offset(w * 0.63, h * dy), pleat);
      }
      canvas.drawLine(Offset(w * 0.35, h * 0.66), Offset(w * 0.29, h * 0.63), pleat);
      canvas.drawLine(Offset(w * 0.65, h * 0.66), Offset(w * 0.71, h * 0.63), pleat);
    }

    // Keringat
    if (lv >= 3) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.76, h * 0.47), width: w * 0.045, height: h * 0.07),
        Paint()..color = const Color(0xFF7FD6FF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => true;
}
