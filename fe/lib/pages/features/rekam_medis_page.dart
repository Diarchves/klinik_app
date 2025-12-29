import 'package:flutter/material.dart';

class RekamMedisPage extends StatelessWidget {
  const RekamMedisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekam Medis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _RekamMedisCard(
            tanggal: '12 Desember 2025',
            dokter: 'Dr. Andi Wijaya',
            diagnosa: 'Demam',
            tindakan: 'Pemberian obat penurun panas',
          ),
          SizedBox(height: 12),
          _RekamMedisCard(
            tanggal: '5 November 2025',
            dokter: 'Dr. Siti Aminah',
            diagnosa: 'Sakit gigi',
            tindakan: 'Pembersihan dan penambalan',
          ),
        ],
      ),
    );
  }
}

class _RekamMedisCard extends StatelessWidget {
  final String tanggal;
  final String dokter;
  final String diagnosa;
  final String tindakan;

  const _RekamMedisCard({
    required this.tanggal,
    required this.dokter,
    required this.diagnosa,
    required this.tindakan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  tanggal,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dokter: $dokter'),
            const SizedBox(height: 6),
            Text('Diagnosa:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(diagnosa),
            const SizedBox(height: 6),
            Text('Tindakan:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(tindakan),
          ],
        ),
      ),
    );
  }
}
