import 'package:flutter/material.dart';
❯ sudo mariadb -e "
SELECT user, host, plugin
FROM mysql.user
WHERE user='root';
"
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
❯ sudo mariadb

ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
❯ sudo su
[dia1024kb archie]# mariadb
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
[dia1024kb archie]# import '../../services/api_service.dart';

class DataDokterPage extends StatefulWidget {
  const DataDokterPage({super.key});

  @override
  State<DataDokterPage> createState() => _DataDokterPageState();
}

class _DataDokterPageState extends State<DataDokterPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getDokter();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ApiService.getDokter();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Dokter')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
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
                      'Gagal memuat data dokter: ${snapshot.error}',
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
                    child: Text('Belum ada data dokter.'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final dokter = items[index] as Map<String, dynamic>;
                return _DokterItem(
                  nama: dokter['nama']?.toString() ?? '-',
                  spesialis: dokter['spesialisasi']?.toString() ?? '-',
                  telepon: dokter['no_telepon']?.toString() ?? '-',
                  jadwal: dokter['jadwal_praktik']?.toString(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DokterItem extends StatelessWidget {
  final String nama;
  final String spesialis;
  final String telepon;
  final String? jadwal;

  const _DokterItem({
    required this.nama,
    required this.spesialis,
    required this.telepon,
    this.jadwal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  child: Icon(Icons.medical_services),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(spesialis, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 6),
                Text(telepon.isEmpty ? '-' : telepon),
              ],
            ),
            if (jadwal != null && jadwal!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(jadwal!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
