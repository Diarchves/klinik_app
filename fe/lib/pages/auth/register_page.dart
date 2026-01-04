import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nik = TextEditingController();
  final nama = TextEditingController();
  final pass = TextEditingController();
  final tanggalLahir = TextEditingController();
  final alamat = TextEditingController();
  final telepon = TextEditingController();
  bool loading = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAccess();
    });
  }

  Future<void> _verifyAccess() async {
    final isAdmin = await SessionManager.isAdmin();
    if (!mounted) return;
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya admin yang dapat mendaftarkan pasien baru.')),
      );
      Navigator.pop(context);
    } else {
      setState(() => _checkingAccess = false);
    }
  }

  Future<void> _register() async {
    if (nik.text.trim().isEmpty || nama.text.trim().isEmpty || pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK, nama, dan password wajib diisi')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final res = await ApiService.register(
        nik: nik.text.trim(),
        nama: nama.text.trim(),
        password: pass.text,
        tanggalLahir: tanggalLahir.text.trim().isEmpty ? null : tanggalLahir.text.trim(),
        alamat: alamat.text.trim().isEmpty ? null : alamat.text.trim(),
        noTelepon: telepon.text.trim().isEmpty ? null : telepon.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Selesai')),
      );
      if (res['success'] == true) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi API gagal')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    nik.dispose();
    nama.dispose();
    pass.dispose();
    tanggalLahir.dispose();
    alamat.dispose();
    telepon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pasien')),
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nik,
                    decoration: const InputDecoration(labelText: 'NIK'),
                    keyboardType: TextInputType.number,
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: tanggalLahir,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: alamat,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: telepon,
                    decoration: const InputDecoration(labelText: 'No. Telepon'),
                    keyboardType: TextInputType.phone,
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
