import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nik = TextEditingController();
  final nama = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  Future<void> _register() async {
    setState(() => loading = true);
    try {
      final res = await ApiService.register(
        nik.text.trim(),
        nama.text.trim(),
        pass.text,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Selesai')));
      if (res['status'] == 'success') Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Koneksi API gagal')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nik,
              decoration: const InputDecoration(labelText: 'NIK'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nama,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
