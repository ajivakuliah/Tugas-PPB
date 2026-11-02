import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'ui.dart';

class SearchPage extends StatefulWidget {
  final List<City> recents;
  final List<City> favorites;
  const SearchPage({super.key, this.recents = const [], this.favorites = const []});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<City> _results = [];
  bool _loading = false;
  String? _msg;
  int _seq = 0;

  bool get _searching => _ctrl.text.trim().length >= 2;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final t = q.trim();
    _seq++;
    if (t.length < 2) {
      setState(() {
        _results = [];
        _msg = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _msg = null;
    });
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(t));
  }

  Future<void> _search(String q) async {
    final my = ++_seq;
    try {
      final r = await _api.searchCity(q);
      if (!mounted || my != _seq) return;
      setState(() {
        _results = r;
        _loading = false;
        _msg = r.isEmpty ? 'Kota tidak ditemukan' : null;
      });
    } catch (_) {
      if (!mounted || my != _seq) return;
      setState(() {
        _results = [];
        _loading = false;
        _msg = 'Gagal mencari. Cek koneksi internet kamu.';
      });
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(title, style: ts(13, weight: FontWeight.w700, color: Colors.white70, spacing: 0.4)),
      );

  Widget _tile(City c, {IconData icon = Icons.location_city_rounded}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.pop(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                child: c.flag != null
                    ? Text(c.flag!, style: const TextStyle(fontSize: 20))
                    : Icon(icon, size: 20, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, weight: FontWeight.w700)),
                  if (c.subtitle.isNotEmpty)
                    Text(c.subtitle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, color: Colors.white60)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (_searching) {
      if (_msg != null) {
        children.add(Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(_msg!, textAlign: TextAlign.center, style: ts(14, color: Colors.white70))),
        ));
      }
      for (final c in _results) {
        children.add(_tile(c));
      }
    } else {
      if (widget.favorites.isNotEmpty) {
        children.add(_section('FAVORIT'));
        for (final c in widget.favorites) {
          children.add(_tile(c, icon: Icons.favorite_rounded));
        }
      }
      if (widget.recents.isNotEmpty) {
        children.add(_section('TERAKHIR DILIHAT'));
        for (final c in widget.recents) {
          children.add(_tile(c, icon: Icons.history_rounded));
        }
      }
      children.add(_section('KOTA POPULER'));
      for (final c in City.presets) {
        children.add(_tile(c));
      }
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: pageGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: ts(15),
                      decoration: InputDecoration(
                        hintText: 'Cari kota di seluruh dunia…',
                        hintStyle: ts(15, color: Colors.white54),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search_rounded, color: Colors.white70),
                        suffixIcon: _ctrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus',
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _ctrl.clear();
                                  _onChanged('');
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: children,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
