import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import 'auth_email_options.dart';
import 'auth_page_shell.dart';
import '../logic/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({this.startsGripped = false, super.key});

  final bool startsGripped;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with AuthSubmitMotion<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await submitWithPaw(
      () => auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        studentId: _studentIdController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );

    if (mounted && success) {
      context.go('/verify-email');
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final narrow = MediaQuery.sizeOf(context).width < 340;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF765C4B)),
      prefixIcon: Icon(icon, color: const Color(0xFFD6581F)),
      prefixIconConstraints: const BoxConstraints(minWidth: 42),
      filled: true,
      fillColor: const Color(0xFFFFFCF8),
      contentPadding: EdgeInsets.symmetric(
        horizontal: narrow ? 10 : 16,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF0DCCB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD6581F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD94B4B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD94B4B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().isLoading || isSubmitting;
    final narrow = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0),
      body: AuthPageShell(
        isSubmitting: isSubmitting,
        scrollController: authScrollController,
        startsGripped: widget.startsGripped,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buat akun Meowtopia',
                style: TextStyle(
                  color: const Color(0xFF4B3325),
                  fontSize: narrow ? 21 : 25,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Gabung untuk ikut merawat kucing di lingkungan kampus.',
                style: TextStyle(
                  color: Color(0xFF765C4B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (!authEmailServicesEnabled) ...[
                const SizedBox(height: 12),
                const AuthEmailOptionsPreview(),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'Nama lengkap',
                  Icons.person_outline_rounded,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'Email pribadi atau kampus',
                  Icons.mail_outline_rounded,
                ),
                validator: (val) => val == null || !val.contains('@')
                    ? 'Email tidak valid'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _studentIdController,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'NIM (opsional)',
                  Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'Nomor WhatsApp',
                  Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'Kata sandi',
                  Icons.lock_outline_rounded,
                ),
                validator: (val) =>
                    val == null || val.length < 8 ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      busy || !authEmailServicesEnabled ? null : _onRegister,
                  icon: busy && !isSwitchingAuthPage
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Daftar sekarang'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!authEmailServicesEnabled) ...[
                const SizedBox(height: 8),
                const Text(
                  'Pendaftaran memerlukan verifikasi email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF765C4B), fontSize: 12),
                ),
              ],
              const SizedBox(height: 7),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun?',
                      style: TextStyle(color: Color(0xFF765C4B), fontSize: 13),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => switchAuthPage('/login'),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
