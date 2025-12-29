import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class AntrianPage extends StatefulWidget {
  const AntrianPage({super.key});

  @override
  State<AntrianPage> createState() => _AntrianPageState();
}

class _AntrianPageState extends State<AntrianPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAntrian();
  }

  Future<List<Map<String, dynamic>>> _fetchAntrian() async {
    final id = await SessionManager.getId();
    if (id == null) {
      throw ApiException('Silakan login terlebih dahulu.');
    }
    final response = await ApiService.getAntrian(id);
    final data = response['data'];
    if (data is List) {
      return data
          .map((item) => item is Map<String, dynamic>
              ? item
              : Map<String, dynamic>.from(item as Map<dynamic, dynamic>))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchAntrian();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Antrian')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada antrian untuk akun ini.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final nomor = item['no_antrian'] ?? '-';
                final status = item['status']?.toString().toUpperCase() ?? '-';
                final dokter = item['nama_dokter']?.toString() ?? '-';
                final tanggal = item['tanggal']?.toString() ?? '';
                final waktu = item['waktu']?.toString() ?? '';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('$nomor')),
                    title: Text(dokter),
                    subtitle: Text('$tanggal • $waktu'),
                    trailing: Text(status),
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
