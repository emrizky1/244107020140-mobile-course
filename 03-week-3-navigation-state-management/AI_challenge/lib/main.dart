// main.dart
// -------------------------------------------------------------------
// Entry point aplikasi Flutter.
// Membungkus seluruh widget tree dengan ProviderScope agar semua
// widget turunan bisa mengakses Riverpod provider.
// -------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/stats_page.dart';

void main() {
  // ProviderScope adalah widget wajib dari Riverpod.
  // Harus berada di root widget tree agar provider bisa di-resolve
  // oleh seluruh widget di bawahnya.
  runApp(
    const ProviderScope(
      child: StatsApp(),
    ),
  );
}

/// Widget root aplikasi.
class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stats App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      // Halaman awal adalah StatsPage
      home: const StatsPage(),
    );
  }
}
