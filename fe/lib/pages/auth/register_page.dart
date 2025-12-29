import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nik = TextEditingController();
  final nama = TextEditingController();
  final pass = TextEditingController();
  final tanggalLahir = TextEditingController();
  final alamat = TextEditingController();
  final noTelepon = TextEditingController();
  bool loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final res = await ApiService.register(
        nik: nik.text.trim(),
        nama: nama.text.trim(),
        password: pass.text,
        tanggalLahir: tanggalLahir.text.trim(),
        alamat: alamat.text.trim(),
        noTelepon: noTelepon.text.trim(),
      );
      final message = res['message']?.toString() ?? 'Registrasi berhasil';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Tidak dapat terhubung ke server');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pasien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nik,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'NIK'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIK wajib diisi';
                  }
                  if (value.length < 8) {
                    return 'NIK minimal 8 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nama,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: pass,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password wajib diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: tanggalLahir,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  hintText: 'YYYY-MM-DD (opsional)',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 3650)),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    tanggalLahir.text = picked.toIso8601String().split('T').first;
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: alamat,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap (opsional)',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: noTelepon,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _register,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
