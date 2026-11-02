import 'package:flutter/material.dart';

import 'aqi_utils.dart';
import 'ui.dart';

/// Halaman edukasi: skala AQI, penjelasan polutan, sumber data, dan catatan akurasi.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: pageGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Text('Tentang & Edukasi', style: ts(22, weight: FontWeight.w800)),
              ]),
              const SectionTitle('Skala US AQI', subtitle: 'Semakin tinggi angkanya, semakin buruk udaranya'),
              Glass(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(children: [
                  for (var i = 0; i < aqiLevels.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: aqiLevels[i].color),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 62,
                          child: Text(aqiRanges[i], style: ts(14, weight: FontWeight.w800, color: aqiLevels[i].color)),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(aqiLevels[i].label, style: ts(14, weight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(aqiLevels[i].advice, style: ts(12, color: Colors.white70, height: 1.35)),
                          ]),
                        ),
                      ]),
                    ),
                ]),
              ),
              const SectionTitle('Mengenal polutan', subtitle: 'Ketuk untuk membaca penjelasan'),
              Glass(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Column(children: [
                    for (final p in pollutantInfos)
                      ExpansionTile(
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white70,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text('${p.name} · ${p.short}', style: ts(15, weight: FontWeight.w700)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.desc, style: ts(13, height: 1.4)),
                          const SizedBox(height: 8),
                          Text('Sumber umum: ${p.sources}', style: ts(12, color: Colors.white70, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(
                            'Pedoman WHO 2021: ${p.who.toStringAsFixed(0)} µg/m³ (${p.whoNote})',
                            style: ts(12, color: Colors.white70, height: 1.4),
                          ),
                        ],
                      ),
                  ]),
                ),
              ),
              const SectionTitle('Sumber data'),
              Glass(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _src('Open-Meteo Air Quality API', 'AQI, polutan, indeks UV, dan prakiraan per jam. Data berasal dari model CAMS (Copernicus Atmosphere Monitoring Service).'),
                  _src('Open-Meteo Forecast API', 'Suhu, kelembapan, dan kecepatan angin.'),
                  _src('Open-Meteo Geocoding API', 'Pencarian kota (data GeoNames).'),
                  const SizedBox(height: 4),
                  Text('Semua gratis dan tanpa API key. Atribusi: Open-Meteo.com & CAMS.',
                      style: ts(12, color: Colors.white60, height: 1.4)),
                ]),
              ),
              const SectionTitle('Catatan penting'),
              Glass(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _note('Data adalah hasil model prakiraan, bukan pembacaan alat ukur di lokasimu. Angkanya bisa berbeda dari stasiun pemantau lokal.'),
                  _note('Konsentrasi yang ditampilkan adalah nilai saat ini, sedangkan pedoman WHO memakai rata-rata 24 jam (O₃: 8 jam). Perbandingannya bersifat indikatif.'),
                  _note('Penyesuaian profil kesehatan dan perkiraan setara rokok adalah pendekatan sederhana, bukan standar medis.'),
                  _note('Aplikasi ini tidak menggantikan nasihat dokter.'),
                ]),
              ),
              const SizedBox(height: 20),
              Center(child: Text('Udara Kita · versi 3.0.0', style: ts(11, color: Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _src(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: ts(14, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body, style: ts(12, color: Colors.white70, height: 1.4)),
        ]),
      );

  static Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amberAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: ts(12, color: Colors.white70, height: 1.4))),
        ]),
      );
}
