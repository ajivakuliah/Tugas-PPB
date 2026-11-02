import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../ui.dart';

class AqiGauge extends StatefulWidget {
  final int aqi;
  const AqiGauge({super.key, required this.aqi});

  @override
  State<AqiGauge> createState() => _AqiGaugeState();
}

class _AqiGaugeState extends State<AqiGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.aqi.toDouble()),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final lv = levelFor(v.round());
        return SizedBox(
          width: 290,
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: const Size(290, 290), painter: _GaugePainter(v, _pulse)),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('US AQI', style: ts(12, color: Colors.white70, spacing: 3)),
                  Text('${v.round()}', style: ts(84, weight: FontWeight.w800, height: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 170),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: lv.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: lv.color.withOpacity(0.6)),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(lv.label,
                          style: ts(13, weight: FontWeight.w700, color: lv.color)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Animation<double> pulse;
  _GaugePainter(this.value, this.pulse) : super(repaint: pulse);

  static const double _start = 5 * math.pi / 6;
  static const double _sweep = 4 * math.pi / 3;

  void _label(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: ts(9, weight: FontWeight.w600, color: Colors.white54)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 26;
    final rect = Rect.fromCircle(center: c, radius: r);
    final p = pulse.value;

    // Jalur
    canvas.drawArc(
      rect, _start, _sweep, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.14),
    );

    final v = value.clamp(0, 300).toDouble();
    final prog = _sweep * (v / 300);

    final gradient = SweepGradient(
      colors: [
        aqiLevels[0].color,
        aqiLevels[1].color,
        aqiLevels[2].color,
        aqiLevels[3].color,
        aqiLevels[4].color,
        aqiLevels[5].color,
        aqiLevels[5].color,
      ],
      stops: const [0, 0.1111, 0.2222, 0.3333, 0.4444, 0.6667, 1.0],
      transform: const GradientRotation(_start),
    );
    final shader = gradient.createShader(rect);

    if (prog > 0.01) {
      // Cahaya yang "bernapas"
      canvas.drawArc(
        rect, _start, prog, false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24 + 6 * p
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + 6 * p)
          ..colorFilter = const ColorFilter.mode(Color.fromRGBO(255, 255, 255, 0.5), BlendMode.modulate),
      );
      // Busur utama
      canvas.drawArc(
        rect, _start, prog, false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round,
      );
    }

    // Titik penanda
    final ang = _start + prog;
    final pos = c + Offset(math.cos(ang), math.sin(ang)) * r;
    canvas.drawCircle(
      pos, 16 + 2 * p,
      Paint()
        ..color = levelFor(v.round()).color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(pos, 13, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 7, Paint()..color = levelFor(v.round()).color);

    // Angka skala
    for (final mark in [0.0, 50.0, 100.0, 150.0, 200.0, 300.0]) {
      final a = _start + _sweep * (mark / 300);
      _label(canvas, mark.toInt().toString(), c + Offset(math.cos(a), math.sin(a)) * (r + 25));
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}
