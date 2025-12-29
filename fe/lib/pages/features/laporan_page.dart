import 'package:flutter/material.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Klinik')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _LaporanCard(
            judul: 'Laporan Kunjungan Pasien',
            periode: 'Desember 2025',
            isi:
                'Jumlah pasien meningkat dibanding bulan sebelumnya. '
                'Sebagian besar kunjungan berasal dari poli umum.',
          ),
          SizedBox(height: 12),
          _LaporanCard(
            judul: 'Laporan Penggunaan Obat',
            periode: 'Desember 2025',
            isi:
                'Paracetamol dan Amoxicillin menjadi obat yang paling sering digunakan. '
                'Stok obat masih dalam kondisi aman.',
          ),
          SizedBox(height: 12),
          _LaporanCard(
            judul: 'Laporan Kinerja Dokter',
            periode: 'Desember 2025',
            isi:
                'Dokter hadir sesuai jadwal praktik. '
                'Tidak ditemukan keterlambatan yang signifikan.',
          ),
        ],
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final String judul;
  final String periode;
  final String isi;

  const _LaporanCard({
    required this.judul,
    required this.periode,
    required this.isi,
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
            Text(
              judul,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.date_range, size: 16),
                const SizedBox(width: 6),
                Text(periode),
              ],
            ),
            const SizedBox(height: 10),
            Text(isi, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
