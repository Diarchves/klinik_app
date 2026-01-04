import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';
import '../auth/register_page.dart';

class PasienPage extends StatefulWidget {
  const PasienPage({super.key});

  @override
  State<PasienPage> createState() => _PasienPageState();
}

class _PasienPageState extends State<PasienPage> {
  Future<List<dynamic>>? _pasienFuture;
  bool _isAdmin = false;
  bool _roleChecked = false;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    final admin = await SessionManager.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _roleChecked = true;
      _pasienFuture = admin ? _fetchPasien() : Future.value(const []);
    });
  }

  Future<List<dynamic>> _fetchPasien() async {
    final res = await ApiService.getPasienList();
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal mengambil data pasien');
    }
    final data = res['data'];
    if (data is List) {
      return data;
    }
    return [];
  }

  Future<void> _refresh() async {
    if (!_isAdmin) return;
    setState(() {
      _pasienFuture = _fetchPasien();
    });
    final future = _pasienFuture;
    if (future != null) {
      await future;
    }
  }

  Future<void> _openRegister() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya admin yang dapat menambah pasien.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Pasien')),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _openRegister,
              child: const Icon(Icons.person_add_alt_1),
            )
          : null,
      body: !_roleChecked || _pasienFuture == null
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Hanya admin yang dapat melihat atau mendaftarkan pasien.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<dynamic>>(
                    future: _pasienFuture,
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
                              child: Center(child: Text('Belum ada data pasien')),
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
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('NIK: ${item['nik'] ?? '-'}'),
                                  if (item['tanggal_lahir'] != null)
                                    Text('Tanggal Lahir: ${item['tanggal_lahir']}'),
                                  if (item['alamat'] != null)
                                    Text('Alamat: ${item['alamat']}'),
                                  if (item['no_telepon'] != null)
                                    Text('No Telepon: ${item['no_telepon']}'),
                                ],
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
