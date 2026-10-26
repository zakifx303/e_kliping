// Lokasi: lib/pages/edit_kliping_page.dart
import 'dart:convert';
import 'dart:ui';
import 'dart:io'; // Untuk File gambar
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Pastikan Anda sudah 'flutter pub add image_picker'

class EditKlipingPage extends StatefulWidget {
  final Map<String, dynamic> dataAwal;
  const EditKlipingPage({super.key, required this.dataAwal});

  @override
  State<EditKlipingPage> createState() => _EditKlipingPageState();
}

class _EditKlipingPageState extends State<EditKlipingPage> {
  late Map<String, dynamic> _dataSementara;
  File? _gambarBaru;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Salin data awal ke variabel sementara agar bisa diubah-ubah sebelum disimpan permanen
    _dataSementara = Map<String, dynamic>.from(widget.dataAwal);
  }

  // --- FUNGSI MUNCULKAN POP-UP (FROSTED GLASS) ---
  void _tampilkanDialogEdit(
    String fieldName,
    String title,
    bool isDropdown,
    List<String>? dropdownOptions,
    bool isTextArea,
  ) {
    TextEditingController controller = TextEditingController(
      text: _dataSementara[fieldName]?.toString() ?? '',
    );
    String dropdownValue =
        _dataSementara[fieldName]?.toString() ??
        (dropdownOptions != null ? dropdownOptions.first : '');

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4), // Latar belakang meredup
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ), // Efek Blur pada latar belakang
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // LOGIKA FORM: Teks biasa, Text Area, atau Dropdown
                      if (isDropdown && dropdownOptions != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: dropdownValue,
                              icon: const Icon(
                                Icons.arrow_drop_down_circle,
                                color: Colors.black,
                              ),
                              items: dropdownOptions.map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setDialogState(() {
                                  dropdownValue = newValue!;
                                });
                              },
                            ),
                          ),
                        )
                      else
                        TextField(
                          controller: controller,
                          maxLines: isTextArea
                              ? 6
                              : 1, // Jika deskripsi, buat kotak besar
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // TOMBOL SIMPAN & BATAL DI DALAM POP-UP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.edit_note),
                            label: const Text('Simpan'),
                            onPressed: () {
                              setState(() {
                                _dataSementara[fieldName] = isDropdown
                                    ? dropdownValue
                                    : controller.text;
                              });
                              Navigator.pop(context); // Tutup Pop-up
                            },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Batal'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FUNGSI AMBIL GAMBAR BARU ---
  Future<void> _pilihGambarBaru() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _gambarBaru = File(image.path);
      });
    }
  }

  // --- FUNGSI SIMPAN PERMANEN KE DATABASE ---
  Future<void> _simpanKeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    var uri = Uri.parse("http://192.168.100.106/api_ekliping/edit_kliping.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['id'] = _dataSementara['id'].toString();
    request.fields['judul'] = _dataSementara['judul'] ?? '';
    request.fields['deskripsi'] = _dataSementara['deskripsi'] ?? '';
    request.fields['kategori'] = _dataSementara['kategori'] ?? '';
    request.fields['sumber'] = _dataSementara['sumber'] ?? '';
    request.fields['sentimen'] = _dataSementara['sentimen'] ?? '';

    if (_gambarBaru != null) {
      var pic = await http.MultipartFile.fromPath("gambar", _gambarBaru!.path);
      request.files.add(pic);
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
            // Kembalikan data terbaru ke halaman Detail/Home
            Navigator.pop(context, data['data']);
          }
        }
      }
    } catch (e) {
      debugPrint("Error edit: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String urlGambarLama =
        (_dataSementara['gambar'] != null &&
            _dataSementara['gambar'].toString().isNotEmpty)
        ? "http://192.168.100.106/api_ekliping/uploads/${_dataSementara['gambar']}"
        : "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Edit kliping',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS 1: Kategori (Bisa diedit)
            Row(
              children: [
                InkWell(
                  onTap: () => _tampilkanDialogEdit(
                    'kategori',
                    'Ubah Kategori',
                    true,
                    ['Agama', 'Pendidikan', 'Umum', 'Haji', 'Lainnya'],
                    false,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _dataSementara['kategori'] ?? 'Lainnya',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // BARIS 2: Judul & Sentimen (Bisa diedit)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _tampilkanDialogEdit(
                      'judul',
                      'Ubah Judul Berita',
                      false,
                      null,
                      false,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dataSementara['judul'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _tampilkanDialogEdit(
                    'sentimen',
                    'Ubah Sentimen',
                    true,
                    ['Positif', 'Netral', 'Negatif'],
                    false,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Sentimen : ${_dataSementara['sentimen'] ?? 'Netral'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BARIS 3: Sumber (Bisa diedit)
            InkWell(
              onTap: () => _tampilkanDialogEdit(
                'sumber',
                'Ubah Sumber Berita',
                false,
                null,
                false,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sumber berita : ${_dataSementara['sumber'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit, size: 14),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // BARIS 4: Ganti Gambar
            InkWell(
              onTap: _pilihGambarBaru,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.grey.shade300,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_gambarBaru != null)
                          Image.file(_gambarBaru!, fit: BoxFit.cover)
                        else if (urlGambarLama.isNotEmpty)
                          Image.network(urlGambarLama, fit: BoxFit.cover),

                        // Lapisan abu-abu transparan agar teks terlihat
                        Container(color: Colors.white.withOpacity(0.5)),

                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 40,
                              color: Colors.black,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ganti Gambar Berita',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // BARIS 5: Teks Deskripsi (Bisa diedit)
            InkWell(
              onTap: () => _tampilkanDialogEdit(
                'deskripsi',
                'Ubah Deskripsi',
                false,
                null,
                true,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _dataSementara['deskripsi'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // TOMBOL SIMPAN UTAMA DI BAWAH
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF90EE90),
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.green, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(),
                      )
                    : const Text('Simpan Edit'),
                onPressed: _isLoading ? null : _simpanKeDatabase,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A80),
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.red, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.cancel),
                label: const Text('Batal'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
