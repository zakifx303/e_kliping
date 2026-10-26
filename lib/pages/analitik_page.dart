// Lokasi: lib/pages/analitik_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalitikPage extends StatefulWidget {
  const AnalitikPage({super.key});

  @override
  State<AnalitikPage> createState() => _AnalitikPageState();
}

class _AnalitikPageState extends State<AnalitikPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  Map<String, dynamic>? _dataAnalitik;

  @override
  void initState() {
    super.initState();
    _fetchAnalitik(); // Ambil data semua tanggal saat pertama kali dibuka
  }

  Future<void> _fetchAnalitik() async {
    setState(() {
      _isLoading = true;
    });

    String url = "http://127.0.0.1/api_ekliping/api_analitik.php";
    if (_startDate != null && _endDate != null) {
      String dari = DateFormat('yyyy-MM-dd').format(_startDate!);
      String sampai = DateFormat('yyyy-MM-dd').format(_endDate!);
      url += "?dari=$dari&sampai=$sampai";
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _dataAnalitik = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching analitik: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pilihTanggal(bool isStart) async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengekstrak data bar
    final barData =
        _dataAnalitik?['bar'] ?? {'Positif': 0, 'Netral': 0, 'Negatif': 0};
    double valPositif = (barData['Positif'] ?? 0).toDouble();
    double valNetral = (barData['Netral'] ?? 0).toDouble();
    double valNegatif = (barData['Negatif'] ?? 0).toDouble();
    bool isBarEmpty = valPositif == 0 && valNetral == 0 && valNegatif == 0;

    // Mengekstrak data garis (line)
    final List lineData = _dataAnalitik?['line'] ?? [];
    bool isLineEmpty = lineData.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FORM RENTANG TANGGAL ---
          _buildDateField("Dari tanggal", _startDate, true),
          const SizedBox(height: 16),
          _buildDateField("Sampai tanggal", _endDate, false),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _fetchAnalitik,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.black),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Terapkan"),
            ),
          ),
          const SizedBox(height: 32),

          // --- GRAFIK TREN SENTIMEN ---
          isLineEmpty
              ? _buildEmptyChartWrapper("Tren Sentimen", "Rentang Waktu")
              : _buildLineChart(lineData),

          const SizedBox(height: 40),

          // --- GRAFIK DISTRIBUSI KATEGORI ---
          isBarEmpty
              ? _buildEmptyChartWrapper(
                  "Distribusi per Kategori",
                  "Positif      Netral      Negatif",
                )
              : _buildBarChart(valPositif, valNetral, valNegatif),

          const SizedBox(height: 40), // Jarak aman bawah
        ],
      ),
    );
  }

  // Widget Input Tanggal
  Widget _buildDateField(String hint, DateTime? dateValue, bool isStart) {
    return InkWell(
      onTap: () => _pilihTanggal(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateValue != null
                  ? DateFormat('dd/MM/yyyy').format(dateValue)
                  : hint,
              style: TextStyle(
                fontSize: 16,
                color: dateValue != null ? Colors.black : Colors.grey.shade600,
              ),
            ),
            const Icon(Icons.calendar_month, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // Widget Bingkai Grafik Kosong (Sesuai Wireframe)
  Widget _buildEmptyChartWrapper(String title, String xLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const RotatedBox(
              quarterTurns: 3,
              child: Text("Jumlah Berita", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black),
                    bottom: BorderSide(color: Colors.black),
                  ),
                ),
                child: const Center(
                  child: Text("Belum ada data", style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30, top: 8),
          child: Center(
            child: Text(xLabel, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // Widget Grafik Batang (Fl_Chart)
  Widget _buildBarChart(double pos, double net, double neg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Distribusi per Kategori",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const RotatedBox(
              quarterTurns: 3,
              child: Text("Jumlah Berita", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        (pos > net
                            ? (pos > neg ? pos : neg)
                            : (net > neg ? net : neg)) +
                        2, // Dinamis
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Text(
                                  'Positif',
                                  style: TextStyle(fontSize: 12),
                                );
                              case 1:
                                return const Text(
                                  'Netral',
                                  style: TextStyle(fontSize: 12),
                                );
                              case 2:
                                return const Text(
                                  'Negatif',
                                  style: TextStyle(fontSize: 12),
                                );
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black),
                        bottom: BorderSide(color: Colors.black),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: pos,
                            color: Colors.green,
                            width: 30,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: net,
                            color: Colors.yellow,
                            width: 30,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: neg,
                            color: Colors.red,
                            width: 30,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget Grafik Garis (Fl_Chart)
  Widget _buildLineChart(List lineData) {
    List<FlSpot> posSpots = [];
    List<FlSpot> netSpots = [];
    List<FlSpot> negSpots = [];

    for (int i = 0; i < lineData.length; i++) {
      double pos = (lineData[i]['Positif'] ?? 0).toDouble();
      double net = (lineData[i]['Netral'] ?? 0).toDouble();
      double neg = (lineData[i]['Negatif'] ?? 0).toDouble();
      posSpots.add(FlSpot(i.toDouble(), pos));
      netSpots.add(FlSpot(i.toDouble(), net));
      negSpots.add(FlSpot(i.toDouble(), neg));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tren Sentimen",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const RotatedBox(
              quarterTurns: 3,
              child: Text("Jumlah Berita", style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineTouchData: const LineTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      show: false,
                    ), // Sembunyikan label bawaan untuk meniru wireframe
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.black),
                        bottom: BorderSide(color: Colors.black),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: posSpots,
                        isCurved: false,
                        color: Colors.green,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: netSpots,
                        isCurved: false,
                        color: Colors.yellow,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: negSpots,
                        isCurved: false,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 30, top: 8),
          child: Center(
            child: Text("Rentang Waktu", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
