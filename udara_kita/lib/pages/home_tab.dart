import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../aqi_utils.dart';
import '../insights.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import '../widgets/aqi_gauge.dart';
import '../widgets/area_chart.dart';
import '../widgets/mascot.dart';
import '../widgets/pollutant_tile.dart';

class HomeTab extends StatelessWidget {
  final AppState s;
  final VoidCallback onSearch;
  final VoidCallback onAbout;
  const HomeTab({super.key, required this.s, required this.onSearch, required this.onAbout});

  @override
  Widget build(BuildContext context) {
    final d = s.data;
    if (d == null) {
      if (s.error != null) return ErrorView(message: s.error!, onRetry: s.load);
      return const _HomeSkeleton();
    }
    final level = levelFor(d.aqi);
    final eff = s.effAqi;
    final effLevel = levelFor(eff);

    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          FadeSlide(key: const ValueKey('hdr'), index: 0, child: _header(context, d, level)),
          if (s.favorites.isNotEmpty)
            FadeSlide(
              key: const ValueKey('fav'),
              index: 1,
              child: Padding(padding: const EdgeInsets.only(top: 12), child: _favChips()),
            ),
          FadeSlide(
            key: const ValueKey('gauge'),
            index: 2,
            child: Column(children: [
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AqiGauge(aqi: d.aqi),
                    Positioned(right: 0, bottom: 0, child: Mascot(aqi: d.aqi, size: 96)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                level.advice,
                textAlign: TextAlign.center,
                style: ts(14, color: Colors.white.withOpacity(0.88), height: 1.4),
              ),
              if (s.profile != 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Saran di bawah disesuaikan untuk: ${healthProfiles[s.profile].name}',
                    textAlign: TextAlign.center,
                    style: ts(11, color: Colors.white60),
                  ),
                ),
            ]),
          ),
          FadeSlide(
            key: const ValueKey('quick'),
            index: 3,
            child: Padding(padding: const EdgeInsets.only(top: 16), child: _quickCards(eff, effLevel)),
          ),
          FadeSlide(
            key: const ValueKey('weather'),
            index: 4,
            child: Padding(padding: const EdgeInsets.only(top: 14), child: _weatherChips(d)),
          ),
          FadeSlide(
            key: const ValueKey('insight'),
            index: 5,
            child: Padding(padding: const EdgeInsets.only(top: 18), child: _insightCard(buildInsight(d))),
          ),
          FadeSlide(
            key: const ValueKey('chart'),
            index: 6,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('24 jam ke depan',
                  subtitle: 'Sentuh atau geser grafik untuk melihat jam tertentu'),
              Glass(child: AreaChart(points: d.next24)),
            ]),
          ),
          FadeSlide(
            key: const ValueKey('poll'),
            index: 7,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Polutan utama',
                  subtitle: 'Konsentrasi saat ini vs pedoman WHO 2021 (angka × = kelipatan batas)'),
              _dominantCard(d),
              const SizedBox(height: 12),
              _pollutants(d),
            ]),
          ),
          FadeSlide(
            key: const ValueKey('cig'),
            index: 8,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Setara berapa batang rokok?'),
              _cigaretteCard(d),
            ]),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Diperbarui ${fmtTime(d.time)} · Data: Open-Meteo (CAMS Copernicus)',
              textAlign: TextAlign.center,
              style: ts(11, color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, AirData d, AqiLevel level) {
    final text =
        'Kualitas udara ${s.city.name}: AQI ${d.aqi} (${level.label}). PM2.5 ${d.pm25.toStringAsFixed(1)} µg/m³. ${level.mask} #UdaraKita';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Ringkasan disalin ke clipboard')));
  }

  Widget _header(BuildContext context, AirData d, AqiLevel level) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSearch,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(s.city.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(30, weight: FontWeight.w800)),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                ]),
                if (s.city.subtitle.isNotEmpty)
                  Text(s.city.subtitle, style: ts(13, color: Colors.white70)),
                Text(dateLabel(d.time), style: ts(12, color: Colors.white54)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: s.isFav ? 'Hapus dari favorit' : 'Tambah ke favorit',
          onPressed: s.toggleFav,
          icon: Icon(s.isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: s.isFav ? Colors.pinkAccent : Colors.white),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (v) {
            if (v == 'copy') _copy(context, d, level);
            if (v == 'about') onAbout();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'copy',
              child: Row(children: [
                const Icon(Icons.copy_rounded, size: 20),
                const SizedBox(width: 12),
                Text('Salin ringkasan', style: ts(14)),
              ]),
            ),
            PopupMenuItem(
              value: 'about',
              child: Row(children: [
                const Icon(Icons.menu_book_rounded, size: 20),
                const SizedBox(width: 12),
                Text('Tentang & edukasi', style: ts(14)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _favChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: s.favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = s.favorites[i];
          return ChoiceChip(
            label: Text(c.name, style: ts(13, weight: FontWeight.w600)),
            selected: c == s.city,
            showCheckmark: false,
            selectedColor: Colors.white.withOpacity(0.32),
            backgroundColor: Colors.white.withOpacity(0.12),
            side: BorderSide.none,
            onSelected: (_) => s.selectCity(c),
          );
        },
      ),
    );
  }

  Widget _quickCards(int eff, AqiLevel effLevel) {
    final win = eff <= 100
        ? ('Buka', Colors.greenAccent)
        : eff <= 150
            ? ('Sebentar', Colors.amberAccent)
            : ('Tutup', Colors.redAccent);
    final run = activities[0];
    return Row(
      children: [
        Expanded(child: _quick(Icons.masks_rounded, 'Masker', effLevel.maskShort, effLevel.color)),
        const SizedBox(width: 10),
        Expanded(child: _quick(Icons.window_rounded, 'Jendela', win.$1, win.$2)),
        const SizedBox(width: 10),
        Expanded(child: _quick(Icons.directions_run_rounded, 'Olahraga luar', run.status(eff), run.statusColor(eff))),
      ],
    );
  }

  Widget _quick(IconData icon, String title, String value, Color color) {
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      radius: 20,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: ts(11, color: Colors.white70))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: ts(14, weight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _weatherChips(AirData d) {
    final chips = <Widget>[];
    if (d.temp != null) chips.add(_chip(Icons.thermostat_rounded, '${d.temp!.round()}°C'));
    if (d.humidity != null) chips.add(_chip(Icons.water_drop_rounded, '${d.humidity!.round()}%'));
    if (d.wind != null) chips.add(_chip(Icons.air_rounded, '${d.wind!.round()} km/j'));
    if (d.uv != null) chips.add(_chip(Icons.wb_sunny_rounded, 'UV ${d.uv!.toStringAsFixed(1)}'));
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: chips);
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: ts(13, weight: FontWeight.w600)),
      ]),
    );
  }

  Widget _insightCard(Insight i) {
    return Glass(
      tint: i.color,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i.icon, size: 34, color: i.color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.title, style: ts(16, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(i.body, style: ts(13, color: Colors.white70, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  Widget _dominantCard(AirData d) {
    final k = d.dominantKey;
    if (k == null) return const SizedBox.shrink();
    final info = pollutantInfos.firstWhere((p) => p.key == k);
    final sub = d.subAqi[k] ?? 0;
    final color = levelFor(sub).color;
    return Glass(
      child: Row(children: [
        Icon(Icons.local_fire_department_rounded, size: 36, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Polutan dominan', style: ts(12, color: Colors.white70)),
            Text('${info.name} · AQI $sub', style: ts(20, weight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text('Skor AQI kota ini ditentukan oleh ${info.short.toLowerCase()}. Sumber umum: ${info.sources}',
                style: ts(12, color: Colors.white70, height: 1.35)),
          ]),
        ),
      ]),
    );
  }

  Widget _pollutants(AirData d) {
    final dom = d.dominantKey;
    return LayoutBuilder(builder: (context, cons) {
      final w = (cons.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final p in pollutantInfos)
            SizedBox(
              width: w,
              child: PollutantTile(
                name: p.name,
                subtitle: p.short,
                value: d.valueOf(p.key),
                limit: p.who,
                subAqi: d.subAqi[p.key],
                dominant: p.key == dom,
              ),
            ),
        ],
      );
    });
  }

  Widget _cigaretteCard(AirData d) {
    final cig = d.pm25 / 22;
    return Glass(
      child: Row(children: [
        const Icon(Icons.smoking_rooms_rounded, size: 44, color: Colors.orangeAccent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('≈ ${cig.toStringAsFixed(1)} batang / hari',
                  style: ts(22, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Jika kamu menghirup PM2.5 sebesar ini selama 24 jam. Perkiraan kasar (22 µg/m³ ≈ 1 batang rokok, Berkeley Earth).',
                style: ts(12, color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Kerangka berkilau saat data pertama kali dimuat.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: const [
        Align(alignment: Alignment.centerLeft, child: Skeleton(width: 190, height: 34, radius: 12)),
        SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft, child: Skeleton(width: 120, height: 14, radius: 8)),
        SizedBox(height: 26),
        Center(child: Skeleton(width: 250, height: 250, radius: 125)),
        SizedBox(height: 22),
        Row(children: [
          Expanded(child: Skeleton(height: 92, radius: 20)),
          SizedBox(width: 10),
          Expanded(child: Skeleton(height: 92, radius: 20)),
          SizedBox(width: 10),
          Expanded(child: Skeleton(height: 92, radius: 20)),
        ]),
        SizedBox(height: 18),
        Skeleton(height: 120, radius: 24),
        SizedBox(height: 14),
        Skeleton(height: 200, radius: 24),
      ],
    );
  }
}
