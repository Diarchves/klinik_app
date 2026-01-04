import 'package:flutter/material.dart';

import 'package:klinik_app/pages/auth/register_page.dart';
import 'package:klinik_app/pages/features/admin_antrian_page.dart';
import 'package:klinik_app/pages/features/admin_rekam_medis_page.dart';
import 'package:klinik_app/pages/features/antrian_page.dart';
import 'package:klinik_app/pages/features/buat_janji_page.dart';
import 'package:klinik_app/pages/features/data_dokter_page.dart';
import 'package:klinik_app/pages/features/jadwal_dokter_page.dart';
import 'package:klinik_app/pages/features/laporan_page.dart';
import 'package:klinik_app/pages/features/obat_page.dart';
import 'package:klinik_app/pages/features/pasien_page.dart';
import 'package:klinik_app/pages/features/rekam_medis_page.dart';
import 'package:klinik_app/utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  String? _namaPengguna;
  bool _loadingUser = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final nama = await SessionManager.getNama();
    final isAdmin = await SessionManager.isAdmin();
    if (!mounted) return;
    setState(() {
      _namaPengguna = nama;
      _loadingUser = false;
      _isAdmin = isAdmin;
    });
  }

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  final List<String> banners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greetingText = _loadingUser
        ? 'Memuat profil...'
        : 'Halo, ${_namaPengguna ?? 'Pengguna'}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klinik Rawat Jalan'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang di Aplikasi Klinik Rawat Jalan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    greetingText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            // IMAGE SLIDER
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        banners[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Text('Gambar tidak tersedia'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Layanan Klinik',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // GRID MENU
            GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _menu('Buat Janji', Icons.calendar_month, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuatJanjiPage()),
                  );
                }),
                if (_isAdmin) ...[
                  _menu('Pasien', Icons.people, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PasienPage()),
                    );
                  }),
                  _menu('Daftar Pasien', Icons.person_add_alt_1, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  }),
                ],
                _menu('Dokter', Icons.medical_information, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DataDokterPage()),
                  );
                }),
                _menu('Jadwal', Icons.schedule, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JadwalDokterPage()),
                  );
                }),
                if (_isAdmin)
                  _menu('Rekam Medis', Icons.folder_special, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminRekamMedisPage(),
                      ),
                    );
                  })
                else
                  _menu('Rekam Medis', Icons.folder_shared, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RekamMedisPage()),
                    );
                  }),
                _menu('Obat', Icons.medication, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ObatPage()),
                  );
                }),
                if (_isAdmin)
                  _menu('Kelola Antrian', Icons.rule_folder, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAntrianPage(),
                      ),
                    );
                  })
                else
                  _menu('Antrian', Icons.queue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AntrianPage()),
                    );
                  }),
                _menu('Laporan', Icons.bar_chart, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LaporanPage()),
                  );
                }),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _menu(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
