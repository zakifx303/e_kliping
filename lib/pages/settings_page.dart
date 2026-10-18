// Lokasi: lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../main.dart'; // Mengimpor sakelar global dari main.dart

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('SETTINGS', style: TextStyle(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade400, height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ikon penanda mode (warna kuning/amber agar mirip gambar)
            const Icon(
              Icons.brightness_6_outlined,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),

            // Teks Mode Gelap dengan garis bawah
            const Expanded(
              child: Text(
                'MODE GELAP',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            // Tombol Switch yang terhubung dengan sakelar global
            ValueListenableBuilder<bool>(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDark, child) {
                return Switch(
                  value: isDark,
                  onChanged: (value) {
                    isDarkModeNotifier.value =
                        value; // Mengubah tema seluruh aplikasi
                  },
                  activeColor: Colors.black, // Warna bulatan saat aktif
                  activeTrackColor:
                      Colors.grey.shade400, // Warna jalur saat aktif
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
