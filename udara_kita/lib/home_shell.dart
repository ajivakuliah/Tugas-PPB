import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'about_page.dart';
import 'aqi_utils.dart';
import 'models.dart';
import 'pages/explore_tab.dart';
import 'pages/forecast_tab.dart';
import 'pages/health_tab.dart';
import 'pages/home_tab.dart';
import 'search_page.dart';
import 'state.dart';
import 'ui.dart';
import 'widgets/sky_background.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final AppState s = AppState();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    s.init();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  Future<void> _openSearch() async {
    final picked = await Navigator.push<City>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(recents: s.recents, favorites: s.favorites),
      ),
    );
    if (picked != null) {
      s.selectCity(picked);
      setState(() => _tab = 0);
    }
  }

  void _openAbout() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
  }

  void _onTab(int i) {
    if (i != _tab) HapticFeedback.selectionClick();
    setState(() => _tab = i);
    if (i == 2 && s.ranking.isEmpty) s.loadRanking();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final d = s.data;
        final aqi = d?.aqi ?? 40;
        final List<Color> grad = d != null
            ? levelFor(d.aqi).gradient
            : const [Color(0xFF1B2A49), Color(0xFF111B33), Color(0xFF0A1020)];

        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: SkyBackground(aqi: aqi, hour: d?.time.hour ?? 12, gradient: grad),
              ),
              SafeArea(
                child: Column(
                  children: [
                    if (s.offline && d != null)
                      InfoBanner(
                        icon: Icons.cloud_off_rounded,
                        color: Colors.amberAccent,
                        text:
                            'Offline: menampilkan data tersimpan (${dateLabel(d.time)}, ${fmtTime(d.time)}). Tarik ke bawah untuk memuat ulang.',
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _tab,
                        children: [
                          HomeTab(s: s, onSearch: _openSearch, onAbout: _openAbout),
                          ForecastTab(s: s),
                          ExploreTab(
                            s: s,
                            onSearch: _openSearch,
                            onPick: (c) {
                              s.selectCity(c);
                              setState(() => _tab = 0);
                            },
                          ),
                          HealthTab(s: s),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _NavBar(index: _tab, onTap: _onTab),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NavBar({required this.index, required this.onTap});

  static const _items = <(IconData, String)>[
    (Icons.home_rounded, 'Beranda'),
    (Icons.show_chart_rounded, 'Prakiraan'),
    (Icons.public_rounded, 'Jelajah'),
    (Icons.favorite_rounded, 'Sehat'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: _items[i].$2,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: i == index ? Colors.white.withOpacity(0.22) : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_items[i].$1,
                                    size: 24, color: i == index ? Colors.white : Colors.white60),
                                if (i == index)
                                  Text(_items[i].$2, style: ts(10, weight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
