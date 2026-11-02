import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Particle {
  final double x, y, size, speed, phase;
  const _Particle(this.x, this.y, this.size, this.speed, this.phase);
}

/// Langit animasi: warna, awan, matahari/bulan, bintang, dan partikel
/// berubah mengikuti tingkat polusi serta waktu setempat (siang/malam).
class SkyBackground extends StatefulWidget {
  final int aqi;
  final int hour;
  final List<Color> gradient;
  const SkyBackground({
    super.key,
    required this.aqi,
    required this.hour,
    required this.gradient,
  });

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _ps;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    final r = math.Random(7);
    _ps = List.generate(
      80,
      (_) => _Particle(r.nextDouble(), r.nextDouble(), 1.5 + r.nextDouble() * 4,
          r.nextDouble() * 2.5, r.nextDouble() * math.pi * 2),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final night = widget.hour < 6 || widget.hour >= 18;
    final colors = night
        ? [for (final c in widget.gradient) Color.lerp(c, const Color(0xFF040818), 0.55)!]
        : widget.gradient;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _SkyPainter(_c, widget.aqi, night, _ps),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final Animation<double> anim;
  final int aqi;
  final bool night;
  final List<_Particle> ps;

  _SkyPainter(this.anim, this.aqi, this.night, this.ps) : super(repaint: anim);

  void _cloud(Canvas c, Offset o, double s, Paint p) {
    c.drawOval(Rect.fromCenter(center: o, width: 150 * s, height: 46 * s), p);
    c.drawOval(Rect.fromCenter(center: o + Offset(-34 * s, -14 * s), width: 90 * s, height: 50 * s), p);
    c.drawOval(Rect.fromCenter(center: o + Offset(30 * s, -18 * s), width: 100 * s, height: 56 * s), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final hazy = aqi > 100;
    final dim = (1 - aqi / 350).clamp(0.25, 1.0).toDouble();

    // Bintang berkelap-kelip (malam, selama langit tidak terlalu berkabut)
    if (night && aqi <= 150) {
      final starAlpha = (1 - aqi / 150).clamp(0.2, 1.0).toDouble();
      for (var i = 0; i < 46; i++) {
        final p = ps[i];
        final tw = 0.5 + 0.5 * math.sin(2 * math.pi * t * (2 + (i % 3)) + p.phase);
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height * 0.6),
          0.6 + p.size * 0.25,
          Paint()..color = Colors.white.withOpacity((0.15 + 0.55 * tw) * starAlpha),
        );
      }
    }

    // Matahari / bulan: meredup dan menguning saat polusi naik
    final center = Offset(size.width * 0.8, size.height * 0.11);
    if (night) {
      canvas.drawCircle(
        center,
        130,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFBFD7FF).withOpacity(0.30 * dim), const Color(0x00BFD7FF)],
          ).createShader(Rect.fromCircle(center: center, radius: 130)),
      );
      canvas.drawCircle(center, 20, Paint()..color = const Color(0xFFF4F1DE).withOpacity(0.95 * dim));
      final crater = Paint()..color = const Color(0xFFB9B39A).withOpacity(0.25 * dim);
      canvas.drawCircle(center + const Offset(-6, -4), 4, crater);
      canvas.drawCircle(center + const Offset(6, 6), 3, crater);
    } else {
      final sun = Color.lerp(const Color(0xFFFFE9A8), const Color(0xFFFF8A4C),
          (aqi / 300).clamp(0.0, 1.0).toDouble())!;
      canvas.drawCircle(
        center,
        190,
        Paint()
          ..shader = RadialGradient(
            colors: [sun.withOpacity(0.5 * dim), sun.withOpacity(0)],
          ).createShader(Rect.fromCircle(center: center, radius: 190)),
      );
      canvas.drawCircle(center, 26, Paint()..color = sun.withOpacity(0.92 * dim));
    }

    // Awan melayang
    final cloudAlpha = hazy ? (0.16 + aqi / 2000).clamp(0.0, 0.3).toDouble() : 0.09;
    final cloudPaint = Paint()
      ..color = (hazy ? const Color(0xFFD8C3A0) : Colors.white).withOpacity(cloudAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    const cloudY = [0.14, 0.30, 0.46];
    const cloudBase = [0.1, 0.45, 0.8];
    for (var i = 0; i < 3; i++) {
      final k = 1 + (i % 2);
      final x = ((cloudBase[i] + t * k) % 1.0) * size.width * 1.5 - size.width * 0.25;
      _cloud(canvas, Offset(x, size.height * cloudY[i]), 0.9 + i * 0.25, cloudPaint);
    }

    // Partikel: debu pekat saat tercemar, kilau halus saat bersih
    final n = (16 + aqi / 5).clamp(16, 48).round();
    for (var i = 0; i < n; i++) {
      final p = ps[i];
      final k = 1 + p.speed.floor();
      final y = (p.y - t * k) % 1.0;
      final x = p.x + 0.04 * math.sin(2 * math.pi * t * k + p.phase);
      final pos = Offset(x * size.width, y * size.height);

      if (hazy) {
        canvas.drawCircle(
          pos,
          p.size * 2.6,
          Paint()
            ..color = const Color(0xFFE0C9A6).withOpacity(0.09 + (aqi / 2500).clamp(0.0, 0.1))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      } else {
        canvas.drawCircle(
          pos,
          p.size,
          Paint()
            ..color = Colors.white.withOpacity(night ? 0.12 : 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.aqi != aqi || old.night != night;
}
