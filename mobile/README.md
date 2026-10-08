# Tracker Android

Aplikasi Flutter/Dart di monorepo ini menggunakan backend Tracker yang sama dengan `app/`. Layar mengikuti desain mobile web: krem, lime, kartu saldo gelap, navigasi bawah dan mode gelap. Ikon memakai aset Tracker yang sudah ada. Font menggunakan font sistem Android; font web Plus Jakarta Sans/JetBrains Mono belum dibundel.

Fitur: login/daftar/session persisten/logout; dashboard saldo dan ringkasan bulanan; pencarian/filter catatan; tambah transaksi dua tahap; kategori AI dari backend; konfirmasi/koreksi kategori dan hapus draft; teman/permintaan; utang/piutang/pelunasan; ubah username; Discord dan pengaturan notifikasi. Semua data berasal dari server. Aplikasi memerlukan internet; tidak menyediakan transaksi offline. Login tersimpan sebagai cookie terenkripsi menggunakan Android secure storage; password tidak disimpan.

## Setup dan build APK

Install [Flutter 3.35.7](https://docs.flutter.dev/install/archive) dan [Android SDK](https://docs.flutter.dev/platform-integration/android/setup), gunakan JDK 17. SDK Android API 36 dan NDK 27.0.12077973 digunakan oleh versi Flutter ini. Minimum perangkat Android 7.0/API 24.

```bash
flutter doctor
flutter doctor --android-licenses
cd mobile
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release
```

APK universal: `mobile/build/app/outputs/flutter-apk/app-release.apk`. Salin ke Android, lalu buka file dan izinkan instalasi dari aplikasi pengelola file. Untuk perangkat yang terhubung via USB debugging:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Perintah ringkas dari root repo:

```bash
bash mobile/tool/build-apk.sh
# APK per arsitektur, ukuran unduhan lebih kecil:
bash mobile/tool/build-apk.sh --split-per-abi
```

Flutter memasang Gradle wrapper yang belum ada saat build; `local.properties` dihasilkan oleh Flutter. Jangan menjalankan `flutter create .` karena konfigurasi Android khusus aplikasi sudah tersedia. Commit `pubspec.lock` setelah `flutter pub get` berhasil untuk mengunci seluruh dependency transitif.

## URL backend

Default `https://tracker.adrianportofolio.my.id/api/`. HTTPS domain tersebut harus sudah aktif dan `/api/health/ready` tersedia. Nginx/Compose yang sekarang sudah menyediakan jalur `/api/`; tidak perlu port backend baru atau layanan model Android.

```bash
flutter build apk --release \
  --dart-define=TRACKER_API_URL=https://tracker.adrianportofolio.my.id/api/
```

Konfigurasi ini hanya berisi URL publik, bukan rahasia. APK release menolak HTTP. Untuk emulator dengan Docker frontend lokal pada port 8080:

```bash
flutter run --dart-define=TRACKER_API_URL=http://10.0.2.2:8080/api/
```

Untuk HP fisik gunakan IP LAN komputer frontend, bukan `localhost`. Jika langsung mengakses Furnace tanpa Nginx, gunakan root backend seperti `http://10.0.2.2:8080/` karena routing Furnace tidak memiliki prefix `/api`. Debug build mengizinkan HTTP lokal; `COOKIE_SECURE=false` diperlukan pada server HTTP. Request Android memakai cookie API secara langsung dan tidak mengirim header browser Origin/Sec-Fetch-Site. Backend tetap memvalidasi session dan otorisasi.

## Build lewat GitHub

Push perubahan ini ke GitHub, buka **Actions → Tracker Android APK → Run workflow**. Isi URL HTTPS API, tunggu analyze/test/build selesai, unduh artifact `tracker-android` dan ekstrak APK. Workflow juga berjalan untuk pull request yang mengubah `mobile/`. Artifact menyertakan `pubspec.lock` hasil resolusi untuk bisa di-commit. Workflow belum dijalankan dari workspace ini.

## Signing

Build tanpa `android/key.properties` memakai debug keystore agar APK lokal bisa diinstal. Untuk versi yang dibagikan dan diperbarui, buat serta simpan keystore sendiri. Debug key CI bersifat sementara sehingga APK dari build CI berbeda bisa meminta uninstall versi lama. Jangan memakai debug signing untuk publikasi Play Store.

```bash
keytool -genkeypair -v -keystore tracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias tracker
```

Buat `mobile/android/key.properties` yang diabaikan Git:

```properties
storeFile=/absolute/path/to/tracker-release.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyPassword=YOUR_PRIVATE_PASSWORD
keyAlias=tracker
```

Build kembali; Gradle otomatis memakai key tersebut. Simpan key yang sama untuk update dengan `adb install -r`. Keystore, password signing, `.env`, SDK paths dan hasil build tidak ikut commit. Workflow CI saat ini menghasilkan APK untuk instalasi percobaan; release signing dikerjakan lokal.

## Verifikasi

Tes source mencakup parsing DTO/filter/nominal, persistensi dan kedaluwarsa cookie, refresh bersamaan, login gagal, session habis, network failure dan alur widget. Di lingkungan implementasi saat ini Flutter/Dart/Android SDK tidak tersedia dan unduhan terminal gagal DNS, sehingga `flutter analyze`, `flutter test`, dan build APK belum dijalankan. APK belum dihasilkan atau diuji pada perangkat. Jalankan perintah di atas atau workflow untuk validasi tersebut; jangan menganggap pemeriksaan statis sebagai hasil kompilasi.

Setelah build, cek pada HP: daftar/login, restart aplikasi, create/commit kategori, pencarian dan filter, teman dengan dua akun, pinjam/bayar, rename, dark mode, Discord bila bot dikonfigurasi, logout, koneksi terputus dan refresh setelah 10 menit. Integrasi backend/VPS dan Discord membutuhkan server yang berjalan.
