import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  late Future<List<dynamic>> _antrianFuture;

  @override
  void initState() {
    super.initState();
    _antrianFuture = _loadAntrian();
  }

  Future<List<dynamic>> _loadAntrian() async {
    final idPasien = await SessionManager.getId();
    if (idPasien == null || idPasien <= 0) {
      throw Exception('Fitur ini hanya untuk akun pasien');
    }
    final res = await ApiService.getAntrian(idPasien);
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal mengambil antrian');
    }
    final data = res['data'];
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<void> _refresh() async {
    setState(() {
      _antrianFuture = _loadAntrian();
    });
    await _antrianFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Antrian')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _antrianFuture,
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
                    child: Center(child: Text('Tidak ada antrian untuk Anda')),
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
                final dokter = item['nama_dokter']?.toString() ?? '-';
                final tanggal = item['tanggal']?.toString() ?? '-';
                final waktu = item['waktu']?.toString() ?? '-';
                final noAntrian = item['no_antrian']?.toString() ?? '-';
                final status = item['status']?.toString() ?? '-';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(noAntrian)),
                    title: Text(dokter),
                    subtitle: Text('Tanggal: $tanggal\nJam: $waktu'),
                    trailing: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status.toUpperCase()),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
