import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class AdminRekamMedisPage extends StatefulWidget {
  const AdminRekamMedisPage({super.key});

  @override
  State<AdminRekamMedisPage> createState() => _AdminRekamMedisPageState();
}

class _AdminRekamMedisPageState extends State<AdminRekamMedisPage> {
  Future<List<dynamic>>? _rekamFuture;
  String? _token;
  bool _authorized = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final isAdmin = await SessionManager.isAdmin();
    final token = isAdmin ? await SessionManager.getAdminToken() : null;
    if (!mounted) return;
    if (!isAdmin || token == null) {
      setState(() {
        _authorized = false;
        _initializing = false;
      });
      return;
    }
    setState(() {
      _authorized = true;
      _token = token;
      _initializing = false;
      _rekamFuture = _fetchRekam();
    });
  }

  Future<List<dynamic>> _fetchRekam() async {
    final token = _token;
    if (token == null) {
      throw Exception('Token admin tidak ditemukan');
    }
    final res = await ApiService.getRekamMedisAdmin(token: token);
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal memuat rekam medis');
    }
    final data = res['data'];
    if (data is List) return data;
    return [];
  }

  Future<void> _refresh() async {
    if (!_authorized) return;
    setState(() {
      _rekamFuture = _fetchRekam();
    });
    await _rekamFuture;
  }

  Future<void> _openEditDialog(Map<String, dynamic> record) async {
    final token = _token;
    final idRekam = (record['id_rekam'] as num?)?.toInt();
    if (token == null || idRekam == null) return;

    final formKey = GlobalKey<FormState>();
    final diagnosaCtrl = TextEditingController(text: record['diagnosa']?.toString() ?? '');
    final tindakanCtrl = TextEditingController(text: record['tindakan']?.toString() ?? '');
    final catatanCtrl = TextEditingController(text: record['catatan']?.toString() ?? '');
    bool submitting = false;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setStateDialog(() => submitting = true);
              try {
                await ApiService.updateRekamMedis(
                  idRekamMedis: idRekam,
                  diagnosa: diagnosaCtrl.text.trim(),
                  tindakan: tindakanCtrl.text.trim().isEmpty
                      ? null
                      : tindakanCtrl.text.trim(),
                  catatan: catatanCtrl.text.trim().isEmpty
                      ? null
                      : catatanCtrl.text.trim(),
                  token: token,
                );
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
              title: const Text('Ubah Rekam Medis'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: diagnosaCtrl,
                        decoration: const InputDecoration(labelText: 'Diagnosa Dokter'),
                        maxLines: 2,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Diagnosa wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: tindakanCtrl,
                        decoration: const InputDecoration(labelText: 'Tindakan (opsional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: catatanCtrl,
                        decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekam medis diperbarui')),
      );
      await _refresh();
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final token = _token;
    final idRekam = (record['id_rekam'] as num?)?.toInt();
    if (token == null || idRekam == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rekam Medis'),
        content: Text('Yakin ingin menghapus rekam medis #$idRekam?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteRekamMedis(idRekamMedis: idRekam, token: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekam medis dihapus')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    final token = _token;
    if (token == null) return;

    final formKey = GlobalKey<FormState>();
    final janjiCtrl = TextEditingController();
    final diagnosaCtrl = TextEditingController();
    final tindakanCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
    bool submitting = false;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setStateDialog(() => submitting = true);
              try {
                await ApiService.createRekamMedis(
                  idJanji: int.parse(janjiCtrl.text.trim()),
                  diagnosa: diagnosaCtrl.text.trim(),
                  tindakan: tindakanCtrl.text.trim().isEmpty
                      ? null
                      : tindakanCtrl.text.trim(),
                  catatan: catatanCtrl.text.trim().isEmpty
                      ? null
                      : catatanCtrl.text.trim(),
                  token: token,
                );
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
              title: const Text('Tambah Rekam Medis'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: janjiCtrl,
                        decoration: const InputDecoration(labelText: 'ID Janji'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'ID janji wajib diisi';
                          final parsed = int.tryParse(value);
                          if (parsed == null) return 'ID janji tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: diagnosaCtrl,
                        decoration: const InputDecoration(labelText: 'Diagnosa Dokter'),
                        maxLines: 2,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Diagnosa wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: tindakanCtrl,
                        decoration: const InputDecoration(labelText: 'Tindakan (opsional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: catatanCtrl,
                        decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rekam medis berhasil dibuat')),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekam Medis Pasien')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rekam Medis Pasien')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Hanya admin yang dapat melihat rekam medis seluruh pasien.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rekam Medis Pasien')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        icon: const Icon(Icons.note_add),
        label: const Text('Tambah Rekam Medis'),
      ),
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
            final items = snapshot.data?.whereType<Map<String, dynamic>>().toList() ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada rekam medis.')),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final record = items[index];
                return _RekamMedisCard(
                  record: record,
                  onEdit: () => _openEditDialog(record),
                  onDelete: () => _deleteRecord(record),
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
  final Map<String, dynamic> record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RekamMedisCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pasien = record['nama_pasien']?.toString() ?? '-';
    final dokter = record['nama_dokter']?.toString() ?? '-';
    final diagnosa = record['diagnosa']?.toString() ?? '-';
    final tindakan = record['tindakan']?.toString();
    final catatan = record['catatan']?.toString();
    final tanggal = record['tanggal']?.toString() ?? '-';
    final idRekam = record['id_rekam']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(idRekam),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pasien, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dokter: $dokter'),
                      Text('Tanggal: $tanggal'),
                    ],
                  ),
                ),
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
            const SizedBox(height: 12),
            Text('Diagnosa: $diagnosa'),
            if (tindakan != null && tindakan.isNotEmpty)
              Text('Tindakan: $tindakan'),
            if (catatan != null && catatan.isNotEmpty)
              Text('Catatan: $catatan'),
          ],
        ),
      ),
    );
  }
}
