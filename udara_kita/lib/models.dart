class City {
  final String name;
  final String? admin;
  final String? country;

  /// Kode negara ISO-3166 alpha-2 (mis. "ID"), dipakai untuk emoji bendera.
  final String? cc;
  final double lat;
  final double lon;

  const City({
    required this.name,
    this.admin,
    this.country,
    this.cc,
    required this.lat,
    required this.lon,
  });

  static const defaultCity = City(
    name: 'Samarinda',
    admin: 'Kalimantan Timur',
    country: 'Indonesia',
    cc: 'ID',
    lat: -0.5022,
    lon: 117.1537,
  );

  static const presets = <City>[
    defaultCity,
    City(name: 'Balikpapan', admin: 'Kalimantan Timur', country: 'Indonesia', cc: 'ID', lat: -1.2675, lon: 116.8289),
    City(name: 'Jakarta', admin: 'DKI Jakarta', country: 'Indonesia', cc: 'ID', lat: -6.2146, lon: 106.8451),
    City(name: 'Palangka Raya', admin: 'Kalimantan Tengah', country: 'Indonesia', cc: 'ID', lat: -2.2136, lon: 113.9108),
    City(name: 'Pekanbaru', admin: 'Riau', country: 'Indonesia', cc: 'ID', lat: 0.5071, lon: 101.4478),
    City(name: 'Bandung', admin: 'Jawa Barat', country: 'Indonesia', cc: 'ID', lat: -6.9147, lon: 107.6098),
    City(name: 'Surabaya', admin: 'Jawa Timur', country: 'Indonesia', cc: 'ID', lat: -7.2492, lon: 112.7508),
    City(name: 'Makassar', admin: 'Sulawesi Selatan', country: 'Indonesia', cc: 'ID', lat: -5.1477, lon: 119.4327),
    City(name: 'Singapura', admin: 'Singapura', country: 'Singapura', cc: 'SG', lat: 1.2897, lon: 103.8501),
    City(name: 'Delhi', admin: 'Delhi', country: 'India', cc: 'IN', lat: 28.6519, lon: 77.2315),
    City(name: 'Beijing', admin: 'Beijing', country: 'China', cc: 'CN', lat: 39.9075, lon: 116.3972),
    City(name: 'Tokyo', admin: 'Tokyo', country: 'Jepang', cc: 'JP', lat: 35.6895, lon: 139.6917),
    City(name: 'Zurich', admin: 'Zurich', country: 'Swiss', cc: 'CH', lat: 47.3769, lon: 8.5417),
  ];

  String get subtitle =>
      [admin, country].where((e) => e != null && e.isNotEmpty).join(', ');

  /// Emoji bendera dari kode negara, atau null bila tidak tersedia.
  String? get flag {
    final c = cc;
    if (c == null || c.length != 2) return null;
    final u = c.toUpperCase().codeUnits;
    for (final x in u) {
      if (x < 65 || x > 90) return null;
    }
    return String.fromCharCodes([0x1F1E6 + u[0] - 65, 0x1F1E6 + u[1] - 65]);
  }

  factory City.fromGeo(Map<String, dynamic> j) => City(
        name: (j['name'] ?? '-').toString(),
        admin: j['admin1']?.toString(),
        country: j['country']?.toString(),
        cc: j['country_code']?.toString(),
        lat: (j['latitude'] as num).toDouble(),
        lon: (j['longitude'] as num).toDouble(),
      );

  factory City.fromJson(Map<String, dynamic> j) => City(
        name: j['name'] as String,
        admin: j['admin'] as String?,
        country: j['country'] as String?,
        cc: j['cc'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin': admin,
        'country': country,
        'cc': cc,
        'lat': lat,
        'lon': lon,
      };

  @override
  bool operator ==(Object other) =>
      other is City && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);
}

class HourPoint {
  final DateTime time;
  final int aqi;
  final double pm25;
  const HourPoint(this.time, this.aqi, this.pm25);
}

class AirData {
  final DateTime time;
  final int aqi;
  final double pm25, pm10, co, no2, so2, o3;
  final double? uv;
  final List<HourPoint> all;
  final double? temp, humidity, wind;

  /// AQI per polutan (kunci: pm25, pm10, no2, o3, so2, co). Polutan dengan
  /// nilai tertinggi adalah polutan dominan yang menentukan skor AQI.
  final Map<String, int> subAqi;

  const AirData({
    required this.time,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.co,
    required this.no2,
    required this.so2,
    required this.o3,
    required this.all,
    this.uv,
    this.temp,
    this.humidity,
    this.wind,
    this.subAqi = const {},
  });

  static const _subFields = <String, String>{
    'pm25': 'us_aqi_pm2_5',
    'pm10': 'us_aqi_pm10',
    'no2': 'us_aqi_nitrogen_dioxide',
    'o3': 'us_aqi_ozone',
    'so2': 'us_aqi_sulphur_dioxide',
    'co': 'us_aqi_carbon_monoxide',
  };

  DateTime get hour0 => DateTime(time.year, time.month, time.day, time.hour);

  List<HourPoint> get next24 =>
      all.where((p) => !p.time.isBefore(hour0)).take(24).toList();

  List<DateTime> get days {
    final s = <DateTime>{};
    for (final p in all) {
      s.add(DateTime(p.time.year, p.time.month, p.time.day));
    }
    return s.toList()..sort();
  }

  List<HourPoint> forDay(DateTime d) => all
      .where((p) => p.time.year == d.year && p.time.month == d.month && p.time.day == d.day)
      .toList();

  String? get dominantKey {
    String? key;
    var best = -1;
    subAqi.forEach((k, v) {
      if (v > best) {
        best = v;
        key = k;
      }
    });
    return key;
  }

  double valueOf(String key) {
    switch (key) {
      case 'pm25':
        return pm25;
      case 'pm10':
        return pm10;
      case 'no2':
        return no2;
      case 'o3':
        return o3;
      case 'so2':
        return so2;
      case 'co':
        return co;
      default:
        return 0;
    }
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  factory AirData.fromJson(Map<String, dynamic> air, Map<String, dynamic>? wx) {
    final cur = air['current'] as Map<String, dynamic>;
    final now = DateTime.parse(cur['time'] as String);

    final all = <HourPoint>[];
    final h = air['hourly'] as Map<String, dynamic>?;
    if (h != null) {
      final times = (h['time'] as List).cast<String>();
      final aqis = h['us_aqi'] as List;
      final pms = h['pm2_5'] as List;
      for (var i = 0; i < times.length; i++) {
        final a = aqis[i] as num?;
        if (a == null) continue;
        all.add(HourPoint(DateTime.parse(times[i]), a.round(), _d(pms[i])));
      }
    }

    double? temp, hum, wind;
    final wc = wx?['current'] as Map<String, dynamic>?;
    if (wc != null) {
      temp = (wc['temperature_2m'] as num?)?.toDouble();
      hum = (wc['relative_humidity_2m'] as num?)?.toDouble();
      wind = (wc['wind_speed_10m'] as num?)?.toDouble();
    }

    final subs = <String, int>{};
    _subFields.forEach((k, field) {
      final v = cur[field];
      if (v is num) subs[k] = v.round();
    });

    return AirData(
      time: now,
      aqi: (cur['us_aqi'] as num?)?.round() ?? 0,
      pm25: _d(cur['pm2_5']),
      pm10: _d(cur['pm10']),
      co: _d(cur['carbon_monoxide']),
      no2: _d(cur['nitrogen_dioxide']),
      so2: _d(cur['sulphur_dioxide']),
      o3: _d(cur['ozone']),
      uv: (cur['uv_index'] as num?)?.toDouble(),
      all: all,
      temp: temp,
      humidity: hum,
      wind: wind,
      subAqi: subs,
    );
  }
}
