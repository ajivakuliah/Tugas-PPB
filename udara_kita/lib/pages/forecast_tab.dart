import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../insights.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import '../widgets/area_chart.dart';

class ForecastTab extends StatefulWidget {
  final AppState s;
  const ForecastTab({super.key, required this.s});

  @override
  State<ForecastTab> createState() => _ForecastTabState();
}

class _ForecastTabState extends State<ForecastTab> {
  DateTime? _day;

  static int _maxOf(List<HourPoint> l) => l.fold<int>(0, (m, e) => e.aqi > m ? e.aqi : m);

  static String _label(DateTime day, DateTime today) {
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == -1) return 'Kemarin';
    if (diff == 1) return 'Besok';
    return '${dayShort(day)} ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = s.data;
    if (d == null) {
      if (s.error != null) return ErrorView(message: s.error!, onRetry: s.load);
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final today = DateTime(d.time.year, d.time.month, d.time.day);
    final days = d.days;
    final sel = (_day != null && days.contains(_day)) ? _day! : today;
    final isToday = sel == today;
    final isPast = sel.isBefore(today);
    final pts = d.forDay(sel);
    final aqis = pts.map((e) => e.aqi).toList();

    int minV = 0, maxV = 0, avgV = 0;
    if (aqis.isNotEmpty) {
      minV = aqis.reduce((a, b) => a < b ? a : b);
      maxV = aqis.reduce((a, b) => a > b ? a : b);
      avgV = (aqis.reduce((a, b) => a + b) / aqis.length).round();
    }

    // Jendela emas: hanya jam aktif, dan untuk hari ini hanya jam yang belum lewat.
    final win = bestWindow(pts, notBefore: isToday ? d.hour0 : null);

    final dayMaxes = [for (final day in days) _maxOf(d.forDay(day))];
    final topMax = dayMaxes.fold<int>(100, (m, e) => e > m ? e : m);

    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Prakiraan', style: ts(30, weight: FontWeight.w800)),
          Text(s.city.name, style: ts(14, color: Colors.white70)),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_label(days[i], today), style: ts(13, weight: FontWeight.w600)),
                selected: days[i] == sel,
                showCheckmark: false,
                selectedColor: Colors.white.withOpacity(0.32),
                backgroundColor: Colors.white.withOpacity(0.12),
                side: BorderSide.none,
                onSelected: (_) => setState(() => _day = days[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AQI per jam · ${dateLabel(sel)}', style: ts(14, weight: FontWeight.w700)),
                Text('Sentuh atau geser untuk melihat detail', style: ts(11, color: Colors.white60)),
                const SizedBox(height: 10),
                AreaChart(points: pts, height: 220),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _stat('Terendah', minV)),
            const SizedBox(width: 10),
            Expanded(child: _stat('Rata-rata', avgV)),
            const SizedBox(width: 10),
            Expanded(child: _stat('Tertinggi', maxV)),
          ]),
          const SizedBox(height: 12),
          if (win != null)
            Glass(
              child: Row(children: [
                const Icon(Icons.schedule_rounded, color: Colors.greenAccent, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isPast ? 'Jam terbersih hari itu' : 'Jendela emas untuk keluar rumah',
                          style: ts(12, color: Colors.white70)),
                      Text('${fmtHour(win.start)} – ${fmtHour(win.end)}',
                          style: ts(22, weight: FontWeight.w800)),
                      Text('Rata-rata AQI ${win.avg.round()} · dipilih dari jam aktif 05.00–22.00',
                          style: ts(12, color: Colors.white70)),
                    ],
                  ),
                ),
              ]),
            )
          else if (isToday)
            Glass(
              child: Row(children: [
                const Icon(Icons.nightlight_round, color: Colors.indigoAccent, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Jam aktif hari ini sudah lewat. Pilih "Besok" untuk melihat jendela emas berikutnya.',
                    style: ts(13, color: Colors.white70, height: 1.4),
                  ),
                ),
              ]),
            ),
          const SectionTitle('Peta warna 24 jam', subtitle: 'Setiap kotak = 1 jam, warna mengikuti kategori AQI'),
          Glass(child: _heatStrip(pts, isToday ? d.hour0 : null)),
          const SectionTitle('Tren harian', subtitle: 'AQI tertinggi tiap hari · ketuk untuk memilih hari'),
          Glass(
            child: SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _day = days[i]),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${dayMaxes[i]}', style: ts(11, weight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: (96 * dayMaxes[i] / topMax).clamp(8.0, 96.0).toDouble(),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: levelFor(dayMaxes[i]).color.withOpacity(days[i] == sel ? 1 : 0.55),
                                borderRadius: BorderRadius.circular(8),
                                border: days[i] == sel ? Border.all(color: Colors.white, width: 2) : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dayShort(days[i]),
                              style: ts(11,
                                  weight: days[i] == sel ? FontWeight.w800 : FontWeight.w500,
                                  color: days[i] == sel ? Colors.white : Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatStrip(List<HourPoint> pts, DateTime? from) {
    if (pts.isEmpty) {
      return Text('Data belum tersedia', style: ts(12, color: Colors.white60));
    }
    return Column(children: [
      Row(children: [
        for (final p in pts)
          Expanded(
            child: Tooltip(
              message: '${fmtHour(p.time)} · AQI ${p.aqi}',
              child: Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: levelFor(p.aqi).color.withOpacity((from != null && p.time.isBefore(from)) ? 0.35 : 0.95),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 6),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final h in const ['00', '06', '12', '18', '23'])
            Text(h, style: ts(10, color: Colors.white60)),
        ],
      ),
    ]);
  }

  Widget _stat(String label, int v) {
    final lv = levelFor(v);
    return Glass(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      radius: 20,
      child: Column(children: [
        Text(label, style: ts(11, color: Colors.white70)),
        const SizedBox(height: 4),
        Text('$v', style: ts(26, weight: FontWeight.w800, color: lv.color)),
      ]),
    );
  }
}
