import 'dart:convert';
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
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sumberController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  String? _selectedKategori;
  String? _selectedSentimen; // Variabel penampung sentimen
  File? _image;
  bool _isLoading = false;

  // Daftar Pilihan Dropdown
  final List<String> _kategoriList = [
    'Berita Agama',
    'Pendidikan',
    'Haji & Umrah',
    'Umum',
    'Prestasi',
    'lainnya',
  ];
  final List<String> _sentimenList = ['Positif', 'Netral', 'Negatif'];

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
      _selectedKategori = null;
      _selectedSentimen = null;
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

    var uri = Uri.parse("http://127.0.0.1/api_ekliping/simpan_kliping.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['judul'] = _judulController.text;
    request.fields['sumber'] = _sumberController.text;
    request.fields['kategori'] = _selectedKategori ?? 'Umum';
    request.fields['sentimen'] =
        _selectedSentimen ?? 'Netral'; // Pengiriman Data Sentimen
    request.fields['deskripsi'] = _deskripsiController.text;

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('gambar', _image!.path),
      );
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);

        if (data['status'] == 'sukses') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['pesan']),
                backgroundColor: Colors.green,
              ),
            );
            _batal(); // Kosongkan form setelah sukses
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              onChanged: (val) => setState(() => _selectedKategori = val),
            ),
            const SizedBox(height: 16),

            // Dropdown Sentimen (BARU)
            _buildDropdown(
              hint: 'Pilih sentimen',
              value: _selectedSentimen,
              items: _sentimenList,
              onChanged: (val) => setState(() => _selectedSentimen = val),
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
      value: value,
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
