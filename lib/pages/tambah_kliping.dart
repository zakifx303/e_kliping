import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class TambahKlipingPage extends StatefulWidget {
  const TambahKlipingPage({super.key});

  @override
  State<TambahKlipingPage> createState() => _TambahKlipingPageState();
}

class _TambahKlipingPageState extends State<TambahKlipingPage> {
  // Pengontrol untuk mengambil teks dari TextField
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sumberController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _kategoriTerpilih;
  File? _gambarKliping;
  bool _isLoading = false;

  // Fungsi untuk membuka galeri dan memilih gambar
  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _gambarKliping = File(pickedFile.path);
      });
    }
  }

  // Fungsi untuk mengirim data ke Database (PHP)
  Future<void> _simpanData() async {
    // Validasi form kosong
    if (_judulController.text.isEmpty ||
        _sumberController.text.isEmpty ||
        _kategoriTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, Sumber, dan Kategori harus diisi!'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // === GANTI 192.168.X.X DENGAN IP LAPTOP ANDA ===
    // Jika pakai Emulator Android Studio, ganti jadi: 10.0.2.2
    var uri = Uri.parse("http://192.168.100.1/api_ekliping/simpan_kliping.php");

    var request = http.MultipartRequest("POST", uri);
    request.fields['judul'] = _judulController.text;
    request.fields['sumber'] = _sumberController.text;
    request.fields['kategori'] = _kategoriTerpilih!;
    request.fields['deskripsi'] = _deskripsiController.text;

    // Jika ada gambar yang dipilih, masukkan ke paket pengiriman
    if (_gambarKliping != null) {
      var pic = await http.MultipartFile.fromPath(
        'gambar',
        _gambarKliping!.path,
      );
      request.files.add(pic);
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        // Jika berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil menyimpan kliping!'),
            backgroundColor: Colors.green,
          ),
        );
        // Bersihkan form setelah sukses
        _judulController.clear();
        _sumberController.clear();
        _deskripsiController.clear();
        setState(() {
          _kategoriTerpilih = null;
          _gambarKliping = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error jaringan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _judulController,
              decoration: const InputDecoration(
                hintText: 'Judul Berita',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _sumberController,
              decoration: const InputDecoration(
                hintText: 'Sumber berita',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori yang berfungsi
            DropdownButtonFormField<String>(
              value: _kategoriTerpilih,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text('Pilih kategori'),
              items: ['Haji & Umrah', 'Madrasah', 'Kerukunan Umat', 'Lainnya']
                  .map(
                    (kategori) => DropdownMenuItem(
                      value: kategori,
                      child: Text(kategori),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _kategoriTerpilih = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Deskripsi...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Upload file (opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Kotak Upload File
            GestureDetector(
              onTap: _pilihGambar, // Buka galeri saat diklik
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black45),
                ),
                child: Column(
                  children: [
                    Icon(
                      _gambarKliping == null
                          ? Icons.upload_file
                          : Icons.check_circle,
                      size: 32,
                      color: _gambarKliping == null
                          ? Colors.black
                          : Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _gambarKliping == null
                          ? 'Klik untuk pilih file'
                          : 'File dipilih!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Simpan & Batal
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _simpanData, // Matikan tombol saat loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(110, 45),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
                const SizedBox(width: 24),
                OutlinedButton(
                  onPressed: () {
                    // Logika batal (bersihkan form)
                    _judulController.clear();
                    _sumberController.clear();
                    _deskripsiController.clear();
                    setState(() {
                      _kategoriTerpilih = null;
                      _gambarKliping = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(110, 45),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
