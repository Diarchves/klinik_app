import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      final response = await ApiService.login(
        nikController.text.trim(),
        passController.text,
      );
      final data = response['data'] as Map<String, dynamic>?;
      final id = data?['id_pasien'] as int?;
      final nama = data?['nama']?.toString();
      if (id == null || nama == null) {
        throw ApiException('Data login tidak lengkap');
      }
      await SessionManager.saveLogin(id, nama);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nikController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'NIK'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NIK wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _login,
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
