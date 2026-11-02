import 'package:flutter/material.dart';

import '../aqi_utils.dart';
import '../ui.dart';

/// Kartu polutan dengan cincin progres terhadap pedoman WHO 2021.
/// Polutan dominan (penentu skor AQI) diberi sorotan.
class PollutantTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final double value;
  final double limit;
  final int? subAqi;
  final bool dominant;

  const PollutantTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.value,
    required this.limit,
    this.subAqi,
    this.dominant = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limit == 0 ? 0.0 : value / limit;
    final color = ratio <= 1
        ? Colors.greenAccent
        : (ratio <= 2 ? Colors.amberAccent : Colors.redAccent);
    final valText = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: dominant ? Border.all(color: color.withOpacity(0.8), width: 1.6) : null,
      ),
      child: Glass(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (ratio / 3).clamp(0.0, 1.0).toDouble()),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 5,
                        backgroundColor: Colors.white12,
                        color: color,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Text('${ratio.toStringAsFixed(1)}×', style: ts(11, weight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ts(16, weight: FontWeight.w800)),
                    ),
                    if (dominant) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.local_fire_department_rounded, size: 15, color: color),
                    ],
                  ]),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(11, color: Colors.white60)),
                  Text('$valText µg/m³',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(12, weight: FontWeight.w600, color: color)),
                  if (subAqi != null)
                    Text('AQI $subAqi',
                        style: ts(11, weight: FontWeight.w600, color: levelFor(subAqi!).color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
