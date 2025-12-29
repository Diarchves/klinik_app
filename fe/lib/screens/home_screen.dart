import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/features/antrian_page.dart';
import '../pages/features/buat_janji_page.dart';
import '../pages/features/data_dokter_page.dart';
import '../utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool logged = false;
  bool demoMode = false;

  final PageController _pageController = PageController();

  final List<String> banners = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  @override
  void dispose() {
    _pageController.dispose(); // 🔴 WAJIB
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final isLogin = await SessionManager.isLogin();
    final nama = await SessionManager.getNama();

    setState(() {
      logged = isLogin;
      demoMode = nama == 'Demo Mode';
    });
  }

  Future<void> _openFeature(
    Widget page, {
    bool requireLogin = true,
  }) async {
    if (requireLogin && !await _ensureLogin()) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<bool> _ensureLogin() async {
    if (logged) return true;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (result == true) {
      await _checkLogin();
      return true;
    }
    return false;
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur "$featureName" masih dalam pengembangan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Klinik Rawat Jalan'),
            const SizedBox(width: 8),
            if (demoMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (logged)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await SessionManager.logout();
                _checkLogin();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: const Text(
                'Selamat Datang di Aplikasi Klinik Rawat Jalan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            // ===== IMAGE SLIDER =====
            SizedBox(
              height: 180,
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
                        errorBuilder: (_, __, ___) => Container(
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
              padding: EdgeInsets.all(16),
              child: Text(
                'Layanan Klinik',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // ===== GRID MENU =====
            GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _menu(
                  'Buat Janji',
                  Icons.calendar_month,
                  () => _openFeature(const BuatJanjiPage()),
                ),
                _menu(
                  'Pendaftaran Pasien',
                  Icons.person_add,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                ),
                _menu(
                  'Jadwal Dokter',
                  Icons.schedule,
                  () => _openFeature(
                    const DataDokterPage(),
                    requireLogin: false,
                  ),
                ),
                _menu(
                  'Antrian Saya',
                  Icons.list_alt,
                  () => _openFeature(const AntrianPage()),
                ),
                _menu(
                  'Riwayat Medis',
                  Icons.medical_services,
                  () => _showComingSoon('Riwayat Medis'),
                ),
                _menu(
                  'Resep & Obat',
                  Icons.medication,
                  () => _showComingSoon('Resep & Obat'),
                ),
                _menu(
                  'Pembayaran',
                  Icons.payment,
                  () => _showComingSoon('Pembayaran'),
                ),
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
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
