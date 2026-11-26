import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../session.dart';
import 'dart:async';

class TambahKlipingPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const TambahKlipingPage({super.key, this.onSaved});

  @override
  State<TambahKlipingPage> createState() => _TambahKlipingPageState();
}

class _TambahKlipingPageState extends State<TambahKlipingPage> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sumberController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String _selectedKategori = 'Otomatis';
  String _selectedSentimen = 'Otomatis';
  File? _image;
  bool _isLoading = false;

  // Daftar Pilihan Dropdown
  final List<String> _kategoriList = [
    'Otomatis',
    'Berita Agama',
    'Pendidikan',
    'Umum',
    'Prestasi',
  ];
  final List<String> _sentimenList = [
    'Otomatis',
    'Positif',
    'Netral',
    'Negatif',
  ];

  // Fungsi Pemilih Gambar
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Fungsi Mengosongkan Form (Tombol Batal)
  void _batal() {
    setState(() {
      _judulController.clear();
      _sumberController.clear();
      _deskripsiController.clear();
      _selectedKategori = 'Otomatis';
      _selectedSentimen = 'Otomatis';
      _image = null;
    });
  }

  // Fungsi Menyimpan Data ke Database
  Future<void> _simpanData() async {
    if (_judulController.text.isEmpty || _sumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan Sumber berita wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    var uri = Uri.parse(
      "http://192.168.100.106/api_ekliping/simpan_kliping.php",
    );
    var request = http.MultipartRequest("POST", uri);

    request.fields['username'] = UserSession.currentUsername;
    request.fields['judul'] = _judulController.text;
    request.fields['sumber'] = _sumberController.text;
    request.fields['kategori'] = _selectedKategori;
    request.fields['sentimen'] = _selectedSentimen;
    request.fields['deskripsi'] = _deskripsiController.text;

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('gambar', _image!.path),
      );
    }

    try {
      // Tunggu maksimal 20 detik. Kalau server tidak menjawab, dianggap gagal.
      var response = await request.send().timeout(const Duration(seconds: 20));
      final responseString = await response.stream.bytesToString();
      debugPrint("RESPON MENTAH DARI PHP: $responseString");

      // Kasus 1: server membalas dengan kode error (404, 500, dll.)
      if (response.statusCode != 200) {
        _tampilkanPesan(
          'Server bermasalah (kode ${response.statusCode}). Coba lagi nanti.',
        );
        return;
      }

      final hasil = jsonDecode(responseString);

      if (hasil['status'] == 'sukses') {
        // Berhasil
        _tampilkanPesan(
          "Tersimpan! Kategori: ${hasil['kategori_terdeteksi'] ?? '-'}, "
          "Sentimen: ${hasil['sentimen_terdeteksi'] ?? '-'}",
          sukses: true,
        );
        if (!mounted) return;
        final onSaved = widget.onSaved;
        if (onSaved != null) {
          onSaved();
        } else {
          _batal();
        }
      } else {
        // Kasus 2: PHP membalas "error". Detail teknis hanya dicatat di konsol.
        debugPrint("PHP MELAPORKAN ERROR: ${hasil['pesan']}");
        _tampilkanPesan('Gagal menyimpan kliping. Silakan coba lagi.');
      }
    } on TimeoutException {
      // Kasus 3: server terlalu lama menjawab
      _tampilkanPesan('Server tidak merespons. Periksa koneksi lalu coba lagi.');
    } on FormatException {
      // Balasan server bukan JSON yang benar
      _tampilkanPesan('Balasan server tidak dapat dibaca. Hubungi pengelola app.');
    } catch (e) {
      // Kasus lain, biasanya server mati atau tidak ada koneksi
      debugPrint("ERROR SIMPAN: $e");
      _tampilkanPesan(
        'Tidak dapat terhubung ke server. Periksa Wi-Fi dan pastikan server menyala.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi bantu: menampilkan pesan di bagian bawah layar
  void _tampilkanPesan(String pesan, {bool sukses = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: sukses ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Judul
            _buildTextField(controller: _judulController, hint: 'Judul Berita'),
            const SizedBox(height: 16),

            // Input Sumber
            _buildTextField(
              controller: _sumberController,
              hint: 'Sumber berita',
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori
            _buildDropdown(
              hint: 'Pilih kategori',
              value: _selectedKategori,
              items: _kategoriList,
              onChanged: (val) => setState(() => _selectedKategori = val ?? 'Otomatis'),
            ),
            const SizedBox(height: 16),

            // Dropdown Sentimen (BARU)
            _buildDropdown(
              hint: 'Pilih sentimen',
              value: _selectedSentimen,
              items: _sentimenList,
              onChanged: (val) =>
                  setState(() => _selectedSentimen = val ?? 'Otomatis'),
            ),
            const SizedBox(height: 16),

            // Text Area Deskripsi
            _buildTextField(
              controller: _deskripsiController,
              hint: 'Deskripsi...',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Kotak Upload File
            const Text(
              'Upload file (opsional)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file, size: 32),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: const BorderSide(color: Colors.black87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _image == null ? 'Pilih file' : 'File Terpilih!',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Tombol Simpan & Batal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionBtn('Simpan', _isLoading ? null : _simpanData),
                _buildActionBtn('Batal', _batal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Kustom untuk meniru gaya Wireframe ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
      hint: Text(hint, style: const TextStyle(color: Colors.grey)),
      initialValue: value,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildActionBtn(String text, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        side: const BorderSide(color: Colors.black87, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
