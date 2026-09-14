// stats_notifier.dart
// -------------------------------------------------------------------
// AsyncNotifier yang bertanggung jawab mengambil data statistik.
// Menggunakan AsyncNotifier dari Riverpod agar state otomatis berupa
// `AsyncValue<T>` (loading | data | error).
//
// Delay dan logika kegagalan bisa di-override melalui provider
// terpisah agar notifier mudah di-test (dependency injection).
// -------------------------------------------------------------------

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model sederhana untuk satu item statistik.
/// Setiap item memiliki [label] (nama metrik) dan [value] (nilainya).
class StatItem {
  final String label;
  final String value;

  const StatItem({required this.label, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;

  @override
  String toString() => 'StatItem(label: $label, value: $value)';
}

// -------------------------------------------------------------------
// Provider untuk dependency injection:
// Memungkinkan test men-override delay dan logika kegagalan tanpa
// mengubah kode produksi.
// -------------------------------------------------------------------

/// Durasi delay yang digunakan oleh [StatsNotifier.fetchStats].
/// Default: 2 detik. Di-override ke Duration.zero saat testing.
final fetchDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);

/// Fungsi yang menentukan apakah fetch harus gagal.
/// Default: 30% kemungkinan gagal menggunakan Random.
/// Di-override di test dengan fungsi yang selalu return true/false.
final shouldFailProvider = Provider<bool Function()>(
  (ref) => () => Random().nextInt(100) < 30,
);

/// AsyncNotifier yang mensimulasikan pengambilan data statistik.
///
/// - Pada [build], notifier otomatis memanggil [fetchStats].
/// - [fetchStats] menunggu selama [fetchDelayProvider] (default 2 detik),
///   kemudian mengecek [shouldFailProvider] untuk menentukan gagal/berhasil.
/// - Jika berhasil, mengembalikan list berisi 3 item statistik.
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  /// [build] dipanggil saat provider pertama kali dibaca.
  /// Mengembalikan `Future<List<StatItem>>` — Riverpod otomatis
  /// membungkusnya dalam AsyncValue (loading → data / error).
  @override
  Future<List<StatItem>> build() => fetchStats();

  /// Mengambil data statistik dari "server" (disimulasikan).
  ///
  /// - Delay sesuai [fetchDelayProvider] untuk simulasi latensi jaringan.
  /// - Mengecek [shouldFailProvider] untuk 30% kemungkinan gagal.
  /// - Jika berhasil, mengembalikan 3 [StatItem].
  Future<List<StatItem>> fetchStats() async {
    // Baca durasi delay dari provider (bisa di-override di test)
    final delay = ref.read(fetchDelayProvider);
    // Baca fungsi shouldFail dari provider (bisa di-override di test)
    final shouldFail = ref.read(shouldFailProvider);

    // Simulasi latensi jaringan
    await Future.delayed(delay);

    // Cek apakah harus gagal (30% di produksi, deterministik di test)
    if (shouldFail()) {
      throw Exception('Gagal mengambil data statistik. Coba lagi.');
    }

    // Data statistik dummy yang dikembalikan saat berhasil
    return const [
      StatItem(label: 'Pengguna Aktif', value: '1.234'),
      StatItem(label: 'Transaksi Hari Ini', value: '567'),
      StatItem(label: 'Pendapatan', value: 'Rp 12.500.000'),
    ];
  }

  /// Dipanggil saat pengguna menekan tombol "Coba Lagi".
  /// Mengeset state ke loading, lalu memanggil ulang [fetchStats].
  Future<void> retry() async {
    // Set state ke AsyncLoading agar UI menampilkan spinner
    state = const AsyncValue.loading();

    // Panggil fetchStats dan tangkap hasilnya via AsyncValue.guard,
    // yang otomatis membungkus result / exception ke AsyncValue.
    state = await AsyncValue.guard(() => fetchStats());
  }
}

/// Provider global yang mengekspos [StatsNotifier].
///
/// Tipe: `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`
/// — Widget mengaksesnya via `ref.watch(statsProvider)` untuk mendapat
///   `AsyncValue<List<StatItem>>`.
/// — Untuk memanggil method (retry), gunakan
///   `ref.read(statsProvider.notifier).retry()`.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
