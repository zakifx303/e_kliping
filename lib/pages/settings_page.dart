// Lokasi: lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../session.dart';
import 'tambah_user_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  // Fungsi untuk mengecek hak akses Admin
  void _cekAdminDanArahkan() {
    if (UserSession.currentUsername == 'admin') {
      // Jika admin, izinkan masuk ke halaman Tambah User
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TambahUserPage()),
      );
    } else {
      // Jika bukan admin, munculkan pop-up penolakan
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Akses Ditolak'),
            ],
          ),
          content: const Text('Maaf, anda bukan admin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'SETTINGS',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Opsi 1: Mode Gelap (Desain sesuai Wireframe)
            Row(
              children: [
                const Icon(Icons.brightness_6, color: Colors.amber, size: 32),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'MODE GELAP',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (val) {
                    setState(() {
                      _isDarkMode = val;
                    });
                  },
                  activeColor: Colors.black,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Opsi 2: Tambah User
            InkWell(
              onTap: _cekAdminDanArahkan,
              child: const Row(
                children: [
                  Icon(Icons.person_add, size: 36, color: Colors.black),
                  SizedBox(width: 16),
                  Text('Tambah User', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
