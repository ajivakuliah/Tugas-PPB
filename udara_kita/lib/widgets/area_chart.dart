import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../models.dart';
import '../ui.dart';

/// Grafik area halus yang bisa disentuh/digeser untuk melihat nilai tiap jam.
class AreaChart extends StatefulWidget {
  final List<HourPoint> points;
  final double height;
  const AreaChart({super.key, required this.points, this.height = 200});

  @override
  State<AreaChart> createState() => _AreaChartState();
}

class _AreaChartState extends State<AreaChart> {
  int? _sel;

  void _update(double dx, double w) {
    final n = widget.points.length;
    if (n < 2) return;
    final i = ((dx / w).clamp(0.0, 1.0) * (n - 1)).round();
    if (i != _sel) setState(() => _sel = i);
  }

  @override
  void didUpdateWidget(covariant AreaChart old) {
    super.didUpdateWidget(old);
    if (_sel != null && _sel! >= widget.points.length) _sel = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final w = cons.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _update(d.localPosition.dx, w),
        onHorizontalDragStart: (d) => _update(d.localPosition.dx, w),
        onHorizontalDragUpdate: (d) => _update(d.localPosition.dx, w),
        child: SizedBox(
          height: widget.height,
          width: w,
          child: CustomPaint(painter: _AreaPainter(widget.points, _sel)),
        ),
      );
    });
  }
}

class _AreaPainter extends CustomPainter {
  final List<HourPoint> pts;
  final int? sel;
  _AreaPainter(this.pts, this.sel);

  TextPainter _tp(String s, double size, Color c, {FontWeight w = FontWeight.w500}) {
    return TextPainter(
      text: TextSpan(text: s, style: ts(size, weight: w, color: c)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < p.length - 1; i++) {
      final mx = (p[i].dx + p[i + 1].dx) / 2;
      path.cubicTo(mx, p[i].dy, mx, p[i + 1].dy, p[i + 1].dx, p[i + 1].dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = pts.length;
    if (n < 2) return;
    const topPad = 32.0, bottomPad = 24.0;
    final chartH = size.height - topPad - bottomPad;
    final maxA = pts.fold<int>(0, (m, e) => e.aqi > m ? e.aqi : m);
    final maxV = math.max(100.0, maxA * 1.2);
    double xAt(int i) => size.width * i / (n - 1);
    double yAt(num v) => topPad + chartH * (1 - v / maxV);

    // Garis bantu
    for (final g in [50, 100, 150]) {
      if (g >= maxV) continue;
      final y = yAt(g);
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 1);
      _tp('$g', 10, Colors.white38).paint(canvas, Offset(2, y - 13));
    }

    final p = [for (var i = 0; i < n; i++) Offset(xAt(i), yAt(pts[i].aqi))];
    final line = _smooth(p);
    final fill = Path.from(line)
      ..lineTo(p.last.dx, topPad + chartH)
      ..lineTo(p.first.dx, topPad + chartH)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [levelFor(maxA).color.withOpacity(0.45), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [for (final e in pts) levelFor(e.aqi).color],
          stops: [for (var i = 0; i < n; i++) i / (n - 1)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Label jam
    final step = math.max(1, (n / 6).round());
    for (var i = 0; i < n; i += step) {
      final tp = _tp(fmtHour(pts[i].time), 10, Colors.white60);
      final dx = (xAt(i) - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)).toDouble();
      tp.paint(canvas, Offset(dx, size.height - 16));
    }

    // Titik terpilih
    final s = sel;
    if (s != null && s < n) {
      final pt = p[s];
      final lv = levelFor(pts[s].aqi);
      canvas.drawLine(Offset(pt.dx, topPad - 4), Offset(pt.dx, topPad + chartH),
          Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1.5);
      canvas.drawCircle(pt, 9, Paint()..color = lv.color.withOpacity(0.35));
      canvas.drawCircle(pt, 6, Paint()..color = Colors.white);
      canvas.drawCircle(pt, 3.5, Paint()..color = lv.color);

      final tp = _tp('${fmtHour(pts[s].time)} · AQI ${pts[s].aqi}', 12, Colors.white, w: FontWeight.w700);
      final bw = tp.width + 20, bh = tp.height + 10;
      final bx = (pt.dx - bw / 2).clamp(0.0, math.max(0.0, size.width - bw)).toDouble();
      final box = RRect.fromRectAndRadius(Rect.fromLTWH(bx, 0, bw, bh), const Radius.circular(10));
      canvas.drawRRect(box, Paint()..color = Colors.black.withOpacity(0.55));
      canvas.drawRRect(
        box,
        Paint()
          ..color = lv.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      tp.paint(canvas, Offset(bx + 10, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _AreaPainter old) => old.pts != pts || old.sel != sel;
}
