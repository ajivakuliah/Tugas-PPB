import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Respons mentah dari API (disimpan juga sebagai cache offline).
class RawBundle {
  final Map<String, dynamic> air;
  final Map<String, dynamic>? wx;
  const RawBundle(this.air, this.wx);

  Map<String, dynamic> toJson() => {'air': air, 'wx': wx};

  factory RawBundle.fromJson(Map<String, dynamic> j) => RawBundle(
        j['air'] as Map<String, dynamic>,
        j['wx'] as Map<String, dynamic>?,
      );
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

/// Semua data dari Open-Meteo (gratis, tanpa API key).
/// Atribusi: Open-Meteo.com, data kualitas udara dari CAMS (Copernicus), geocoding dari GeoNames.
class ApiService {
  static const _timeout = Duration(seconds: 15);

  static const _currentBasic =
      'us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index';
  static const _currentFull =
      '$_currentBasic,us_aqi_pm2_5,us_aqi_pm10,us_aqi_nitrogen_dioxide,'
      'us_aqi_ozone,us_aqi_sulphur_dioxide,us_aqi_carbon_monoxide';

  dynamic _decode(http.Response res) => jsonDecode(utf8.decode(res.bodyBytes));

  Future<List<City>> searchCity(String query) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '8',
      'language': 'id',
      'format': 'json',
    });
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('Geocoding error ${res.statusCode}');
    }
    final body = _decode(res) as Map<String, dynamic>;
    final list = (body['results'] as List?) ?? [];
    return list.map((e) => City.fromGeo(e as Map<String, dynamic>)).toList();
  }

  Future<http.Response> _airCall(City city, String current) {
    final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': city.lat.toString(),
      'longitude': city.lon.toString(),
      'current': current,
      'hourly': 'us_aqi,pm2_5',
      'past_days': '2',
      'forecast_days': '5',
      'timezone': 'auto',
    });
    return http.get(uri).timeout(_timeout);
  }

  Future<Map<String, dynamic>> _fetchAir(City city) async {
    var res = await _airCall(city, _currentFull);
    // Cadangan: bila variabel AQI per-polutan ditolak, ulangi dengan set dasar.
    if (res.statusCode != 200) res = await _airCall(city, _currentBasic);
    if (res.statusCode != 200) {
      throw ApiException('Air quality error ${res.statusCode}');
    }
    final j = _decode(res);
    if (j is! Map<String, dynamic> || j['current'] is! Map) {
      throw const ApiException('Format respons tidak dikenali');
    }
    return j;
  }

  Future<Map<String, dynamic>?> _fetchWeather(City city) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': city.lat.toString(),
        'longitude': city.lon.toString(),
        'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m',
        'timezone': 'auto',
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) return _decode(res) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// Data lengkap sebuah kota: kualitas udara (wajib) + cuaca (opsional).
  Future<RawBundle> fetchRaw(City city) async {
    final wxFuture = _fetchWeather(city); // tidak pernah melempar error
    final air = await _fetchAir(city);
    final wx = await wxFuture;
    return RawBundle(air, wx);
  }

  Future<AirData> fetch(City city) async {
    final raw = await fetchRaw(city);
    return AirData.fromJson(raw.air, raw.wx);
  }

  int? _aqiOf(dynamic e) {
    try {
      final cur = (e as Map<String, dynamic>)['current'] as Map<String, dynamic>?;
      return (cur?['us_aqi'] as num?)?.round();
    } catch (_) {
      return null;
    }
  }

  /// Versi ringan (hanya AQI saat ini) untuk satu kota.
  Future<int?> fetchQuick(City city) async {
    try {
      final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': city.lat.toString(),
        'longitude': city.lon.toString(),
        'current': 'us_aqi',
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      return _aqiOf(_decode(res));
    } catch (_) {
      return null;
    }
  }

  /// AQI banyak kota dalam SATU request (Open-Meteo menerima koordinat
  /// dipisah koma). Bila gagal, otomatis kembali ke request per kota.
  Future<List<int?>> fetchQuickBatch(List<City> cities) async {
    if (cities.isEmpty) return [];
    try {
      final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': cities.map((c) => c.lat.toString()).join(','),
        'longitude': cities.map((c) => c.lon.toString()).join(','),
        'current': 'us_aqi',
      });
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = _decode(res);
        final list = j is List ? j : [j];
        if (list.length == cities.length) {
          return [for (final e in list) _aqiOf(e)];
        }
      }
    } catch (_) {}
    return Future.wait(cities.map(fetchQuick));
  }
}
