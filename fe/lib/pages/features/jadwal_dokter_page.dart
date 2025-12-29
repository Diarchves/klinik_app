import 'package:flutter/material.dart';

class JadwalDokterPage extends StatelessWidget {
  const JadwalDokterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Dokter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _DokterCard(
            nama: 'Dr. Andi Wijaya',
            spesialis: 'Dokter Umum',
            jadwal: 'Senin - Jumat\n08.00 - 12.00',
          ),
          SizedBox(height: 12),
          _DokterCard(
            nama: 'Dr. Siti Aminah',
            spesialis: 'Dokter Gigi',
            jadwal: 'Senin, Rabu, Jumat\n09.00 - 13.00',
          ),
          SizedBox(height: 12),
          _DokterCard(
            nama: 'Dr. Budi Santoso',
            spesialis: 'Dokter Anak',
            jadwal: 'Selasa & Kamis\n10.00 - 14.00',
          ),
        ],
      ),
    );
  }
}

class _DokterCard extends StatelessWidget {
  final String nama;
  final String spesialis;
  final String jadwal;

  const _DokterCard({
    required this.nama,
    required this.spesialis,
    required this.jadwal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 30)),
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
                  Text(jadwal, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
