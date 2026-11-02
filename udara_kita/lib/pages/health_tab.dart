import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../insights.dart';
import '../state.dart';
import '../ui.dart';

class HealthTab extends StatelessWidget {
  final AppState s;
  const HealthTab({super.key, required this.s});

  static const _indoorTips = <String>[
    'Tutup jendela dan pintu saat AQI di luar tinggi.',
    'Gunakan air purifier dengan filter HEPA bila tersedia.',
    'Jangan membakar sampah atau merokok di dalam ruangan.',
    'Bersihkan debu dengan lap lembap, bukan sapu kering.',
    'Nyalakan exhaust saat memasak untuk mengurangi partikel.',
  ];

  @override
  Widget build(BuildContext context) {
    final d = s.data;
    if (d == null) {
      if (s.error != null) return ErrorView(message: s.error!, onRetry: s.load);
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final eff = s.effAqi;
    final lv = levelFor(eff);
    final prof = healthProfiles[s.profile];

    final today = DateTime(d.time.year, d.time.month, d.time.day);
    final win = bestWindow(d.forDay(today), notBefore: d.hour0);

    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Kesehatan', style: ts(30, weight: FontWeight.w800)),
          Text('Saran personal sesuai kelompokmu', style: ts(13, color: Colors.white70)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < healthProfiles.length; i++)
                ChoiceChip(
                  avatar: Icon(healthProfiles[i].icon, size: 18, color: Colors.white),
                  label: Text(healthProfiles[i].name, style: ts(13, weight: FontWeight.w600)),
                  selected: i == s.profile,
                  showCheckmark: false,
                  selectedColor: Colors.white.withOpacity(0.32),
                  backgroundColor: Colors.white.withOpacity(0.12),
                  side: BorderSide.none,
                  onSelected: (_) => s.setProfile(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(prof.icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Profil: ${prof.name}', style: ts(15, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$eff', style: ts(52, weight: FontWeight.w800, color: lv.color, height: 1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('AQI efektif\n${lv.label}', style: ts(13, color: Colors.white70)),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  prof.shift > 0
                      ? 'AQI sebenarnya ${d.aqi}. Karena kelompok ini lebih rentan, saran di bawah dihitung seolah-olah AQI-nya $eff (tambahan +${prof.shift} adalah penyesuaian kehati-hatian dari aplikasi, bukan standar medis).'
                      : 'Saran di bawah memakai AQI sebenarnya: ${d.aqi}.',
                  style: ts(12, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(prof.note, style: ts(13, height: 1.4)),
              ],
            ),
          ),
          if (win != null) ...[
            const SectionTitle('Waktu terbaik hari ini'),
            Glass(
              child: Row(children: [
                const Icon(Icons.directions_run_rounded, size: 36, color: Colors.greenAccent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Aktivitas luar ruangan', style: ts(12, color: Colors.white70)),
                    Text('${fmtHour(win.start)} – ${fmtHour(win.end)}',
                        style: ts(22, weight: FontWeight.w800)),
                    Text(
                      'Rata-rata AQI ${win.avg.round()}'
                      '${s.profile != 0 ? ' (efektif ${win.avg.round() + prof.shift} untuk profilmu)' : ''}',
                      style: ts(12, color: Colors.white70),
                    ),
                  ]),
                ),
              ]),
            ),
          ],
          const SectionTitle('Panduan masker'),
          Glass(
            child: Row(children: [
              Icon(Icons.masks_rounded, size: 40, color: lv.color),
              const SizedBox(width: 14),
              Expanded(child: Text(lv.mask, style: ts(14, height: 1.4))),
            ]),
          ),
          const SectionTitle('Meter aktivitas', subtitle: 'Berdasarkan AQI efektif profilmu'),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final a in activities)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Icon(a.icon, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(a.name, style: ts(14))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: a.statusColor(eff).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(a.status(eff),
                            style: ts(12, weight: FontWeight.w700, color: a.statusColor(eff))),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          const SectionTitle('Tips udara dalam ruangan'),
          Glass(
            child: Column(
              children: [
                for (final t in _indoorTips)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle_rounded, size: 18, color: Colors.greenAccent),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, style: ts(13, height: 1.35))),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Saran bersifat umum dan bukan pengganti nasihat dokter.',
            textAlign: TextAlign.center,
            style: ts(11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
