import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class BuatJanjiPage extends StatefulWidget {
  const BuatJanjiPage({super.key});
  @override
  State<BuatJanjiPage> createState() => _BuatJanjiPageState();
}

class _BuatJanjiPageState extends State<BuatJanjiPage> {
  int? selectedDokter;
  String tanggal = '';
  String jam = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Janji')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getDokter(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final dokter = snap.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  hint: const Text('Pilih Dokter'),
                  items: dokter.map<DropdownMenuItem<int>>((d) {
                    final id = d['id_dokter'] is int
                        ? d['id_dokter'] as int
                        : int.parse(d['id_dokter'].toString());
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(d['nama'].toString()),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedDokter = v),
                  value: selectedDokter,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal (YYYY-MM-DD)',
                  ),
                  onChanged: (v) => tanggal = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Jam (HH:MM)'),
                  onChanged: (v) => jam = v,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (selectedDokter == null ||
                                tanggal.isEmpty ||
                                jam.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lengkapi data')),
                              );
                              return;
                            }
                            final idPasien = await SessionManager.getId();
                            if (idPasien == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan login dulu'),
                                ),
                              );
                              return;
                            }
                            setState(() => loading = true);
                            final res = await ApiService.buatJanji(
                              idPasien: idPasien,
                              idDokter: selectedDokter!,
                              tanggal: tanggal,
                              jam: jam,
                            );
                            setState(() => loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['message'] ?? 'Selesai'),
                              ),
                            );
                            if (res['status'] == 'success')
                              Navigator.pop(context);
                          },
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Janji'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
