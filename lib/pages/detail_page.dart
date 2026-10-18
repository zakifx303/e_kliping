// Lokasi: lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DetailPage extends StatelessWidget {
  // Menangkap seluruh data JSON (item) dari halaman Home
  final dynamic data;

  const DetailPage({super.key, required this.data});

  // Fungsi untuk mengirim perintah hapus ke API
  Future<void> _hapusKliping(BuildContext context, String id) async {
    // Tampilkan dialog konfirmasi sebelum menghapus
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Kliping?'),
            content: const Text('Tindakan ini tidak dapat dibatalkan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Batal
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Yakin
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // Jika pengguna memilih "Hapus", jalankan API
      var uri = Uri.parse("http://127.0.0.1/api_ekliping/hapus_kliping.php");
      var request = http.MultipartRequest("POST", uri);
      request.fields['id'] = id.toString(); // Kirim ID yang akan dihapus

      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          // Jika sukses, tutup halaman Detail dan kembali ke Home
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kliping dihapus!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(
              context,
              true,
            ); // Kirim sinyal 'true' ke Home untuk Refresh
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Merakit URL Gambar
    final String? namaGambar = data['gambar'];
    final String urlGambar = (namaGambar != null && namaGambar.isNotEmpty)
        ? "http://127.0.0.1/api_ekliping/uploads/$namaGambar"
        : "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detail Kliping',
          style: TextStyle(color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade400, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori dan Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    data['kategori'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  data['created_at']?.toString().substring(0, 10) ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Judul
            Text(
              data['judul'] ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Sumber
            Row(
              children: [
                const Icon(Icons.language, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  data['sumber'] ?? '',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Gambar Full
            if (urlGambar.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  urlGambar,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Isi Deskripsi
            Text(
              data['deskripsi'] ?? 'Tidak ada deskripsi',
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),

      // Tombol Hapus Mengambang di Bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _hapusKliping(context, data['id'].toString()),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Kliping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.red.shade200),
            ),
          ),
        ),
      ),
    );
  }
}
