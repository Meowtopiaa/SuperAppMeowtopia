import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import 'auth_email_options.dart';
import 'auth_page_shell.dart';
import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart';
import '../logic/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.startsGripped = false, super.key});

  final bool startsGripped;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with AuthSubmitMotion<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useOtp = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  static Future<void>? _googleInitialization;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleEvents;
  Future<void>? _webGoogleReady;
  bool _choosingGoogleAccount = false;

  static const _webGoogleClientId = AppConstants.googleClientId != ''
      ? AppConstants.googleClientId
      : AppConstants.googleServerClientId;

  @override
  void initState() {
    super.initState();
    if (authEmailServicesEnabled && kIsWeb && _webGoogleClientId.isNotEmpty) {
      _webGoogleReady = _prepareGoogleWeb();
    }
  }

  Future<void> _initializeGoogle() async {
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize(
        clientId: kIsWeb
            ? _webGoogleClientId
            : AppConstants.googleClientId.isEmpty
                ? null
                : AppConstants.googleClientId,
        serverClientId: kIsWeb ? null : AppConstants.googleServerClientId,
      ));
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  Future<void> _prepareGoogleWeb() async {
    await _initializeGoogle();
    if (!mounted) return;
    _googleEvents = GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn &&
          _isLoginOnTop &&
          !_otpSent) {
        unawaited(_completeGoogleLogin(event.user));
      }
    }, onError: (Object error) {
      if (_isLoginOnTop) {
        _showGoogleError(error);
      }
    });
  }

  bool get _isLoginOnTop =>
      mounted && ModalRoute.of(context)?.isCurrent == true;

  @override
  void dispose() {
    unawaited(_googleEvents?.cancel());
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showMessage('Masukkan alamat email yang valid.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final sent = await submitWithPaw(() => auth.requestEmailOtp(email));
    if (!mounted) return;
    if (sent) {
      setState(() => _otpSent = true);
      _showMessage('Jika email terdaftar, kode masuk sedang dikirim.');
    } else {
      _showMessage(auth.errorMessage ?? 'Kode OTP belum dapat dikirim.');
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await submitWithPaw(
      () => auth.loginWithEmailOtp(
        _emailController.text.trim(),
        _otpController.text.trim(),
      ),
    );
    if (!mounted) return;
    if (success) {
      context.go(auth.user?.emailVerified == true ? '/home' : '/verify-email');
    } else {
      _showMessage(auth.errorMessage ?? 'Kode OTP tidak sesuai.');
    }
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await submitWithPaw(
      () => auth.login(_emailController.text.trim(), _passwordController.text),
    );
    if (!mounted) return;
    if (success) {
      context.go(auth.user?.emailVerified == true ? '/home' : '/verify-email');
    } else {
      _showMessage(auth.errorMessage ?? 'Email atau kata sandi tidak sesuai.');
    }
  }

  Future<void> _loginWithGoogle() async {
    if (kIsWeb || AppConstants.googleServerClientId.isEmpty) {
      _showMessage(
          'Login Google belum dikonfigurasi. Gunakan email untuk masuk.');
      return;
    }
    if (_choosingGoogleAccount) return;
    setState(() => _choosingGoogleAccount = true);
    try {
      await _initializeGoogle();
      if (!mounted) return;
      final google = GoogleSignIn.instance;
      if (!google.supportsAuthenticate()) {
        _showMessage('Login Google tidak tersedia di perangkat ini.');
        return;
      }
      await _completeGoogleLogin(await google.authenticate());
    } catch (error) {
      if (mounted) _showGoogleError(error);
    } finally {
      if (mounted) setState(() => _choosingGoogleAccount = false);
    }
  }

  Future<void> _completeGoogleLogin(GoogleSignInAccount account) async {
    if (!mounted || isSubmitting) return;
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _showMessage('Google tidak memberikan token login. Coba lagi.');
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    final success = await submitWithPaw(() => auth.loginWithGoogle(idToken));
    if (!mounted) return;
    if (success) {
      context.go(auth.user?.emailVerified == true ? '/home' : '/verify-email');
    } else {
      _showMessage(auth.errorMessage ?? 'Login Google gagal.');
    }
  }

  void _showGoogleError(Object error) {
    if (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) {
      return;
    }
    _showMessage('Login Google gagal. Periksa koneksi dan konfigurasi akun.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
    final busy = context.watch<AuthProvider>().isLoading ||
        isSubmitting ||
        _choosingGoogleAccount;
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
                _otpSent ? 'Cek email kamu' : 'Masuk ke akunmu',
                style: TextStyle(
                  color: const Color(0xFF4B3325),
                  fontSize: narrow ? 21 : 25,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _otpSent
                    ? 'Masukkan kode 6 digit yang dikirim ke ${_emailController.text.trim()}.'
                    : authEmailServicesEnabled
                        ? 'Masuk untuk merawat dan menjelajah dunia kucing kampus.'
                        : 'Masuk dengan email dan kata sandi akunmu.',
                style: const TextStyle(
                  color: Color(0xFF765C4B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (authEmailServicesEnabled && !_otpSent) ...[
                if (_webGoogleReady != null)
                  SizedBox(
                    height: 52,
                    child: FutureBuilder<void>(
                      future: _webGoogleReady,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => setState(
                                      () =>
                                          _webGoogleReady = _prepareGoogleWeb(),
                                    ),
                            child:
                                const Text('Coba sambungkan kembali ke Google'),
                          );
                        }
                        if (snapshot.connectionState != ConnectionState.done ||
                            busy) {
                          return const Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) => Center(
                            child: buildGoogleWebButton(constraints.maxWidth),
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _loginWithGoogle,
                      icon: const AuthGoogleMark(),
                      label: const Text('Lanjutkan dengan Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B3325),
                        side: const BorderSide(color: Color(0xFFF0DCCB)),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: narrow ? 8 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: narrow ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFF0DCCB))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'atau dengan email',
                        style: TextStyle(
                          color: Color(0xFF846C5A),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFF0DCCB))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _emailController,
                enabled: !_otpSent,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _useOtp && !_otpSent
                    ? TextInputAction.done
                    : TextInputAction.next,
                style: const TextStyle(color: Color(0xFF4B3325)),
                decoration: _inputDecoration(
                  'Email pribadi atau kampus',
                  Icons.mail_outline_rounded,
                ),
                validator: (value) =>
                    value == null || !value.contains('@') || value.endsWith('@')
                        ? 'Masukkan alamat email yang valid'
                        : null,
              ),
              if (_otpSent) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4B3325),
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 11,
                  ),
                  decoration: _inputDecoration(
                    'Kode OTP',
                    Icons.password_rounded,
                  ).copyWith(counterText: ''),
                  validator: (value) => value == null || value.length != 6
                      ? 'Masukkan 6 digit kode OTP'
                      : null,
                ),
                const SizedBox(height: 14),
                _PrimaryButton(
                  text: 'Verifikasi & Masuk',
                  isLoading: busy,
                  onPressed: _verifyOtp,
                ),
                Center(
                  child: TextButton(
                    onPressed: busy ? null : _requestOtp,
                    child: const Text('Kirim ulang kode'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                            }),
                    child: const Text('Ganti alamat email'),
                  ),
                ),
              ] else ...[
                if (!_useOtp) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!busy) _loginWithPassword();
                    },
                    style: const TextStyle(color: Color(0xFF4B3325)),
                    decoration: _inputDecoration(
                      'Kata sandi',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFF765C4B),
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 8
                        ? 'Kata sandi minimal 8 karakter'
                        : null,
                  ),
                ],
                const SizedBox(height: 14),
                _PrimaryButton(
                  text: _useOtp
                      ? 'Kirim kode OTP ke email'
                      : 'Masuk ke Meowtopia',
                  isLoading: busy && !isSwitchingAuthPage,
                  onPressed: busy
                      ? null
                      : (_useOtp ? _requestOtp : _loginWithPassword),
                ),
                if (authEmailServicesEnabled)
                  Center(
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => _useOtp = !_useOtp),
                      child: Text(
                        _useOtp
                            ? 'Masuk dengan kata sandi'
                            : 'Gunakan kode OTP lewat email',
                      ),
                    ),
                  ),
              ],
              if (!authEmailServicesEnabled) ...[
                const SizedBox(height: 12),
                const AuthEmailOptionsPreview(),
              ],
              const SizedBox(height: 2),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(color: Color(0xFF765C4B), fontSize: 13),
                    ),
                    TextButton(
                      onPressed:
                          busy ? null : () => switchAuthPage('/register'),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              if (_useOtp || _otpSent)
                const Text(
                  'Kode OTP berlaku 15 menit. Jangan bagikan kepada siapa pun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF947D6C),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.text, required this.isLoading, required this.onPressed});

  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 340;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0x99F97316),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: narrow ? 12 : 14,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(text),
      ),
    );
  }
}
