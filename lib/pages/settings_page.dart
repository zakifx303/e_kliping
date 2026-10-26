// Lokasi: lib/pages/settings_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../session.dart';
import 'tambah_user_page.dart';
import 'login_page.dart'; // Wajib diimpor agar bisa pindah ke halaman login
import 'ubah_password_page.dart'; // Wajib diimpor agar bisa pindah ke halaman ubah password

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;

  // Fungsi Cek Admin
  void _cekAdminDanArahkan() {
    if (UserSession.currentUsername == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TambahUserPage()),
      );
    } else {
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

  // Fungsi Pop-up Logout
  void _tampilkanDialogLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ), // Efek blur layar belakang
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.grey.shade200,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Yakin Ingin Logout?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol "Yakin dong" (Hijau)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B14F), // Hijau
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          // 1. Hapus data sesi pengguna
                          UserSession.currentUsername = '';

                          // 2. Lempar kembali ke halaman Login dan hapus semua riwayat halaman
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Yakin dong',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      // Tombol "Ga dulu deh" (Merah Gelap/Cokelat)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFB73E11,
                          ), // Merah bata/cokelat
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog
                        },
                        child: const Text(
                          'Ga dulu deh',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // 1. Mode Gelap
            Row(
              children: [
                const Icon(Icons.brightness_6, color: Colors.amber, size: 36),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'MODE GELAP',
                    style: TextStyle(
                      fontSize: 18,
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

            // 2. Tambah User
            InkWell(
              onTap: _cekAdminDanArahkan,
              child: const Row(
                children: [
                  Icon(Icons.person_add, size: 36, color: Colors.black),
                  SizedBox(width: 16),
                  Text('Tambah User', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Ubah Password
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UbahPasswordPage(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 36, color: Colors.black),
                  SizedBox(width: 16),
                  Text('Ubah Password', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Logout
            InkWell(
              onTap: _tampilkanDialogLogout,
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 36, color: Colors.black),
                  SizedBox(width: 16),
                  Text('Logout', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
