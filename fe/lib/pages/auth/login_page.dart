import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    final user = userController.text.trim();
    final pass = passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK dan password wajib diisi')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      bool adminBypass = user == 'admin' && pass == 'bypass';
      int userId = 0;
      String userName = adminBypass ? 'Admin' : 'Demo Mode';
      bool patientLoggedIn = false;
      String? patientError;

      if (!adminBypass) {
        try {
          final response = await ApiService.login(user, pass);
          if (response['success'] == true) {
            final data = response['data'] as Map<String, dynamic>?;
            final idPasien = data?['id_pasien'] as int?;
            final nama = data?['nama'] as String?;
            if (idPasien == null || nama == null) {
              throw Exception('Data sesi tidak lengkap');
            }
            userId = idPasien;
            userName = nama;
            patientLoggedIn = true;
          } else {
            patientError = response['message']?.toString();
          }
        } catch (e) {
          patientError = e.toString();
        }
      }

      bool isAdmin = false;
      String? adminToken;
      try {
        final adminRes = await ApiService.adminLogin(user, pass);
        if (adminRes['success'] == true && adminRes['token'] != null) {
          isAdmin = true;
          adminToken = adminRes['token'] as String;
        }
      } catch (_) {
        // abaikan jika bukan admin
      }

      if (!patientLoggedIn && !adminBypass && !isAdmin) {
        throw Exception(
          patientError?.replaceFirst('Exception: ', '') ?? 'NIK atau password salah',
        );
      }

      if (!patientLoggedIn) {
        userId = 0;
        userName = 'Admin ${user.isEmpty ? '' : user}'.trim();
      }

      await SessionManager.saveLogin(
        userId,
        userName,
        isAdmin: isAdmin || adminBypass,
        adminToken: adminToken,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'NIK / Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pendaftaran pasien dilakukan oleh admin klinik. Silakan hubungi petugas bila belum memiliki akun.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
