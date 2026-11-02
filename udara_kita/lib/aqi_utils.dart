import 'package:flutter/material.dart';

class AqiLevel {
  final String label;
  final Color color;
  final List<Color> gradient;
  final String advice;
  final String mask;
  final String maskShort;

  const AqiLevel(this.label, this.color, this.gradient, this.advice, this.mask, this.maskShort);
}

const aqiLevels = <AqiLevel>[
  AqiLevel(
    'Baik',
    Color(0xFF3DDC97),
    [Color(0xFF1FB5A0), Color(0xFF0E6BA8), Color(0xFF0A2342)],
    'Udara bersih dan segar. Waktu yang pas untuk beraktivitas di luar ruangan.',
    'Tidak perlu masker. Nikmati udara segarnya!',
    'Tak perlu',
  ),
  AqiLevel(
    'Sedang',
    Color(0xFFFFD84D),
    [Color(0xFFE8A33D), Color(0xFFB5651D), Color(0xFF3D2314)],
    'Kualitas udara dapat diterima. Orang yang sangat sensitif sebaiknya mengurangi aktivitas berat di luar.',
    'Masker hanya perlu untuk orang yang sangat sensitif.',
    'Bila sensitif',
  ),
  AqiLevel(
    'Tidak Sehat (Sensitif)',
    Color(0xFFFF9F43),
    [Color(0xFFF2773D), Color(0xFFB5412B), Color(0xFF3A1414)],
    'Kelompok sensitif (asma, anak-anak, lansia) sebaiknya membatasi aktivitas di luar.',
    'Disarankan memakai masker medis saat di luar ruangan, terutama kelompok sensitif.',
    'Masker medis',
  ),
  AqiLevel(
    'Tidak Sehat',
    Color(0xFFFF6B6B),
    [Color(0xFFE5484D), Color(0xFF9B2335), Color(0xFF2D0F1B)],
    'Semua orang bisa mulai merasakan dampaknya. Kurangi aktivitas berat di luar dan pakai masker.',
    'Pakai masker KN95/N95 saat keluar rumah.',
    'KN95 / N95',
  ),
  AqiLevel(
    'Sangat Tidak Sehat',
    Color(0xFFC77DFF),
    [Color(0xFFA24DD6), Color(0xFF5B2A86), Color(0xFF1E0F3C)],
    'Risiko kesehatan meningkat. Hindari aktivitas di luar ruangan dan gunakan masker N95.',
    'Wajib masker N95 bila terpaksa keluar. Hindari aktivitas luar.',
    'Wajib N95',
  ),
  AqiLevel(
    'Berbahaya',
    Color(0xFFFF6E9C),
    [Color(0xFFC2185B), Color(0xFF6A1B3F), Color(0xFF1A0A14)],
    'Kondisi darurat. Tetap di dalam ruangan, tutup jendela, dan gunakan penjernih udara bila ada.',
    'Tetap di dalam ruangan. Bila terpaksa keluar, gunakan masker N95 yang terpasang rapat.',
    'Di dalam saja',
  ),
];

int levelIndex(int aqi) {
  if (aqi <= 50) return 0;
  if (aqi <= 100) return 1;
  if (aqi <= 150) return 2;
  if (aqi <= 200) return 3;
  if (aqi <= 300) return 4;
  return 5;
}

AqiLevel levelFor(int aqi) => aqiLevels[levelIndex(aqi)];

class HealthProfile {
  final String name;
  final IconData icon;
  final int shift;
  final String note;
  const HealthProfile(this.name, this.icon, this.shift, this.note);
}

const healthProfiles = <HealthProfile>[
  HealthProfile('Umum', Icons.person_rounded, 0,
      'Panduan umum untuk orang dewasa yang sehat.'),
  HealthProfile('Anak-anak', Icons.child_care_rounded, 25,
      'Anak bernapas lebih cepat dan parunya masih berkembang, jadi lebih rentan. Batasi bermain di luar saat udara kurang baik.'),
  HealthProfile('Lansia', Icons.elderly_rounded, 25,
      'Lansia lebih rentan terhadap polusi. Hindari berjalan jauh di luar saat AQI tinggi dan pantau gejala batuk atau sesak.'),
  HealthProfile('Gangguan napas', Icons.air_rounded, 50,
      'Penderita asma atau gangguan napas lebih mudah kambuh. Siapkan obat sesuai anjuran dokter dan kurangi aktivitas luar saat AQI tinggi.'),
  HealthProfile('Atlet', Icons.fitness_center_rounded, 15,
      'Olahraga intens membuat napas lebih dalam sehingga paparan lebih besar. Pindahkan latihan berat ke dalam ruangan saat AQI tinggi.'),
];

class Activity {
  final String name;
  final IconData icon;
  final int okMax;
  final int cautionMax;
  const Activity(this.name, this.icon, this.okMax, this.cautionMax);

  String status(int aqi) {
    if (aqi <= okMax) return 'Aman';
    if (aqi <= cautionMax) return 'Hati-hati';
    return 'Hindari';
  }

  Color statusColor(int aqi) {
    if (aqi <= okMax) return Colors.greenAccent;
    if (aqi <= cautionMax) return Colors.amberAccent;
    return Colors.redAccent;
  }
}

const activities = <Activity>[
  Activity('Jogging / olahraga luar', Icons.directions_run_rounded, 50, 100),
  Activity('Bersepeda', Icons.pedal_bike_rounded, 50, 100),
  Activity('Anak bermain di luar', Icons.child_care_rounded, 50, 100),
  Activity('Naik motor tanpa masker', Icons.two_wheeler_rounded, 100, 150),
  Activity('Menjemur pakaian', Icons.dry_cleaning_rounded, 100, 150),
  Activity('Membuka jendela', Icons.window_rounded, 100, 150),
];

/// Info tiap polutan + pedoman WHO 2021 (µg/m³).
class PollutantInfo {
  final String key;
  final String name;
  final String short;
  final String desc;
  final String sources;
  final double who;
  final String whoNote;
  const PollutantInfo(this.key, this.name, this.short, this.desc, this.sources, this.who, this.whoNote);
}

const pollutantInfos = <PollutantInfo>[
  PollutantInfo(
    'pm25',
    'PM2.5',
    'Partikel halus',
    'Partikel sangat kecil (kurang dari 2,5 mikron) yang dapat masuk jauh ke paru-paru dan aliran darah.',
    'Asap kendaraan, kebakaran lahan, pembakaran sampah, industri.',
    15,
    'rata-rata 24 jam',
  ),
  PollutantInfo(
    'pm10',
    'PM10',
    'Debu kasar',
    'Debu dan partikel (kurang dari 10 mikron) yang mengiritasi mata, hidung, dan tenggorokan.',
    'Debu jalan, konstruksi, pembakaran.',
    45,
    'rata-rata 24 jam',
  ),
  PollutantInfo(
    'no2',
    'NO₂',
    'Gas kendaraan',
    'Gas yang memicu peradangan saluran napas dan dapat memperparah asma.',
    'Knalpot kendaraan bermotor, pembangkit listrik.',
    25,
    'rata-rata 24 jam',
  ),
  PollutantInfo(
    'o3',
    'O₃',
    'Ozon',
    'Ozon permukaan terbentuk dari reaksi polutan dengan sinar matahari dan mengiritasi paru-paru.',
    'Reaksi gas buang kendaraan dan industri di bawah terik matahari.',
    100,
    'rata-rata 8 jam (musim puncak)',
  ),
  PollutantInfo(
    'so2',
    'SO₂',
    'Belerang',
    'Gas berbau tajam yang mengiritasi saluran pernapasan.',
    'Pembakaran batu bara dan minyak, industri, gunung berapi.',
    40,
    'rata-rata 24 jam',
  ),
  PollutantInfo(
    'co',
    'CO',
    'Karbon monoksida',
    'Gas tak berbau yang mengurangi kemampuan darah membawa oksigen.',
    'Pembakaran tidak sempurna pada kendaraan, kompor, dan pembakaran sampah.',
    4000,
    'rata-rata 24 jam',
  ),
];

const aqiRanges = ['0–50', '51–100', '101–150', '151–200', '201–300', '301+'];

const _dn = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _mn = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String dayShort(DateTime d) => _dn[d.weekday - 1];
String dateLabel(DateTime d) => '${_dn[d.weekday - 1]}, ${d.day} ${_mn[d.month - 1]}';
String fmtHour(DateTime t) => '${t.hour.toString().padLeft(2, '0')}.00';
String fmtTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
