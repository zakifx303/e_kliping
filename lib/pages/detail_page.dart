// Lokasi: lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_kliping_page.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DetailPage({super.key, required this.data});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isLoading = false;

  Future<void> _hapusKliping() async {
    // [Logika Hapus Tetap Sama Seperti Sebelumnya]
    // Pastikan Anda menggunakan konfirmasi dialog dan HTTP request ke hapus_kliping.php
  }

  @override
  Widget build(BuildContext context) {
    // Format Tanggal
    String rawDate = widget.data['created_at'] ?? '';
    String displayDate = '';
    if (rawDate.isNotEmpty && rawDate.length >= 10) {
      List<String> parts = rawDate.substring(0, 10).split('-');
      if (parts.length == 3) {
        displayDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      } else {
        displayDate = rawDate.substring(0, 10);
      }
    }

    // Cek Gambar
    final String? namaGambar = widget.data['gambar'];
    final String urlGambar = (namaGambar != null && namaGambar.isNotEmpty)
        ? "http://192.168.100.106/api_ekliping/uploads/$namaGambar"
        : "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detail kliping',
          style: TextStyle(color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS 1: Kategori & Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.data['kategori'] ?? 'Lainnya',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // BARIS 2: Judul & Sentimen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.data['judul'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sentimen : ${widget.data['sentimen'] ?? 'Netral'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BARIS 3: Sumber & Pembuat
            Text(
              'Sumber berita : ${widget.data['sumber'] ?? '-'}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              // Jika nama_lengkap belum ditarik dari database, tampilkan nama default
              'diposting oleh : ${widget.data['nama_lengkap'] ?? 'Admin'}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // BARIS 4: Gambar Berita (Rasio 4:3 sesuai wireframe)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey.shade300,
                  width: double.infinity,
                  child: urlGambar.isNotEmpty
                      ? Image.network(urlGambar, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Gambar Berita',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '4:3',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // BARIS 5: Teks Deskripsi
            Text(
              widget.data['deskripsi'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // BOTTOM NAVIGATION: Tombol Edit & Hapus (Mengambang di bawah)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // TOMBOL EDIT (HIJAU)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF90EE90), // Hijau terang
                  foregroundColor: Colors.black,
                  side: const BorderSide(
                    color: Colors.green,
                    width: 2,
                  ), // Garis tepi tebal
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // Arahkan ke halaman edit dan tunggu kembalian data terbarunya
                  final updatedData = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditKlipingPage(dataAwal: widget.data),
                    ),
                  );

                  // Jika berhasil diedit (kembali membawa data), segarkan halaman detail ini
                  if (updatedData != null) {
                    Navigator.pop(
                      context,
                      true,
                    ); // Tutup detail, suruh Home refresh
                  }
                },
              ),
            ),
            const SizedBox(width: 16),

            // TOMBOL HAPUS (MERAH)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A80), // Merah terang
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'Hapus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _hapusKliping,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
