// Lokasi: lib/pages/home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tambah_kliping.dart';
import 'analitik_page.dart';
import 'search_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan dipanggil berdasarkan tab
  final List<Widget> _pages = [
    const HomeContent(), // Sekarang HomeContent akan menampilkan data dari database
    const TambahKlipingPage(),
    const AnalitikPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildDynamicAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade400, width: 1.0),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 32,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Tambah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              activeIcon: Icon(Icons.leaderboard),
              label: 'Analitik',
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi AppBar yang menyesuaikan dengan halaman yang aktif
  PreferredSizeWidget _buildDynamicAppBar() {
    if (_selectedIndex == 1) {
      return AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Tambah kliping', style: TextStyle(fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade400, height: 1.0),
        ),
      );
    } else if (_selectedIndex == 2) {
      return AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Analistik', style: TextStyle(fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade400, height: 1.0),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Eclips',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: Colors.grey.shade400, height: 1.0),
      ),
    );
  }
}

// ==========================================
// Widget Tampilan Beranda yang Mengambil Data
// ==========================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Fungsi untuk memanggil API ambil_kliping.php
  Future<List<dynamic>> _fetchKliping() async {
    // Karena Anda mengetes di Windows Desktop, gunakan 127.0.0.1
    final response = await http.get(
      Uri.parse("http://127.0.0.1/api_ekliping/ambil_kliping.php"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(
        response.body,
      ); // Menerjemahkan JSON ke bentuk list Dart
    } else {
      throw Exception("Gagal memuat data kliping");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Memuat ulang (merefresh) tampilan
      },
      child: FutureBuilder<List<dynamic>>(
        future: _fetchKliping(),
        builder: (context, snapshot) {
          // 1. Kondisi saat sedang memuat data (Loading)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Kondisi jika terjadi error jaringan / URL salah
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // 3. Kondisi jika database masih kosong (Kembali tampilkan wajah sedih)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_dissatisfied_outlined, size: 100),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada kliping, tambahkan sekarang!',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. Jika data tersedia, tampilkan dalam bentuk ListView Card
          final listKliping = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: listKliping.length,
            itemBuilder: (context, index) {
              final item = listKliping[index];
              final String? namaGambar = item['gambar'];

              // Membuat URL gambar untuk dipanggil dari folder uploads
              final String urlGambar =
                  (namaGambar != null && namaGambar.isNotEmpty)
                  ? "http://127.0.0.1/api_ekliping/uploads/$namaGambar"
                  : "";

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Menampilkan gambar berita (jika ada) ---
                      if (urlGambar.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            urlGambar,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            // Jika gambar gagal dimuat (misal terhapus manual dari folder uploads)
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (urlGambar.isNotEmpty) const SizedBox(height: 12),

                      // --- Menampilkan Kategori & Sumber ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['kategori'] ?? 'Umum',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            item['sumber'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // --- Menampilkan Judul Berita ---
                      Text(
                        item['judul'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // --- Menampilkan Deskripsi Berita ---
                      if (item['deskripsi'] != null &&
                          item['deskripsi'].toString().isNotEmpty)
                        Text(
                          item['deskripsi'],
                          maxLines: 3, // Maksimal 3 baris
                          overflow: TextOverflow
                              .ellipsis, // Jika panjang akan diberi titik-titik (...)
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
