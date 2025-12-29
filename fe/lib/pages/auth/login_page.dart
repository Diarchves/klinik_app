import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nikController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.login(
        nikController.text.trim(),
        passController.text,
      );
      if (res['status'] == 'success') {
        final id = res['id_pasien'] is int
            ? res['id_pasien'] as int
            : int.parse(res['id_pasien'].toString());
        final nama = res['nama']?.toString() ?? '';
        await SessionManager.saveLogin(id, nama);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Login gagal')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Koneksi API gagal')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nikController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nikController,
              decoration: const InputDecoration(labelText: 'NIK'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
