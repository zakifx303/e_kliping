import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CariInternetPage extends StatefulWidget {
  const CariInternetPage({super.key});

  @override
  State<CariInternetPage> createState() => _CariInternetPageState();
}

// Tambahkan SingleTickerProviderStateMixin untuk animasi
class _CariInternetPageState extends State<CariInternetPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  List<dynamic> _searchResults = [];

  // Variabel Animasi "Breath"
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Konfigurasi animasi looping (durasi 1 detik bolak-balik)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cariBerita() async {
    String keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    // GANTI IP INI DENGAN IP LAPTOP ANDA (contoh: 192.168.18.56)
    String url =
        "http://192.168.100.106/api_ekliping/cari_rss_google.php?keyword=$keyword";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'sukses') {
          setState(() {
            _searchResults = data['data'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _simpanKeDatabase(Map<String, dynamic> berita) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyimpan berita ke Beranda...'),
        duration: Duration(seconds: 1),
      ),
    );

    const urlSimpan =
        'http://192.168.100.106/api_ekliping/simpan_berita_internet.php';

    try {
      final response = await http.post(
        Uri.parse(urlSimpan),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(berita),
      );
      print("ISI RESPONSE SERVER: ${response.body}"); // Tambahkan baris ini

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      final pesan = data['pesan']?.toString() ?? 'Tidak ada pesan dari server.';
      final berhasil = response.statusCode == 200 && data['status'] == 'sukses';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
          backgroundColor: berhasil ? Colors.green : Colors.red,
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Respons server tidak valid: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error jaringan: $e'),
          backgroundColor: Colors.red,
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
      ),
      body: Column(
        children: [
          // --- BAGIAN KOLOM PENCARIAN (Berdasarkan Gambar 2) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: "Cari Berita...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (value) => _cariBerita(),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _cariBerita,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BAGIAN KONTEN DINAMIS ---
          Expanded(child: _buildKonten()),
        ],
      ),
    );
  }

  Widget _buildKonten() {
    // Keadaan 1: Belum mencari
    if (!_hasSearched) {
      return const Center(
        child: Text(
          "Cari berita lewat Internet\nkemudian tambahkan ke Beranda",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    // Keadaan 2: Sedang Loading (Animasi Breath In/Out berdasarkan Gambar 3)
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: const Icon(
                Icons.travel_explore,
                size: 80,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sedang mencari\nTunggu sebentar ya...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Keadaan 3: Hasil Ditemukan (Berdasarkan Gambar 4)
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "Menemukan ${_searchResults.length} Berita\nSilahkan Dipilih untuk disimpan ke beranda",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              final berita = _searchResults[index];
              return _buildKartuHasil(berita);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKartuHasil(Map<String, dynamic> berita) {
    final tanggal = berita['tanggal']?.toString() ?? '';
    final parsedTanggal = DateTime.tryParse(tanggal);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 120, // Memaksa tinggi kartu
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Garis aksen biru di sebelah kiri
          Container(
            width: 8,
            decoration: const BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Kotak putih placeholder gambar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),

          // Teks Judul dan Deskripsi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Text(
                      berita['deskripsi'] ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        parsedTanggal == null
                            ? tanggal
                            : DateFormat('dd/MM/yyyy').format(parsedTanggal),
                        style: const TextStyle(fontSize: 9),
                      ),
                      const Text("Kategori : -", style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 5), // Spacer
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tombol Plus (+) kotak hitam
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: InkWell(
              onTap: () {
                _simpanKeDatabase(berita);
              },
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
