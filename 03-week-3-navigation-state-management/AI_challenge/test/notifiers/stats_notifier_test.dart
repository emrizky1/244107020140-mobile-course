// stats_notifier_test.dart
// -------------------------------------------------------------------
// Unit test untuk StatsNotifier dan StatItem.
//
// Strategi testing:
// 1. Test StatItem (model) secara langsung — equality, toString.
// 2. Test StatsNotifier melalui ProviderContainer dengan override:
//    - fetchDelayProvider → Duration.zero (tanpa delay)
//    - shouldFailProvider → () => false (selalu sukses) atau
//      () => true (selalu gagal), tergantung skenario test.
// 3. Gunakan `container.listen` + Completer untuk menunggu state
//    berubah dari loading ke data/error.
// -------------------------------------------------------------------

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_app/notifiers/stats_notifier.dart';

void main() {
  // =================================================================
  // Helper: Membuat ProviderContainer dengan override standar
  // =================================================================

  /// Membuat [ProviderContainer] dengan delay = Duration.zero
  /// dan shouldFail sesuai parameter [fail].
  ProviderContainer createContainer({required bool fail}) {
    return ProviderContainer(
      overrides: [
        // Override delay menjadi 0 agar test cepat
        fetchDelayProvider.overrideWithValue(Duration.zero),
        // Override shouldFail agar deterministik
        shouldFailProvider.overrideWithValue(() => fail),
      ],
    );
  }

  /// Menunggu [statsProvider] selesai loading (menjadi data atau error).
  /// Menggunakan `listen` untuk mendeteksi perubahan state.
  Future<AsyncValue<List<StatItem>>> waitForResult(
    ProviderContainer container,
  ) async {
    final completer = Completer<AsyncValue<List<StatItem>>>();

    // Listen ke perubahan state provider
    container.listen<AsyncValue<List<StatItem>>>(
      statsProvider,
      (previous, next) {
        // Selesaikan completer saat state sudah memiliki data atau error.
        // Di Riverpod 3.x, error bisa dibungkus dalam AsyncLoading (retrying),
        // jadi kita cek hasValue atau hasError, bukan hanya tipe.
        if (!completer.isCompleted && (next.hasValue || next.hasError)) {
          // Kecuali jika ini masih loading murni (tanpa data/error sebelumnya)
          if (next is! AsyncLoading || next.hasError) {
            completer.complete(next);
          }
        }
      },
      fireImmediately: true,
    );

    // Pump microtasks agar Future.delayed(Duration.zero) bisa resolve.
    // Beberapa pump diperlukan karena Riverpod memproses state secara async.
    for (int i = 0; i < 5; i++) {
      await Future.delayed(Duration.zero);
    }

    // Tunggu dengan timeout sebagai safety net
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => container.read(statsProvider),
    );
  }

  // =================================================================
  // Grup test untuk StatItem (model)
  // =================================================================
  group('StatItem', () {
    // ---------------------------------------------------------------
    // Test: operator == bekerja — dua StatItem dengan field sama = equal
    // ---------------------------------------------------------------
    test('equality bekerja dengan benar', () {
      const a = StatItem(label: 'Test', value: '100');
      const b = StatItem(label: 'Test', value: '100');
      const c = StatItem(label: 'Lain', value: '200');

      expect(a, equals(b)); // a == b
      expect(a, isNot(equals(c))); // a != c
      expect(a.hashCode, b.hashCode); // hashCode konsisten
    });

    // ---------------------------------------------------------------
    // Test: toString mengembalikan representasi string yang benar
    // ---------------------------------------------------------------
    test('toString mengembalikan format yang benar', () {
      const item = StatItem(label: 'Users', value: '42');
      expect(item.toString(), 'StatItem(label: Users, value: 42)');
    });
  });

  // =================================================================
  // Grup test untuk StatsNotifier
  // =================================================================
  group('StatsNotifier', () {
    // ---------------------------------------------------------------
    // Test: State awal harus AsyncLoading
    // ---------------------------------------------------------------
    test('state awal adalah AsyncLoading', () {
      final container = createContainer(fail: false);
      addTearDown(container.dispose);

      // State awal langsung setelah read harus loading
      final state = container.read(statsProvider);
      expect(state, isA<AsyncLoading<List<StatItem>>>());
    });

    // ---------------------------------------------------------------
    // Test: fetchStats berhasil → 3 StatItem dengan data benar
    // ---------------------------------------------------------------
    test('fetchStats berhasil mengembalikan 3 StatItem', () async {
      // Buat container dengan fail = false (selalu sukses)
      final container = createContainer(fail: false);
      addTearDown(container.dispose);

      // Tunggu provider selesai loading
      final result = await waitForResult(container);

      // Harus berhasil (AsyncData)
      expect(result, isA<AsyncData<List<StatItem>>>());

      final data = (result as AsyncData<List<StatItem>>).value;

      // Verifikasi jumlah item
      expect(data.length, 3);

      // Verifikasi setiap item
      expect(data[0], const StatItem(label: 'Pengguna Aktif', value: '1.234'));
      expect(
        data[1],
        const StatItem(label: 'Transaksi Hari Ini', value: '567'),
      );
      expect(
        data[2],
        const StatItem(label: 'Pendapatan', value: 'Rp 12.500.000'),
      );
    });

    // ---------------------------------------------------------------
    // Test: fetchStats gagal → AsyncError dengan pesan yang benar
    // ---------------------------------------------------------------
    test('fetchStats melempar exception saat simulasi gagal', () async {
      // Buat container dengan fail = true (selalu gagal)
      final container = createContainer(fail: true);
      addTearDown(container.dispose);

      // Tunggu provider selesai loading
      final result = await waitForResult(container);

      // Harus memiliki error (bisa berupa AsyncError atau
      // AsyncLoading dengan error tertanam di Riverpod 3.x)
      expect(result.hasError, isTrue,
          reason: 'State harus memiliki error setelah fetch gagal');

      // Verifikasi pesan error
      expect(result.error.toString(),
          contains('Gagal mengambil data statistik'));
    });

    // ---------------------------------------------------------------
    // Test: retry() mengeset state ke loading, lalu resolves
    // ---------------------------------------------------------------
    test('retry() mengeset state ke loading lalu menghasilkan hasil baru',
        () async {
      // Buat container dengan fail = false (sukses)
      final container = createContainer(fail: false);
      addTearDown(container.dispose);

      // Tunggu build awal selesai
      await waitForResult(container);

      // Verifikasi state awal berhasil
      expect(container.read(statsProvider), isA<AsyncData<List<StatItem>>>());

      // Panggil retry — ini langsung set state ke loading
      final retryFuture = container.read(statsProvider.notifier).retry();

      // Segera setelah panggilan, state harus loading
      expect(container.read(statsProvider), isA<AsyncLoading<List<StatItem>>>());

      // Tunggu retry selesai
      await retryFuture;

      // State harus berupa data (karena fail = false)
      final finalState = container.read(statsProvider);
      expect(finalState, isA<AsyncData<List<StatItem>>>());
    });
  });
}
