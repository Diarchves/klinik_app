import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class DataDokterPage extends StatefulWidget {
  const DataDokterPage({super.key});

  @override
  State<DataDokterPage> createState() => _DataDokterPageState();
}

class _DataDokterPageState extends State<DataDokterPage> {
  late Future<List<dynamic>> _dokterFuture = ApiService.getDokter();
  bool _isAdmin = false;
  String? _adminToken;

  @override
  void initState() {
    super.initState();
    _hydrateRole();
  }

  Future<void> _hydrateRole() async {
    final admin = await SessionManager.isAdmin();
    final token = admin ? await SessionManager.getAdminToken() : null;
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _adminToken = token;
    });
  }

  Future<void> _reloadDokter() async {
    setState(() {
      _dokterFuture = ApiService.getDokter();
    });
    await _dokterFuture;
  }

  String? _requireAdminToken() {
    if (!_isAdmin || (_adminToken?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya admin yang bisa mengelola dokter')),
      );
      return null;
    }
    return _adminToken;
  }

  Future<void> _openDokterDialog({Map<String, dynamic>? dokter}) async {
    final token = _requireAdminToken();
    if (token == null) return;

    final formKey = GlobalKey<FormState>();
    final namaCtrl = TextEditingController(text: dokter?['nama']?.toString() ?? '');
    final spesialisCtrl =
        TextEditingController(text: dokter?['spesialisasi']?.toString() ?? '');
    final teleponCtrl =
        TextEditingController(text: dokter?['no_telepon']?.toString() ?? '');
    final jadwalCtrl =
        TextEditingController(text: dokter?['jadwal_praktik']?.toString() ?? '');

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
                if (dokter == null) {
                  await ApiService.createDokter(
                    token: token,
                    nama: namaCtrl.text.trim(),
                    spesialisasi: spesialisCtrl.text.trim(),
                    noTelepon: teleponCtrl.text.trim().isEmpty
                        ? null
                        : teleponCtrl.text.trim(),
                    jadwal: jadwalCtrl.text.trim().isEmpty
                        ? null
                        : jadwalCtrl.text.trim(),
                  );
                } else {
                  await ApiService.updateDokter(
                    idDokter: (dokter['id_dokter'] as num).toInt(),
                    token: token,
                    nama: namaCtrl.text.trim(),
                    spesialisasi: spesialisCtrl.text.trim(),
                    noTelepon: teleponCtrl.text.trim().isEmpty
                        ? null
                        : teleponCtrl.text.trim(),
                    jadwal: jadwalCtrl.text.trim().isEmpty
                        ? null
                        : jadwalCtrl.text.trim(),
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
              title: Text(dokter == null ? 'Tambah Dokter' : 'Ubah Dokter'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Dokter'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: spesialisCtrl,
                        decoration: const InputDecoration(labelText: 'Spesialisasi'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Spesialisasi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: teleponCtrl,
                        decoration: const InputDecoration(labelText: 'No. Telepon'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: jadwalCtrl,
                        decoration: const InputDecoration(labelText: 'Jadwal Praktik'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: Text(dokter == null ? 'Simpan' : 'Perbarui'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _reloadDokter();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> dokter) async {
    final token = _requireAdminToken();
    if (token == null) return;
    final idDokter = (dokter['id_dokter'] as num?)?.toInt();
    if (idDokter == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Dokter'),
        content: Text('Hapus ${dokter['nama'] ?? 'dokter ini'}?'),
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
        await ApiService.deleteDokter(idDokter: idDokter, token: token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data dokter dihapus')),
          );
        }
        await _reloadDokter();
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
      appBar: AppBar(title: const Text('Data Dokter')),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _openDokterDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _reloadDokter,
        child: FutureBuilder<List<dynamic>>(
          future: _dokterFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
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
                    child: Center(child: Text('Belum ada data dokter')),
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
                return _DokterItem(
                  data: item,
                  isAdmin: _isAdmin,
                  onEdit: () => _openDokterDialog(dokter: item),
                  onDelete: () => _confirmDelete(item),
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
  final Map<String, dynamic> data;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DokterItem({
    required this.data,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nama = data['nama']?.toString() ?? 'Tidak diketahui';
    final spesialis = data['spesialisasi']?.toString() ?? '-';
    final telepon = data['no_telepon']?.toString() ?? '-';
    final jadwal = data['jadwal_praktik']?.toString();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 26, child: Icon(Icons.medical_services)),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 6),
                      Text(telepon),
                    ],
                  ),
                  if (jadwal != null && jadwal.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Jadwal: $jadwal'),
                  ],
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
