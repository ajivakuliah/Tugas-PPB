import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';

class ExploreTab extends StatelessWidget {
  final AppState s;
  final VoidCallback onSearch;
  final ValueChanged<City> onPick;
  const ExploreTab({super.key, required this.s, required this.onSearch, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final entries = s.ranking.entries.where((e) => e.value != null).toList()
      ..sort((a, b) => a.value!.compareTo(b.value!));

    return RefreshIndicator(
      onRefresh: s.loadRanking,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jelajah Kota', style: ts(30, weight: FontWeight.w800)),
                  Text('Peringkat udara: terbersih → terkotor', style: ts(13, color: Colors.white70)),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Cari kota',
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          ]),
          const SizedBox(height: 18),
          if (entries.length >= 2) ...[
            Row(children: [
              Expanded(child: _extreme('Terbersih', entries.first.key, entries.first.value!, Icons.eco_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _extreme('Terkotor', entries.last.key, entries.last.value!,
                      Icons.warning_amber_rounded)),
            ]),
            const SizedBox(height: 14),
          ],
          if (entries.isEmpty) ..._placeholder(),
          for (var i = 0; i < entries.length; i++)
            FadeSlide(
              key: ValueKey('${entries[i].key.lat},${entries[i].key.lon}'),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _row(i, entries[i].key, entries[i].value!, entries.length),
              ),
            ),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text('${entries.length} kota · ketuk kota untuk melihat detailnya',
                    style: ts(11, color: Colors.white54)),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _placeholder() {
    if (s.rankingLoading) {
      return [
        for (var i = 0; i < 6; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Skeleton(height: 74, radius: 20),
          ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text('Tarik ke bawah untuk memuat peringkat',
              style: ts(14, color: Colors.white70)),
        ),
      ),
    ];
  }

  Widget _extreme(String title, City c, int aqi, IconData icon) {
    final lv = levelFor(aqi);
    return GestureDetector(
      onTap: () => onPick(c),
      child: Glass(
        padding: const EdgeInsets.all(14),
        radius: 20,
        tint: lv.color,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: lv.color),
            const SizedBox(width: 6),
            Text(title, style: ts(11, color: Colors.white70)),
          ]),
          const SizedBox(height: 6),
          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, weight: FontWeight.w800)),
          Text('AQI $aqi · ${lv.label}',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, weight: FontWeight.w600, color: lv.color)),
        ]),
      ),
    );
  }

  Widget _row(int i, City c, int aqi, int total) {
    final lv = levelFor(aqi);
    final isCurrent = c == s.city;
    final isFav = s.favorites.contains(c);
    return GestureDetector(
      onTap: () => onPick(c),
      child: Glass(
        padding: const EdgeInsets.all(14),
        radius: 20,
        tint: isCurrent ? Colors.white : null,
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
            ),
            child: i == 0
                ? const Icon(Icons.eco_rounded, size: 18, color: Colors.greenAccent)
                : (i == total - 1 && total > 2)
                    ? const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.redAccent)
                    : Text('${i + 1}', style: ts(13, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text('${c.flag != null ? '${c.flag} ' : ''}${c.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts(16, weight: FontWeight.w700)),
                  ),
                  if (isFav) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.favorite_rounded, size: 14, color: Colors.pinkAccent),
                  ],
                ]),
                Text('${c.country ?? ''} · ${lv.label}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, color: Colors.white60)),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: (aqi / 200).clamp(0.03, 1.0).toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      color: lv.color,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: lv.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: lv.color.withOpacity(0.6)),
            ),
            child: Text('$aqi', style: ts(18, weight: FontWeight.w800, color: lv.color)),
          ),
        ]),
      ),
    );
  }
}
