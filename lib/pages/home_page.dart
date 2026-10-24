// Lokasi: lib/pages/home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tambah_kliping.dart';
import 'analitik_page.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
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
          backgroundColor: Colors.white,
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
              icon: Icon(Icons.home_outlined, color: Colors.black),
              activeIcon: Icon(Icons.home, color: Colors.black),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, color: Colors.black),
              activeIcon: Icon(Icons.add_circle, color: Colors.black),
              label: 'Tambah',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined, color: Colors.black),
              activeIcon: Icon(Icons.leaderboard, color: Colors.black),
              label: 'Analitik',
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDynamicAppBar() {
    if (_selectedIndex == 1) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Tambah kliping',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      );
    } else if (_selectedIndex == 2) {
      return AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Analitik',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      title: const Text(
        'Eclips',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 28, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            size: 28,
            color: Colors.black,
          ),
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
        child: Container(color: Colors.grey.shade300, height: 1.0),
      ),
    );
  }
}

// ==========================================
// Widget Tampilan Beranda (Menampilkan List Card Sesuai Wireframe)
// ==========================================
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Future<List<dynamic>> _fetchKliping() async {
    final response = await http.get(
      Uri.parse("http://127.0.0.1/api_ekliping/ambil_kliping.php"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat data kliping");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<List<dynamic>>(
          future: _fetchKliping(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied_outlined,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada kliping, tambahkan sekarang!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final listKliping = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listKliping.length,
              itemBuilder: (context, index) {
                final item = listKliping[index];

                // 1. Ambil nama gambar
                final String? namaGambar = item['gambar'];
                final String urlGambar =
                    (namaGambar != null && namaGambar.isNotEmpty)
                    ? "http://127.0.0.1/api_ekliping/uploads/$namaGambar"
                    : "";

                // 2. Tentukan Warna Pita berdasarkan Sentimen
                final String sentimen = item['sentimen'] ?? 'Netral';
                Color pitaWarna = Colors.amber; // Default Netral
                if (sentimen.toLowerCase() == 'positif') {
                  pitaWarna = const Color(0xFF00B14F); // Hijau
                } else if (sentimen.toLowerCase() == 'negatif') {
                  pitaWarna = const Color(0xFFD32F2F); // Merah
                }

                // 3. Format Tanggal (Dari YYYY-MM-DD HH:MM:SS menjadi DD/MM/YYYY)
                String rawDate = item['created_at'] ?? '';
                String displayDate = '';
                if (rawDate.isNotEmpty && rawDate.length >= 10) {
                  List<String> parts = rawDate.substring(0, 10).split('-');
                  if (parts.length == 3) {
                    displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';
                  } else {
                    displayDate = rawDate.substring(0, 10);
                  }
                }

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(data: item),
                      ),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors
                          .grey
                          .shade300, // Warna abu-abu latar belakang kartu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: IntrinsicHeight(
                        // Menyamakan tinggi baris pita warna dengan isi konten
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- PITA WARNA SENTIMEN ---
                            Container(
                              width: 14, // Ketebalan pita warna
                              color: pitaWarna,
                            ),

                            // --- ISI KONTEN KARTU ---
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bagian Atas: Gambar, Judul, Deskripsi
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Kotak Gambar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors
                                                .white, // Latar putih untuk placeholder gambar
                                            child: urlGambar.isNotEmpty
                                                ? Image.network(
                                                    urlGambar,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.image_outlined,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Judul dan Deskripsi
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['judul'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item['deskripsi'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87
                                                      .withOpacity(0.7),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Bagian Bawah: Tanggal & Kategori
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          displayDate,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Kategori : ${item['kategori'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
