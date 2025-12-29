import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/buat_janji/buat_janji_page.dart';
import '../utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool logged = false;
  String nama = '';

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final l = await SessionManager.isLogin();
    final n = await SessionManager.getNama();
    setState(() {
      logged = l;
      nama = n ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Klinik'),
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
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _menuCard(context, Icons.calendar_month, 'Buat Janji', () async {
            final isLogin = await SessionManager.isLogin();
            if (!isLogin) {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              if (res == true) _checkLogin();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuatJanjiPage()),
            );
          }),
          _menuCard(
            context,
            Icons.person,
            'Register',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
          ),
          if (logged) Center(child: Text('Halo, $nama')),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}
