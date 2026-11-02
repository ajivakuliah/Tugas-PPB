#!/usr/bin/env bash
# Membuat folder platform Android lalu menambahkan izin INTERNET.
# Jalankan dari root proyek:  bash tool/setup_android.sh
set -e

flutter create --platforms=android --project-name udara_kita --org id.udarakita .

MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST"
fi
sed -i 's|android:label="[^"]*"|android:label="Udara Kita"|' "$MANIFEST"

flutter pub get
echo "Selesai. Jalankan: flutter run"
