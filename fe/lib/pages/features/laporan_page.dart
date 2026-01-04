import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final TextEditingController periodeController = TextEditingController();
  final List<String> jenisOptions = const [
    'kunjungan',
    'penggunaan',
    'kinerja',
  ];
  late String selectedJenis;
  late Future<List<dynamic>> _laporanFuture;

  @override
  void initState() {
    super.initState();
    selectedJenis = jenisOptions.first;
    _laporanFuture = _loadLaporan();
  }

  Future<List<dynamic>> _loadLaporan() async {
    final res = await ApiService.getLaporan(
      jenis: selectedJenis,
      periode: periodeController.text.trim().isEmpty
          ? null
          : periodeController.text.trim(),
    );
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal mengambil laporan');
    }
    final data = res['data'];
    if (data is List) return data;
    return [];
  }

  void _applyFilter() {
    setState(() {
      _laporanFuture = _loadLaporan();
    });
  }

  @override
  void dispose() {
    periodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Klinik')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('jenis-$selectedJenis'),
                  initialValue: selectedJenis,
                  decoration: const InputDecoration(labelText: 'Jenis Laporan'),
                  items: jenisOptions
                      .map((jenis) => DropdownMenuItem(
                            value: jenis,
                            child: Text(jenis.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedJenis = value);
                    _applyFilter();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: periodeController,
                  decoration: const InputDecoration(
                    labelText: 'Periode (opsional, contoh: 2025-12)',
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text('Terapkan'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Tidak ada laporan untuk filter ini'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: data.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = data[index] as Map<String, dynamic>? ?? {};
                    final statistik = (item['statistik'] as List?)
                            ?.whereType<Map<String, dynamic>>()
                            .toList() ??
                        const <Map<String, dynamic>>[];
                    final detailRows = (item['detail_rows'] as List?)
                            ?.whereType<Map<String, dynamic>>()
                            .toList() ??
                        const <Map<String, dynamic>>[];
                    final catatan = (item['catatan'] as List?)
                            ?.map((note) => note.toString())
                            .where((note) => note.trim().isNotEmpty)
                            .toList() ??
                        const <String>[];
                    return _LaporanCard(
                      judul: item['jenis']?.toString().toUpperCase() ?? '-'.toUpperCase(),
                      periode: item['periode']?.toString() ?? '-',
                      isi: item['isi_laporan']?.toString() ?? '-',
                      statistik: statistik,
                      detailTitle: item['detail_title']?.toString(),
                      detailRows: detailRows,
                      catatan: catatan,
                      generatedAt: item['generated_at']?.toString(),
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

class _LaporanCard extends StatelessWidget {
  final String judul;
  final String periode;
  final String isi;
  final List<Map<String, dynamic>> statistik;
  final String? detailTitle;
  final List<Map<String, dynamic>> detailRows;
  final List<String> catatan;
  final String? generatedAt;

  const _LaporanCard({
    required this.judul,
    required this.periode,
    required this.isi,
    this.statistik = const <Map<String, dynamic>>[],
    this.detailTitle,
    this.detailRows = const <Map<String, dynamic>>[],
    this.catatan = const <String>[],
    this.generatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              judul,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16),
                const SizedBox(width: 6),
                Text(periode),
              ],
            ),
            const SizedBox(height: 10),
            Text(isi, style: const TextStyle(fontSize: 14)),
            if (statistik.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statistik
                    .map(
                      (stat) => Chip(
                        label: Text('${stat['label']}: ${stat['value']}'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue.shade50,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (detailRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (detailTitle != null && detailTitle!.isNotEmpty)
                Text(
                  detailTitle!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ...detailRows.map(
                (row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row['label']?.toString() ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(row['value']?.toString() ?? '-'),
                        ],
                      ),
                      if ((row['note']?.toString() ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            row['note'].toString(),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (catatan.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Catatan Penting',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...catatan.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(note)),
                    ],
                  ),
                ),
              ),
            ],
            if (generatedAt != null && generatedAt!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Diperbarui: $generatedAt',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
