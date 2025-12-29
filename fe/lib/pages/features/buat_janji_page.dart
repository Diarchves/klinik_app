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

  List<Map<String, dynamic>> _dokter = [];
  bool _loadingDokter = true;
  bool _submitting = false;
  String? _error;
  int? _selectedDokter;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int? _pasienId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final id = await SessionManager.getId();
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu.')),
      );
      Navigator.pop(context);
      return;
    }
    setState(() => _pasienId = id);
    await _loadDokter();
  }

  Future<void> _loadDokter() async {
    setState(() {
      _loadingDokter = true;
      _error = null;
    });
    try {
      final result = await ApiService.getDokter();
      setState(() {
        _dokter = result
          .map((item) => item is Map<String, dynamic>
            ? item
            : item is Map
              ? Map<String, dynamic>.from(
                item as Map<dynamic, dynamic>,
                )
              : <String, dynamic>{})
            .toList();
      });
    } catch (e) {
      setState(() => _error = 'Tidak dapat memuat data dokter: $e');
    } finally {
      if (mounted) setState(() => _loadingDokter = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_pasienId == null) {
      _showMessage('Session tidak ditemukan, login ulang.');
      return;
    }
    if (_selectedDokter == null || _selectedDate == null || _selectedTime == null) {
      _showMessage('Lengkapi dokter, tanggal, dan jam.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final tanggal = _selectedDate!.toIso8601String().split('T').first;
      final jam = _formatTime(_selectedTime!);
      final res = await ApiService.buatJanji(
        idPasien: _pasienId!,
        idDokter: _selectedDokter!,
        tanggal: tanggal,
        jam: jam,
        poli: poliController.text.trim(),
        catatan: catatanController.text.trim(),
      );
      final nomor = res['data']?['no_antrian'];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nomor != null
                ? 'Janji berhasil! Nomor antrian: $nomor'
                : 'Janji berhasil dibuat',
          ),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Janji')),
      body: _loadingDokter
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadDokter,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedDokter,
                        decoration: const InputDecoration(labelText: 'Pilih Dokter'),
                        items: _dokter.map((dokter) {
                          final id = _parseId(dokter['id_dokter']);
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(dokter['nama']?.toString() ?? '-'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedDokter = value),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tanggal Janji'),
                        subtitle: Text(
                          _selectedDate == null
                              ? 'Belum dipilih'
                              : _selectedDate!.toIso8601String().split('T').first,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Jam Janji'),
                        subtitle: Text(
                          _selectedTime == null
                              ? 'Belum dipilih'
                              : _formatTime(_selectedTime!),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: _pickTime,
                        ),
                      ),
                      TextField(
                        controller: poliController,
                        decoration: const InputDecoration(
                          labelText: 'Poli (opsional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Simpan Janji'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  int? _parseId(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
