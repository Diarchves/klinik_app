import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class RekamMedisPage extends StatefulWidget {
  const RekamMedisPage({super.key});

  @override
  State<RekamMedisPage> createState() => _RekamMedisPageState();
}

class _RekamMedisPageState extends State<RekamMedisPage> {
  late Future<List<dynamic>> _rekamFuture;

  @override
  void initState() {
    super.initState();
    _rekamFuture = _loadRekamMedis();
  }

  Future<List<dynamic>> _loadRekamMedis() async {
    final id = await SessionManager.getId();
    if (id == null || id <= 0) {
      throw Exception('Fitur ini hanya untuk akun pasien');
    }
    final res = await ApiService.getRekamMedis(id);
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal mengambil rekam medis');
    }
    final data = res['data'];
    if (data is List) return data;
    return [];
  }

  Future<void> _refresh() async {
    setState(() {
      _rekamFuture = _loadRekamMedis();
    });
    await _rekamFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekam Medis')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _rekamFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(snapshot.error.toString()),
                  ),
                ],
              );
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada rekam medis')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = data[index] as Map<String, dynamic>? ?? {};
                return _RekamMedisCard(
                  tanggal: item['tanggal']?.toString() ?? '-',
                  dokter: item['nama_dokter']?.toString() ?? '-',
                  diagnosa: item['diagnosa']?.toString() ?? '-',
                  tindakan: item['tindakan']?.toString() ?? '-',
                  catatan: item['catatan']?.toString(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RekamMedisCard extends StatelessWidget {
  final String tanggal;
  final String dokter;
  final String diagnosa;
  final String tindakan;
  final String? catatan;

  const _RekamMedisCard({
    required this.tanggal,
    required this.dokter,
    required this.diagnosa,
    required this.tindakan,
    this.catatan,
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
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  tanggal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dokter: $dokter'),
            const SizedBox(height: 6),
            const Text('Diagnosa:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(diagnosa),
            const SizedBox(height: 6),
            const Text('Tindakan:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tindakan),
            if (catatan != null && catatan!.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(catatan!),
            ],
          ],
        ),
      ),
    );
  }
}
