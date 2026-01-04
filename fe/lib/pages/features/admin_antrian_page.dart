import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class AdminAntrianPage extends StatefulWidget {
  const AdminAntrianPage({super.key});

  @override
  State<AdminAntrianPage> createState() => _AdminAntrianPageState();
}

class _AdminAntrianPageState extends State<AdminAntrianPage> {
  Future<List<dynamic>>? _antrianFuture;
  String? _token;
  bool _authorized = false;
  bool _initializing = true;
  String? _statusFilter;

  final List<Map<String, String?>> _statusOptions = const [
    {'label': 'Semua Status', 'value': null},
    {'label': 'Menunggu', 'value': 'menunggu'},
    {'label': 'Dipanggil', 'value': 'dipanggil'},
    {'label': 'Selesai', 'value': 'selesai'},
  ];

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
      _antrianFuture = _fetchAntrian();
    });
  }

  Future<List<dynamic>> _fetchAntrian() async {
    final token = _token;
    if (token == null) {
      throw Exception('Token admin tidak ditemukan');
    }
    final res = await ApiService.getAntrianAdmin(
      status: _statusFilter,
      token: token,
    );
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Gagal memuat antrian');
    }
    final data = res['data'];
    if (data is List) return data;
    return [];
  }

  Future<void> _refresh() async {
    if (!_authorized) return;
    setState(() {
      _antrianFuture = _fetchAntrian();
    });
    await _antrianFuture;
  }

  Future<void> _updateStatus(Map<String, dynamic> item, String status) async {
    final token = _token;
    final idAntrian = (item['id_antrian'] as num?)?.toInt();
    if (token == null || idAntrian == null) return;
    try {
      await ApiService.updateAntrian(
        idAntrian: idAntrian,
        status: status,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status antrian #$idAntrian diperbarui ke $status')),
      );
      if (status.toLowerCase() == 'selesai') {
        await _handleRekamMedis(item);
      }
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleRekamMedis(Map<String, dynamic> item) async {
    final token = _token;
    final idJanji = (item['id_janji'] as num?)?.toInt();
    if (token == null || idJanji == null) return;

    try {
      final existing = await ApiService.getRekamMedisAdmin(
        idJanji: idJanji,
        token: token,
      );
      final data = existing['data'];
      final alreadyExists = data is List && data.isNotEmpty;
      if (alreadyExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rekam medis sudah ada. Gunakan menu Rekam Medis untuk mengubahnya.'),
          ),
        );
        return;
      }
      await _openRekamMedisDialog(item);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openRekamMedisDialog(Map<String, dynamic> item) async {
    final token = _token;
    final idJanji = (item['id_janji'] as num?)?.toInt();
    if (token == null || idJanji == null) return;

    final formKey = GlobalKey<FormState>();
    final diagnosaCtrl = TextEditingController();
    final tindakanCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
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
                await ApiService.createRekamMedis(
                  idJanji: idJanji,
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
              title: const Text('Rekam Medis Pasien'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${item['nama_pasien'] ?? '-'} - ${item['nama_dokter'] ?? '-'}'),
                      const SizedBox(height: 12),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Antrian')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kelola Antrian')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Hanya admin yang dapat mengelola antrian.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Antrian')),
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
            final items = data.whereType<Map<String, dynamic>>().toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String?>(
                  key: ValueKey('filter_${_statusFilter ?? 'all'}'),
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(labelText: 'Filter Status'),
                  items: _statusOptions
                      .map(
                        (option) => DropdownMenuItem<String?>(
                          value: option['value'],
                          child: Text(option['label'] ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                      _antrianFuture = _fetchAntrian();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Center(child: Text('Belum ada data antrian untuk filter ini'))
                else
                  ...items.map((item) => _AntrianCard(
                        data: item,
                        onStatusChange: (status) => _updateStatus(item, status),
                        onCreateRekam: () => _handleRekamMedis(item),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AntrianCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(String status) onStatusChange;
  final VoidCallback onCreateRekam;

  const _AntrianCard({
    required this.data,
    required this.onStatusChange,
    required this.onCreateRekam,
  });

  @override
  Widget build(BuildContext context) {
    final pasien = data['nama_pasien']?.toString() ?? '-';
    final dokter = data['nama_dokter']?.toString() ?? '-';
    final tanggal = data['tanggal']?.toString() ?? '-';
    final waktu = data['waktu']?.toString() ?? '-';
    final poli = data['poli']?.toString() ?? '-';
    final status = (data['status']?.toString().toLowerCase() ?? 'menunggu');
    final noAntrian = data['no_antrian']?.toString() ?? '-';

    final statusItems = ['menunggu', 'dipanggil', 'selesai'];

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
                  backgroundColor: Colors.blue.shade100,
                  child: Text(noAntrian),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pasien, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Dokter: $dokter'),
                      Text('Tanggal: $tanggal - $waktu'),
                      Text('Poli: $poli'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('status_${data['id_antrian']}_$status'),
                    initialValue: statusItems.contains(status) ? status : 'menunggu',
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statusItems
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != status) {
                        onStatusChange(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: status == 'selesai' ? onCreateRekam : null,
                  icon: const Icon(Icons.note_add),
                  label: const Text('Rekam Medis'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
