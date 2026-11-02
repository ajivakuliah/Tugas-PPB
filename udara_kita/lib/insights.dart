import 'package:flutter/material.dart';

import 'aqi_utils.dart';
import 'models.dart';

/// Jendela 3 jam berturut-turut dengan rata-rata AQI terendah.
class BestWindow {
  final DateTime start;
  final DateTime end;
  final double avg;
  const BestWindow(this.start, this.end, this.avg);
}

/// Mencari jendela 3 jam terbersih pada jam aktif (05.00-22.00).
/// [notBefore] dipakai untuk "hari ini" agar jam yang sudah lewat tidak ikut dipilih.
BestWindow? bestWindow(
  List<HourPoint> pts, {
  DateTime? notBefore,
  int fromHour = 5,
  int toHour = 21,
}) {
  BestWindow? best;
  for (var i = 0; i + 2 < pts.length; i++) {
    final a = pts[i];
    final c = pts[i + 2];
    if (notBefore != null && a.time.isBefore(notBefore)) continue;
    if (a.time.hour < fromHour || c.time.hour > toHour) continue;
    if (c.time.difference(a.time).inHours != 2) continue;
    final avg = (a.aqi + pts[i + 1].aqi + c.aqi) / 3;
    if (best == null || avg < best.avg) {
      best = BestWindow(a.time, c.time.add(const Duration(hours: 1)), avg);
    }
  }
  return best;
}

class Insight {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const Insight(this.icon, this.title, this.body, this.color);
}

/// Ringkasan tren AQI beberapa jam ke depan dalam bahasa sehari-hari.
Insight buildInsight(AirData d) {
  final next = d.next24;
  if (next.length < 7) {
    return const Insight(
      Icons.info_outline_rounded,
      'Prakiraan belum lengkap',
      'Data jam-jam ke depan belum tersedia untuk lokasi ini.',
      Colors.white70,
    );
  }
  final now = d.aqi;
  final upcoming = next.skip(1).take(6).toList();
  final avg = upcoming.fold<int>(0, (s, e) => s + e.aqi) / upcoming.length;
  final delta = avg - now;

  var peak = next.first;
  var low = next.first;
  for (final p in next) {
    if (p.aqi > peak.aqi) peak = p;
    if (p.aqi < low.aqi) low = p;
  }

  final peakText = (peak.aqi >= now + 15 && levelIndex(peak.aqi) > levelIndex(now))
      ? ' Puncak diperkirakan sekitar ${fmtHour(peak.time)} (AQI ${peak.aqi}, ${levelFor(peak.aqi).label}).'
      : '';

  if (delta >= 10) {
    return Insight(
      Icons.trending_up_rounded,
      'Udara cenderung memburuk',
      'Dalam 6 jam ke depan rata-rata AQI sekitar ${avg.round()}, naik dari $now saat ini.$peakText',
      levelFor(avg.round()).color,
    );
  }
  if (delta <= -10) {
    return Insight(
      Icons.trending_down_rounded,
      'Udara cenderung membaik',
      'Dalam 6 jam ke depan rata-rata AQI sekitar ${avg.round()}, turun dari $now saat ini. Jam terbersih: ${fmtHour(low.time)} (AQI ${low.aqi}).',
      levelFor(avg.round()).color,
    );
  }
  return Insight(
    Icons.trending_flat_rounded,
    'Udara relatif stabil',
    'AQI diperkirakan berkisar ${low.aqi}–${peak.aqi} dalam 24 jam ke depan.$peakText',
    levelFor(now).color,
  );
}
