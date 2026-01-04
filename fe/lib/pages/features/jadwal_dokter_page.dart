import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class JadwalDokterPage extends StatefulWidget {
  const JadwalDokterPage({super.key});

  @override
  State<JadwalDokterPage> createState() => _JadwalDokterPageState();
}

class _JadwalDokterPageState extends State<JadwalDokterPage> {
  List<Map<String, dynamic>> dokterList = [];
  Map<String, dynamic>? jadwalData;
  int? selectedDokter;
  DateTimeRange? _range;
  bool loadingDokter = true;
  bool loadingJadwal = false;

  @override
  void initState() {
    super.initState();
    _loadDokter();
  }

  Future<void> _loadDokter() async {
    try {
      final data = await ApiService.getDokter();
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        dokterList = parsed;
        selectedDokter = parsed.isNotEmpty
          ? (parsed.first['id_dokter'] as num?)?.toInt()
          : null;
        loadingDokter = false;
      });
      if (selectedDokter != null) {
        await _fetchJadwal();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingDokter = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat dokter: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _chooseRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 30)),
      initialDateRange: _range ?? DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
    );
    if (result != null) {
      setState(() => _range = result);
      await _fetchJadwal();
    }
  }

  Future<void> _fetchJadwal() async {
    if (selectedDokter == null) return;
    setState(() => loadingJadwal = true);
    try {
      final res = await ApiService.getJadwalDokter(
        selectedDokter!,
        tanggalMulai: _range != null ? _formatDate(_range!.start) : null,
        tanggalSelesai: _range != null ? _formatDate(_range!.end) : null,
      );
      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Gagal memuat jadwal');
      }
      if (!mounted) return;
      setState(() {
        jadwalData = res['data'] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loadingJadwal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = jadwalData?['booking'] as List<dynamic>?;
    final doctorInfo = jadwalData?['dokter'] as Map<String, dynamic>?;
    final rentang = jadwalData?['rentang_tanggal'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Dokter')),
      body: loadingDokter
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey('jadwal-dokter-$selectedDokter'),
                        initialValue: selectedDokter,
                        decoration: const InputDecoration(labelText: 'Pilih Dokter'),
                        items: dokterList.map((d) {
                          final id = (d['id_dokter'] as num?)?.toInt();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(d['nama']?.toString() ?? '-'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedDokter = value);
                          if (value != null) {
                            _fetchJadwal();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rentang == null
                                  ? 'Rentang tanggal default'
                                  : 'Rentang: ${rentang['mulai']} s/d ${rentang['selesai']}',
                            ),
                          ),
                          TextButton(
                            onPressed: _chooseRange,
                            child: const Text('Ganti Rentang'),
                          ),
                        ],
                      ),
                      if (doctorInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          doctorInfo['nama']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(doctorInfo['spesialisasi']?.toString() ?? '-'),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: loadingJadwal
                      ? const Center(child: CircularProgressIndicator())
                      : (bookings == null || bookings.isEmpty)
                          ? const Center(child: Text('Belum ada jadwal pada rentang ini'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: bookings.length,
                              separatorBuilder: (context, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = bookings[index] as Map<String, dynamic>? ?? {};
                                final tanggal = item['tanggal']?.toString() ?? '-';
                                final waktu = item['waktu']?.toString() ?? '-';
                                final pasien = item['nama_pasien']?.toString() ?? '-';
                                final status = item['status']?.toString() ?? '-';
                                final noAntrian = item['no_antrian']?.toString() ?? '-';
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$tanggal - $waktu',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text('#$noAntrian'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Pasien: $pasien'),
                                        const SizedBox(height: 4),
                                        Text('Status: ${status.toUpperCase()}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
