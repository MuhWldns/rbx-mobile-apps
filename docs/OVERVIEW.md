# RBX Royale Mobile App

Aplikasi mobile pendamping untuk layanan RBX Royale. Aplikasi ini memberikan akses ke akun, saldo wallet, license, dan pembayaran langsung dari perangkat Android/iOS.

## Tentang Aplikasi

RBX Royale Mobile adalah klien Flutter yang terhubung ke backend RBX Royale (`api-rbx.muhwldns.me`). Aplikasi mengandalkan session cookie dari proses OAuth untuk berkomunikasi dengan API, sehingga pengalaman login mengikuti versi web tanpa perlu manajemen password.

Bahasa antarmuka utama adalah Bahasa Indonesia, dengan format mata uang Rupiah dan tema gelap (violet–fuchsia) yang konsisten dengan brand RBX Royale.

## Fitur

### Autentikasi
- Login dengan akun Google atau Discord melalui OAuth.
- Sesi tetap aktif setelah aplikasi ditutup; user tidak perlu login ulang sampai logout manual.
- Logout aman yang membersihkan sesi di perangkat.

### Dashboard
- Sapaan personal berdasarkan nama user.
- Ringkasan saldo wallet dalam Rupiah.
- Jumlah license aktif yang dimiliki user.
- Indikator pemakaian kuota audio harian (free audio) — berapa banyak yang sudah dipakai hari ini dari batas harian.

### Top Up Saldo
- Pilih nominal cepat (Rp 10.000 – Rp 500.000) atau ketik nominal manual.
- Pembayaran via QRIS — QR Code ditampilkan langsung di aplikasi untuk discan dengan e-wallet/m-banking.
- Status pembayaran dipantau otomatis (auto-polling) dengan batas waktu 5 menit.
- Saldo wallet otomatis ter-refresh begitu pembayaran terdeteksi sukses.
- State pembayaran tertangani: berhasil, gagal/dibatalkan, dan timeout, dengan opsi mengulang dari awal.

### Profile
- Tampilkan informasi akun: email, nama, avatar, provider login (Google/Discord), dan waktu login terakhir.
- Statistik akun: saldo wallet, total top-up sepanjang masa, total pengeluaran.
- Set / update **Roblox User ID** untuk menghubungkan akun ke profil Roblox. Input divalidasi (hanya angka) sebelum dikirim ke server.

### Navigasi
- Bottom navigation tiga tab: Dashboard, Top Up, Profile.
- Halaman login terpisah dan otomatis muncul saat user belum/keluar dari sesi.
- Redirect otomatis ke dashboard setelah login sukses.

## Yang Belum Tersedia

Fitur berikut belum tersedia di versi mobile saat ini:
- Riwayat transaksi top-up.
- Manajemen detail license (mis. whitelist game per license).
- Halaman audio / pemakaian fitur audio (data kuotanya hanya muncul sebagai indikator di dashboard).
- Push notification.

## Platform

- Target utama: Android & iOS.
- Dibangun dengan Flutter (Dart SDK ^3.11.4).
