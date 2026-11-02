import 'package:flutter_test/flutter_test.dart';
import 'package:udara_kita/aqi_utils.dart';
import 'package:udara_kita/insights.dart';
import 'package:udara_kita/models.dart';

void main() {
  group('Kategori US AQI', () {
    test('batas tiap kategori benar', () {
      expect(levelIndex(0), 0);
      expect(levelIndex(50), 0);
      expect(levelIndex(51), 1);
      expect(levelIndex(100), 1);
      expect(levelIndex(101), 2);
      expect(levelIndex(150), 2);
      expect(levelIndex(151), 3);
      expect(levelIndex(200), 3);
      expect(levelIndex(201), 4);
      expect(levelIndex(300), 4);
      expect(levelIndex(301), 5);
    });

    test('label dan jumlah rentang konsisten', () {
      expect(aqiLevels.length, aqiRanges.length);
      expect(levelFor(42).label, 'Baik');
      expect(levelFor(320).label, 'Berbahaya');
    });
  });

  group('City', () {
    test('emoji bendera dari kode negara', () {
      const c = City(name: 'Samarinda', cc: 'ID', lat: 0, lon: 0);
      expect(c.flag, String.fromCharCodes([0x1F1EE, 0x1F1E9]));
      expect(const City(name: 'X', lat: 0, lon: 0).flag, isNull);
    });

    test('toJson dan fromJson konsisten', () {
      final back = City.fromJson(City.defaultCity.toJson());
      expect(back, City.defaultCity);
      expect(back.cc, 'ID');
      expect(back.name, 'Samarinda');
    });

    test('fromGeo membaca respons geocoding', () {
      final c = City.fromGeo({
        'name': 'Balikpapan',
        'admin1': 'Kalimantan Timur',
        'country': 'Indonesia',
        'country_code': 'ID',
        'latitude': -1.2675,
        'longitude': 116.8289,
      });
      expect(c.subtitle, 'Kalimantan Timur, Indonesia');
      expect(c.lat, -1.2675);
    });
  });

  group('AirData.fromJson', () {
    final air = <String, dynamic>{
      'current': {
        'time': '2026-10-30T09:00',
        'us_aqi': 87,
        'pm2_5': 30.5,
        'pm10': 40.1,
        'carbon_monoxide': 300.0,
        'nitrogen_dioxide': 12.0,
        'sulphur_dioxide': 5.0,
        'ozone': 60.0,
        'uv_index': 6.5,
        'us_aqi_pm2_5': 87,
        'us_aqi_pm10': 37,
        'us_aqi_ozone': 40,
      },
      'hourly': {
        'time': ['2026-10-30T08:00', '2026-10-30T09:00', '2026-10-30T10:00'],
        'us_aqi': [80, null, 90],
        'pm2_5': [28.0, null, 33.0],
      },
    };
    final wx = <String, dynamic>{
      'current': {'temperature_2m': 31.4, 'relative_humidity_2m': 70, 'wind_speed_10m': 8.2},
    };

    test('membaca nilai saat ini dan cuaca', () {
      final d = AirData.fromJson(air, wx);
      expect(d.aqi, 87);
      expect(d.pm25, 30.5);
      expect(d.uv, 6.5);
      expect(d.temp, 31.4);
      expect(d.humidity, 70);
    });

    test('titik per jam yang null dilewati', () {
      final d = AirData.fromJson(air, null);
      expect(d.all.length, 2);
      expect(d.temp, isNull);
    });

    test('polutan dominan = AQI per polutan tertinggi', () {
      final d = AirData.fromJson(air, null);
      expect(d.dominantKey, 'pm25');
      expect(d.subAqi['pm10'], 37);
    });

    test('tanpa AQI per polutan, dominan kosong', () {
      final basic = <String, dynamic>{
        'current': {'time': '2026-10-30T09:00', 'us_aqi': 40},
      };
      expect(AirData.fromJson(basic, null).dominantKey, isNull);
    });
  });

  group('bestWindow', () {
    // Satu hari penuh: AQI tinggi di malam hari, terendah pukul 06-08.
    List<HourPoint> day() {
      return [
        for (var h = 0; h < 24; h++)
          HourPoint(DateTime(2026, 10, 30, h), (h >= 6 && h <= 8) ? 20 : (h < 5 ? 5 : 60), 10),
      ];
    }

    test('hanya memilih jam aktif (bukan dini hari)', () {
      final w = bestWindow(day())!;
      expect(w.start.hour, 6);
      expect(w.end.hour, 9);
      expect(w.avg, 20);
    });

    test('jam yang sudah lewat tidak dipilih untuk hari ini', () {
      final w = bestWindow(day(), notBefore: DateTime(2026, 10, 30, 12))!;
      expect(w.start.hour >= 12, isTrue);
    });

    test('mengembalikan null bila tidak ada jam yang tersisa', () {
      expect(bestWindow(day(), notBefore: DateTime(2026, 10, 30, 23)), isNull);
    });
  });
}
