// stats_page.dart
// -------------------------------------------------------------------
// Halaman utama yang menampilkan data statistik.
// Menggunakan ConsumerWidget dari flutter_riverpod agar bisa
// mengakses provider melalui WidgetRef.
// -------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/stats_notifier.dart';

/// [StatsPage] adalah ConsumerWidget — varian StatelessWidget dari
/// Riverpod yang menyediakan [WidgetRef] untuk membaca provider.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ---------------------------------------------------------------
    // ref.watch(statsProvider) mengembalikan AsyncValue<List<StatItem>>.
    // AsyncValue memiliki 3 sub-state:
    //   - AsyncLoading → data sedang dimuat
    //   - AsyncError   → terjadi kesalahan
    //   - AsyncData    → data berhasil dimuat
    // ---------------------------------------------------------------
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      // AppBar dengan judul halaman
      appBar: AppBar(
        title: const Text('Statistik'),
        centerTitle: true,
      ),
      // Body menggunakan pattern matching pada AsyncValue
      body: statsAsync.when(
        // ---- STATE: LOADING ----
        // Menampilkan spinner di tengah layar saat data sedang dimuat
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data statistik...'),
            ],
          ),
        ),

        // ---- STATE: ERROR ----
        // Menampilkan pesan error dan tombol "Coba Lagi"
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikon error besar berwarna merah
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),

                // Pesan error yang diterima dari exception
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Tombol retry — memanggil notifier.retry()
                ElevatedButton.icon(
                  onPressed: () {
                    // ref.read (bukan ref.watch) untuk aksi sekali jalan.
                    // Memanggil retry() pada notifier untuk memuat ulang data.
                    ref.read(statsProvider.notifier).retry();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),

        // ---- STATE: SUCCESS ----
        // Menampilkan data dalam ListView dengan 3 item statistik
        data: (stats) => ListView.separated(
          padding: const EdgeInsets.all(16),
          // Jumlah item sesuai panjang list yang diterima
          itemCount: stats.length,
          // Separator antar item berupa garis horizontal tipis
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, index) {
            final item = stats[index];

            // Setiap item ditampilkan dalam Card dengan ListTile
            return Card(
              elevation: 2,
              child: ListTile(
                // Ikon leading berupa lingkaran bernomor
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                // Label statistik sebagai judul
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Nilai statistik sebagai subtitle
                subtitle: Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
