import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../logic/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted && success) {
      context.go('/home');
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    width: 120,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets,
                      size: 80,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppConstants.appTagline,
                    style: TextStyle(color: AppConstants.textSecondary),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Kampus / SSO',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) => val == null || !val.contains('@')
                        ? 'Masukkan email valid'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (val) => val == null || val.length < 6
                        ? 'Sandi minimal 6 karakter'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Masuk Sekarang',
                    isLoading: auth.isLoading,
                    onPressed: _onLogin,
                    icon: Icons.login,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      'Belum punya akun? Daftar Mahasiswa di sini',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
