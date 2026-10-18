// Lokasi: lib/pages/analitik_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnalitikPage extends StatefulWidget {
  const AnalitikPage({super.key});

  @override
  State<AnalitikPage> createState() => _AnalitikPageState();
}

class _AnalitikPageState extends State<AnalitikPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  String _startDateQuery = "";
  String _endDateQuery = "";
  bool _isFiltered = false;

  // Fungsi untuk memunculkan Kalender dan memilih tanggal
  Future<void> _pilihTanggal(
    BuildContext context,
    TextEditingController controller,
    bool isStart,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // Batas tahun paling lama
      lastDate: DateTime.now(), // Batas tahun paling baru (hari ini)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black87, // Warna header kalender
              onPrimary: Colors.white, // Warna teks header kalender
              onSurface: Colors.black, // Warna angka kalender
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Format tanggal ke YYYY-MM-DD (Sesuai standar MySQL)
        String formattedDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        controller.text = formattedDate;

        if (isStart) {
          _startDateQuery = formattedDate;
        } else {
          _endDateQuery = formattedDate;
        }
      });
    }
  }

  // Fungsi untuk memanggil API Filter
  Future<List<dynamic>> _fetchFilteredData() async {
    final response = await http.get(
      Uri.parse(
        "http://127.0.0.1/api_ekliping/filter_kliping.php?start=$_startDateQuery&end=$_endDateQuery",
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memfilter data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- BAGIAN ATAS: FORM FILTER TANGGAL ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Input: Dari Tanggal
                TextField(
                  controller: _startController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Dari tanggal (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: Icon(
                      Icons.edit_calendar,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () => _pilihTanggal(context, _startController, true),
                ),
                const SizedBox(height: 16),

                // Input: Sampai Tanggal
                TextField(
                  controller: _endController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Sampai tanggal (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    suffixIcon: Icon(
                      Icons.edit_calendar,
                      color: Colors.black87,
                    ),
                  ),
                  onTap: () => _pilihTanggal(context, _endController, false),
                ),
                const SizedBox(height: 16),

                // Tombol Terapkan
                OutlinedButton(
                  onPressed: () {
                    if (_startDateQuery.isNotEmpty &&
                        _endDateQuery.isNotEmpty) {
                      setState(() {
                        _isFiltered =
                            true; // Picu FutureBuilder untuk merender hasil
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pilih "Dari" dan "Sampai" tanggal terlebih dahulu!',
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(100, 40),
                  ),
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ),

          const Divider(thickness: 1, color: Colors.black12),

          // --- BAGIAN BAWAH: HASIL FILTER ---
          Expanded(
            child: !_isFiltered
                ? const Center(
                    child: Text(
                      'Pilih rentang tanggal untuk melihat analitik',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : FutureBuilder<List<dynamic>>(
                    future: _fetchFilteredData(),
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
                                Icons.event_busy,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada kliping pada tanggal tersebut',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      final listKliping = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: listKliping.length,
                        itemBuilder: (context, index) {
                          final item = listKliping[index];

                          // Format tampilan tanggal jam
                          final String rawDate = item['created_at'] ?? '';
                          final String displayDate = rawDate.isNotEmpty
                              ? rawDate.substring(0, 10)
                              : '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              title: Text(
                                item['judul'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Kategori: ${item['kategori']} \nDiunggah: $displayDate",
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
