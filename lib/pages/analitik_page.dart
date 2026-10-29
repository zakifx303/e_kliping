// Lokasi: lib/pages/analitik_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalitikPage extends StatefulWidget {
  const AnalitikPage({super.key});

  @override
  State<AnalitikPage> createState() => _AnalitikPageState();
}

class _AnalitikPageState extends State<AnalitikPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Data default sebelum fetch
  Map<String, int> _distribusi = {'positif': 0, 'netral': 0, 'negatif': 0};
  List<dynamic> _tren = [];

  final String baseUrl = "http://192.168.100.106"; // Ganti dengan IP Anda

  @override
  void initState() {
    super.initState();
    // Secara default, ambil data sebulan terakhir
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _fetchAnalitik();
  }

  Future<void> _pilihTanggal(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _fetchAnalitik() async {
    setState(() {
      _isLoading = true;
    });

    String url = "$baseUrl/api_ekliping/analitik.php";
    if (_startDate != null && _endDate != null) {
      String start = DateFormat('yyyy-MM-dd').format(_startDate!);
      String end = DateFormat('yyyy-MM-dd').format(_endDate!);
      url += "?start_date=$start&end_date=$end";
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'sukses') {
          setState(() {
            _distribusi = Map<String, int>.from(data['distribusi']);
            _tren = data['tren'];
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(
        title: const Text('Analitik', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kontrol Tanggal (Sesuai Referensi image_f4cd00.png)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  _startDate == null
                      ? 'Dari tanggal'
                      : DateFormat('dd/MM/yyyy').format(_startDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pilihTanggal(context, true),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(
                  _endDate == null
                      ? 'Sampai tanggal'
                      : DateFormat('dd/MM/yyyy').format(_endDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pilihTanggal(context, false),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _fetchAnalitik,
                child: const Text('Terapkan'),
              ),
            ),
            const SizedBox(height: 30),

            // Indikator Loading
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Grafik Tren Sentimen (Line Chart)
              const Text(
                'Tren Sentimen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(height: 250, child: LineChart(_buildLineChartData())),
              const SizedBox(height: 40),

              // Grafik Distribusi per Kategori (Bar Chart)
              const Text(
                'Distribusi per Kategori',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(height: 200, child: BarChart(_buildBarChartData())),
            ],
          ],
        ),
      ),
    );
  }

  // --- Konfigurasi Line Chart (Tren Sentimen) ---
  LineChartData _buildLineChartData() {
    List<FlSpot> positifSpots = [];
    List<FlSpot> netralSpots = [];
    List<FlSpot> negatifSpots = [];

    for (int i = 0; i < _tren.length; i++) {
      positifSpots.add(FlSpot(i.toDouble(), _tren[i]['positif'].toDouble()));
      netralSpots.add(FlSpot(i.toDouble(), _tren[i]['netral'].toDouble()));
      negatifSpots.add(FlSpot(i.toDouble(), _tren[i]['negatif'].toDouble()));
    }

    return LineChartData(
      minY: 0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          axisNameWidget: const Text(
            'Rentang Waktu',
            style: TextStyle(fontSize: 12),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < _tren.length) {
                // Tampilkan label tanggal (misal: '15/10')
                String rawDate = _tren[value.toInt()]['tanggal'];
                DateTime date = DateTime.parse(rawDate);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Jumlah Berita',
            style: TextStyle(fontSize: 12),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value % 1 == 0)
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Colors.black),
          left: BorderSide(color: Colors.black),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: positifSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: netralSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: Colors.amber,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: negatifSpots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ],
    );
  }

  // --- Konfigurasi Bar Chart (Distribusi per Kategori) ---
  BarChartData _buildBarChartData() {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return const Text('Positif', style: TextStyle(fontSize: 12));
                case 1:
                  return const Text('Netral', style: TextStyle(fontSize: 12));
                case 2:
                  return const Text('Negatif', style: TextStyle(fontSize: 12));
                default:
                  return const Text('');
              }
            },
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: const Text(
            'Jumlah Berita',
            style: TextStyle(fontSize: 12),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value % 1 == 0)
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              return const Text('');
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: Colors.black),
          left: BorderSide(color: Colors.black),
        ),
      ),
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: _distribusi['positif']!.toDouble(),
              color: Colors.green,
              width: 25,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: _distribusi['netral']!.toDouble(),
              color: Colors.amber,
              width: 25,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: _distribusi['negatif']!.toDouble(),
              color: Colors.red,
              width: 25,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      ],
    );
  }
}
