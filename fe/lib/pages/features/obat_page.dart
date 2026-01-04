import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class ObatPage extends StatefulWidget {
  const ObatPage({super.key});

  @override
  State<ObatPage> createState() => _ObatPageState();
}

class _ObatPageState extends State<ObatPage> {
  late Future<List<dynamic>> _obatFuture;
  bool _isAdmin = false;
  String? _adminToken;

  @override
  void initState() {
    super.initState();
    _obatFuture = _loadObat();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final admin = await SessionManager.isAdmin();
    final token = admin ? await SessionManager.getAdminToken() : null;
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _adminToken = token;
    });
  }

  Future<List<dynamic>> _loadObat() async {
    final res = await ApiService.getObat();
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal mengambil data obat');
    }
    final data = res['data'];
    if (data is List) return data;
    return [];
  }

  Future<void> _refresh() async {
    setState(() {
      _obatFuture = _loadObat();
    });
    await _obatFuture;
  }

  String? _requireToken() {
    if (!_isAdmin || (_adminToken?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur ini hanya untuk admin')),
      );
      return null;
    }
    return _adminToken;
  }

  Future<void> _openObatDialog({Map<String, dynamic>? data}) async {
    final token = _requireToken();
    if (token == null) return;

    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: data?['nama_obat']?.toString() ?? '');
    final jenisCtrl = TextEditingController(text: data?['jenis']?.toString() ?? '');
    final bentukCtrl = TextEditingController(text: data?['bentuk']?.toString() ?? '');
    final stokCtrl = TextEditingController(
      text: data?['stok'] != null ? '${data!['stok']}' : '',
    );
    bool submitting = false;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (formContext, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setStateDialog(() => submitting = true);
              try {
                final stokValue = stokCtrl.text.trim().isEmpty
                    ? null
                    : int.tryParse(stokCtrl.text.trim());
                if (data == null) {
                  await ApiService.createObat(
                    nama: namaCtrl.text.trim(),
                    jenis: jenisCtrl.text.trim().isEmpty ? null : jenisCtrl.text.trim(),
                    bentuk:
                        bentukCtrl.text.trim().isEmpty ? null : bentukCtrl.text.trim(),
                    stok: stokValue,
                    token: token,
                  );
                } else {
                  await ApiService.updateObat(
                    idObat: (data['id_obat'] as num).toInt(),
                    token: token,
                    nama: namaCtrl.text.trim(),
                    jenis: jenisCtrl.text.trim().isEmpty ? null : jenisCtrl.text.trim(),
                    bentuk:
                        bentukCtrl.text.trim().isEmpty ? null : bentukCtrl.text.trim(),
                    stok: stokValue,
                  );
                }
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                setStateDialog(() => submitting = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            }

            return AlertDialog(
              title: Text(data == null ? 'Tambah Obat' : 'Ubah Obat'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Obat'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: jenisCtrl,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: bentukCtrl,
                      decoration: const InputDecoration(labelText: 'Bentuk'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: stokCtrl,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: Text(data == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _deleteObat(Map<String, dynamic> data) async {
    final token = _requireToken();
    if (token == null) return;
    final id = (data['id_obat'] as num?)?.toInt();
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: Text('Hapus ${data['nama_obat'] ?? 'obat ini'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteObat(idObat: id, token: token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data obat dihapus')),
          );
        }
        await _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Obat')),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _openObatDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _obatFuture,
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
                    child: Center(child: Text('Belum ada data obat')),
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
                return _ObatCard(
                  data: item,
                  isAdmin: _isAdmin,
                  onEdit: () => _openObatDialog(data: item),
                  onDelete: () => _deleteObat(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ObatCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ObatCard({
    required this.data,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nama = data['nama_obat']?.toString() ?? '-';
    final jenis = data['jenis']?.toString() ?? '-';
    final bentuk = data['bentuk']?.toString() ?? '-';
    final stok = (data['stok'] as num?)?.toInt();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 26, child: Icon(Icons.medication)),
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
                  const SizedBox(height: 6),
                  Text('Jenis: $jenis'),
                  Text('Bentuk: $bentuk'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.inventory, size: 16),
                      const SizedBox(width: 6),
                      Text('Stok: ${stok ?? '-'}'),
                    ],
                  ),
                ],
              ),
            ),
            if (isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Ubah')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
