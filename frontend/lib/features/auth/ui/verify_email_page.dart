import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../logic/auth_provider.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final verified = await auth.verifyEmailOtp(_otpController.text.trim());
    if (!mounted) return;
    if (verified) {
      context.go('/home');
    } else {
      _message(auth.errorMessage ?? 'Kode tidak sesuai atau kedaluwarsa.');
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final sent = await auth.resendEmailOtp();
    if (!mounted) return;
    _message(sent
        ? 'Kode baru telah dikirim.'
        : auth.errorMessage ?? 'Kode belum dapat dikirim.');
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF11141C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Verifikasi email'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: const Color(0xFF20232D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          size: 44, color: Color(0xFFFF9C54)),
                      const SizedBox(height: 18),
                      const Text('Satu langkah lagi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan kode 6 digit yang kami kirim ke ${auth.user?.email ?? 'email kamu'}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFCFD0D6), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 12),
                        decoration: InputDecoration(
                          labelText: 'Kode OTP',
                          labelStyle: const TextStyle(color: Color(0xFFD0D1D7)),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .06),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0x33FFFFFF))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFFF9C54))),
                        ),
                        validator: (value) => value == null || value.length != 6
                            ? 'Masukkan kode 6 digit'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: auth.isLoading ? null : _verify,
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC65210)),
                          child: auth.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Verifikasi email',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: auth.isLoading ? null : _resend,
                          child: const Text('Kirim ulang kode',
                              style: TextStyle(color: Color(0xFFFFB27D))),
                        ),
                      ),
                      const Text('Kode berlaku selama 15 menit.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFFAEB0B8), fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
