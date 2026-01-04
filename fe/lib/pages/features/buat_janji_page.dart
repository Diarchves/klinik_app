import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class BuatJanjiPage extends StatefulWidget {
  const BuatJanjiPage({super.key});

  @override
  State<BuatJanjiPage> createState() => _BuatJanjiPageState();
}

class _BuatJanjiPageState extends State<BuatJanjiPage> {
  final TextEditingController poliController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  List<Map<String, dynamic>> dokterList = [];
  List<Map<String, dynamic>> pasienList = [];
  int? selectedDokter;
  int? selectedPasien;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int? idPasien;
  bool loading = false;
  bool loadingDokter = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pasienId = await SessionManager.getId();
      final isAdmin = await SessionManager.isAdmin();
      final dokter = await ApiService.getDokter();
      final parsed = dokter
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      List<Map<String, dynamic>> pasien = [];
      int? defaultPasien = pasienId;
      if (isAdmin) {
        final pasienRes = await ApiService.getPasienList();
        if (pasienRes['success'] == true) {
          final data = (pasienRes['data'] as List?) ?? [];
          pasien = data
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (pasien.isNotEmpty) {
            defaultPasien = (pasien.first['id_pasien'] as num?)?.toInt();
          }
        }
      }
      if (!mounted) return;
      setState(() {
        idPasien = pasienId;
        dokterList = parsed;
        selectedDokter = parsed.isNotEmpty
            ? (parsed.first['id_dokter'] as num?)?.toInt()
            : null;
        pasienList = pasien;
        selectedPasien = defaultPasien;
        loadingDokter = false;
        _isAdmin = isAdmin;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingDokter = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data dokter: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (result != null) {
      setState(() => selectedDate = result);
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (result != null) {
      setState(() => selectedTime = result);
    }
  }

  Future<void> _submit() async {
    final targetPasien = _isAdmin ? selectedPasien : idPasien;
    if (targetPasien == null || targetPasien <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pasien terlebih dahulu')),
      );
      return;
    }
    if (selectedDokter == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi dokter, tanggal, dan jam')),
      );
      return;
    }

    final tanggal = '${selectedDate!.year.toString().padLeft(4, '0')}-'
        '${selectedDate!.month.toString().padLeft(2, '0')}-'
        '${selectedDate!.day.toString().padLeft(2, '0')}';
    final jam = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

    setState(() => loading = true);
    try {
      final res = await ApiService.buatJanji(
        idPasien: targetPasien,
        idDokter: selectedDokter!,
        tanggal: tanggal,
        jam: jam,
        poli: poliController.text.trim().isEmpty ? null : poliController.text.trim(),
        catatan:
            catatanController.text.trim().isEmpty ? null : catatanController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Janji berhasil dibuat')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    poliController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Janji')),
      body: loadingDokter
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isAdmin) ...[
                    DropdownButtonFormField<int>(
                      key: ValueKey('pasien-$selectedPasien'),
                      initialValue: selectedPasien,
                      items: pasienList.map((p) {
                        final id = (p['id_pasien'] as num?)?.toInt();
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(p['nama']?.toString() ?? '-'),
                        );
                      }).toList(),
                      decoration: const InputDecoration(labelText: 'Pilih Pasien'),
                      onChanged: (v) => setState(() => selectedPasien = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<int>(
                    key: ValueKey('dokter-$selectedDokter'),
                    initialValue: selectedDokter,
                    items: dokterList.map((d) {
                      final id = (d['id_dokter'] as num?)?.toInt();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(d['nama']?.toString() ?? '-'),
                      );
                    }).toList(),
                    decoration: const InputDecoration(labelText: 'Pilih Dokter'),
                    onChanged: (v) => setState(() => selectedDokter = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: poliController,
                    decoration: const InputDecoration(labelText: 'Poli (opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: catatanController,
                    decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          child: Text(
                            selectedDate == null
                                ? 'Pilih Tanggal'
                                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickTime,
                          child: Text(
                            selectedTime == null
                                ? 'Pilih Jam'
                                : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Simpan Janji'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
