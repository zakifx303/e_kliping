// Lokasi: lib/pages/search_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = ""; // Menyimpan kata yang sedang dicari

  // Fungsi untuk memanggil API pencarian
  Future<List<dynamic>> _cariKliping(String keyword) async {
    if (keyword.isEmpty) return []; // Jika kotak kosong, jangan cari apa-apa

    final response = await http.get(
      Uri.parse(
        "http://192.168.100.106/api_ekliping/cari_kliping.php?keyword=$keyword",
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal mencari data kliping");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- BAGIAN ATAS: KOTAK PENCARIAN (Berdasarkan Wireframe) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),

                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              // Fitur agar saat menekan 'Enter' di keyboard, langsung mencari
                              onSubmitted: (value) {
                                setState(() {
                                  _keyword = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Cari kliping...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 25,
                            color: Colors.grey.shade500,
                          ),

                          // Tombol Search diklik juga akan memulai pencarian
                          InkWell(
                            onTap: () {
                              setState(() {
                                _keyword = _searchController.text;
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(Icons.search, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // --- BAGIAN BAWAH: HASIL PENCARIAN ---
            Expanded(
              child: _keyword.isEmpty
                  ? const Center(
                      child: Text(
                        'Ketik judul atau isi berita untuk mencari',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : FutureBuilder<List<dynamic>>(
                      future: _cariKliping(_keyword),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Kliping tidak ditemukan',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        final listKliping = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: listKliping.length,
                          itemBuilder: (context, index) {
                            final item = listKliping[index];
                            final String? namaGambar = item['gambar'];
                            final String urlGambar =
                                (namaGambar != null && namaGambar.isNotEmpty)
                                ? "http://192.168.100.106/api_ekliping/uploads/$namaGambar"
                                : "";

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPage(data: item),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(8),
                                  leading: urlGambar.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            urlGambar,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                      ),
                                                    ),
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.article,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  title: Text(
                                    item['judul'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['kategori'] ?? '',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
