import 'package:flutter/material.dart';

class ObatPage extends StatelessWidget {
  const ObatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Obat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ObatCard(
            nama: 'Paracetamol',
            jenis: 'Analgesik',
            bentuk: 'Tablet',
            stok: 120,
          ),
          SizedBox(height: 12),
          _ObatCard(
            nama: 'Amoxicillin',
            jenis: 'Antibiotik',
            bentuk: 'Kapsul',
            stok: 80,
          ),
          SizedBox(height: 12),
          _ObatCard(
            nama: 'Vitamin C',
            jenis: 'Suplemen',
            bentuk: 'Tablet',
            stok: 200,
          ),
        ],
      ),
    );
  }
}

class _ObatCard extends StatelessWidget {
  final String nama;
  final String jenis;
  final String bentuk;
  final int stok;

  const _ObatCard({
    required this.nama,
    required this.jenis,
    required this.bentuk,
    required this.stok,
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
                      Text('Stok: $stok'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
