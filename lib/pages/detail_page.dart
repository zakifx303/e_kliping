// Lokasi: lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit_kliping_page.dart';
import '../session.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const DetailPage({super.key, required this.data});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Future<void> _hapusKliping() async {
    final id = widget.data['id']?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID kliping tidak ditemukan.')),
      );
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus kliping?'),
        content: const Text('Kliping ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loadingShown = true;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.106/api_ekliping/hapus_kliping.php'),
        body: {'id': id},
      );
      if (response.statusCode != 200) {
        throw StateError('Server mengembalikan HTTP ${response.statusCode}.');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if (result['status'] != 'sukses') {
        throw StateError(
          result['pesan']?.toString() ?? 'Server gagal menghapus kliping.',
        );
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingShown = false;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus kliping: $e')));
      }
    } finally {
      if (loadingShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
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
      bottomNavigationBar: UserSession.currentUsername == 'guest'
          ? const SizedBox.shrink()
          : Container(
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
                        backgroundColor: const Color(0xFF90EE90),
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.green, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final updatedData = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditKlipingPage(dataAwal: widget.data),
                          ),
                        );

                        if (updatedData != null && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // TOMBOL HAPUS (MERAH)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A80),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _hapusKliping,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
