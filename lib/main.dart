// Lokasi: lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';

// SAKELAR GLOBAL: Menyimpan status mode gelap (default: false / terang)
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder akan mendengarkan perubahan pada isDarkModeNotifier
    // Jika sakelar ditekan, ia akan merender ulang seluruh tema aplikasi
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'E-Kliping Humas',
          debugShowCheckedModeBanner: false,
          themeMode: isDark
              ? ThemeMode.dark
              : ThemeMode.light, // Menentukan mode saat ini
          // Tema Terang
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor:
                  Colors.black, // Mengatur warna teks & ikon AppBar jadi hitam
              surfaceTintColor: Colors.white,
            ),
          ),
          // Tema Gelap
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(
              0xFF121212,
            ), // Warna abu-abu sangat gelap
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor:
                  Colors.white, // Mengatur warna teks & ikon AppBar jadi putih
              surfaceTintColor: Color(0xFF121212),
            ),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
