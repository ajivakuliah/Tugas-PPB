# Cara mengambil screenshot untuk README

README memanggil 6 gambar di folder `docs/screenshots/`. Nama file harus persis:

| File | Layar yang di-capture |
|---|---|
| `home.png` | Tab **Beranda** (gauge + maskot, tunggu animasi selesai) |
| `forecast.png` | Tab **Prakiraan** (grafik + jendela emas + peta warna) |
| `explore.png` | Tab **Jelajah** (peringkat kota) |
| `health.png` | Tab **Sehat** (pilih profil, mis. "Gangguan napas") |
| `search.png` | Halaman **Cari kota** (ketuk nama kota di Beranda) |
| `about.png` | **Tentang & edukasi** (menu ⋮ di Beranda) |

## Cara capture

**Emulator Android Studio:** klik ikon kamera di panel samping emulator, lalu ganti nama file.

**HP asli / emulator via terminal:**

```bash
adb exec-out screencap -p > docs/screenshots/home.png
```

**Flutter:** saat `flutter run` berjalan, tekan `s` di terminal untuk menyimpan screenshot.

## Tips agar hasilnya bagus

- Gunakan emulator/HP dengan rasio layar modern (mis. Pixel 6) dan **mode potret**.
- Tunggu data selesai dimuat (tidak ada skeleton berkilau).
- Coba beberapa kota supaya ada variasi warna langit, misalnya Delhi atau Beijing untuk udara tercemar, Zurich untuk udara bersih.
- Setelah semua file ada, commit dan push: `git add docs/screenshots && git commit -m "docs: tambah screenshot" && git push`.
