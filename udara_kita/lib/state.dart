import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'aqi_utils.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final _api = ApiService();

  City city = City.defaultCity;
  List<City> favorites = [];
  List<City> recents = [];
  AirData? data;
  bool loading = true;
  String? error;

  /// true bila yang tampil adalah data tersimpan (gagal terhubung ke internet).
  bool offline = false;
  int profile = 0;

  Map<City, int?> ranking = {};
  bool rankingLoading = false;

  int _req = 0; // penanda request terbaru, mencegah respons lama menimpa yang baru

  bool get isFav => favorites.contains(city);
  int get effAqi => (data?.aqi ?? 0) + healthProfiles[profile].shift;

  static String _cacheKey(City c) => '${c.lat.toStringAsFixed(3)},${c.lon.toStringAsFixed(3)}';

  List<City> _readCities(SharedPreferences prefs, String key) {
    final out = <City>[];
    for (final e in prefs.getStringList(key) ?? const <String>[]) {
      try {
        out.add(City.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favorites = _readCities(prefs, 'favorites');
      recents = _readCities(prefs, 'recents');
      final last = prefs.getString('last_city');
      if (last != null) {
        city = City.fromJson(jsonDecode(last) as Map<String, dynamic>);
      }
      final p = prefs.getInt('profile') ?? 0;
      if (p >= 0 && p < healthProfiles.length) profile = p;
    } catch (_) {}
    await load();
  }

  Future<void> _saveCache(City c, RawBundle raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_key', _cacheKey(c));
      await prefs.setString('cache_data', jsonEncode(raw.toJson()));
    } catch (_) {}
  }

  Future<AirData?> _readCache(City c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('cache_key') != _cacheKey(c)) return null;
      final s = prefs.getString('cache_data');
      if (s == null) return null;
      final raw = RawBundle.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return AirData.fromJson(raw.air, raw.wx);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final my = ++_req;
    final target = city;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _api.fetchRaw(target);
      if (my != _req) return;
      data = AirData.fromJson(raw.air, raw.wx);
      offline = false;
      _saveCache(target, raw);
    } catch (_) {
      if (my != _req) return;
      if (data == null) {
        final cached = await _readCache(target);
        if (my != _req) return;
        if (cached != null) {
          data = cached;
          offline = true;
        } else {
          error = 'Gagal memuat data. Cek koneksi internet kamu.';
        }
      } else {
        offline = true; // refresh gagal, tetap tampilkan data lama
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> selectCity(City c) async {
    city = c;
    data = null;
    offline = false;
    error = null;
    recents = [c, ...recents.where((e) => e != c)].take(6).toList();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_city', jsonEncode(c.toJson()));
      await prefs.setStringList(
          'recents', recents.map((e) => jsonEncode(e.toJson())).toList());
    } catch (_) {}
    await load();
  }

  Future<void> toggleFav() async {
    if (isFav) {
      favorites.remove(city);
    } else {
      favorites.add(city);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'favorites', favorites.map((c) => jsonEncode(c.toJson())).toList());
    } catch (_) {}
  }

  Future<void> setProfile(int i) async {
    profile = i;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('profile', i);
    } catch (_) {}
  }

  Future<void> loadRanking() async {
    if (rankingLoading) return;
    rankingLoading = true;
    notifyListeners();
    final list = <City>{...City.presets, ...favorites, city}.toList();
    final res = await _api.fetchQuickBatch(list);
    ranking = {for (var i = 0; i < list.length; i++) list[i]: res[i]};
    rankingLoading = false;
    notifyListeners();
  }
}
