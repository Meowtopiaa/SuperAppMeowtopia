import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../logic/identification_provider.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _cameraEnabled = false;
  bool _processing = false;
  bool _active = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    if (_active != active && _cameraEnabled) {
      if (active && !_processing) {
        _controller.start();
      } else {
        _controller.stop();
      }
    }
    _active = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraEnabled) return;
    if (state == AppLifecycleState.inactive) _controller.stop();
    if (state == AppLifecycleState.resumed && _active && !_processing) {
      _controller.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _identify(String rawToken) async {
    if (_processing) return;
    final token = rawToken.trim();
    if (!token.startsWith('MEOW-CAT-')) {
      setState(
        () => _error =
            'Gunakan QR resmi pada kalung kucing, bukan QR feeding spot.',
      );
      return;
    }
    setState(() {
      _processing = true;
      _error = null;
    });
    if (_cameraEnabled) await _controller.stop();
    if (!mounted) return;
    final provider = context.read<IdentificationProvider>();
    final success = await provider.identifyByQr(token);
    if (!mounted) return;
    if (success) {
      await context.push('/identify/result');
    } else {
      setState(
        () => _error =
            provider.errorMessage ??
            'Kucing belum dapat dikenali. Silakan coba lagi.',
      );
    }
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _manualInput() async {
    final input = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Token QR kalung'),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Token kucing',
            hintText: 'MEOW-CAT-…',
          ),
          onSubmitted: (value) => Navigator.pop(dialog, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, input.text),
            child: const Text('Kenali kucing'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 300), input.dispose);
    if (token != null && mounted) await _identify(token);
  }

  @override
  Widget build(BuildContext context) => MeowPage(
    back: false,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Kenali Kucing',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sapa teman berbulu di sekitarmu.',
          style: TextStyle(fontSize: 13, color: MeowStyle.brown),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _cameraEnabled
                      ? MobileScanner(
                          controller: _controller,
                          onDetect: (capture) {
                            if (capture.barcodes.isNotEmpty) {
                              final token = capture.barcodes.first.rawValue;
                              if (token != null) _identify(token);
                            }
                          },
                          errorBuilder: (context, error) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Kamera belum tersedia. Izinkan akses kamera atau gunakan token manual.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const ColoredBox(color: MeowStyle.slate),
                ),
                if (!_cameraEnabled)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 70,
                          color: MeowStyle.peach,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'QR di kalung kucing',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kamera akan aktif setelah kamu izinkan.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                const Positioned(
                  top: 16,
                  left: 16,
                  child: MeowPill(
                    'PINDAI KUCING',
                    color: MeowStyle.orange,
                    foreground: Colors.white,
                    icon: Icons.pets_rounded,
                  ),
                ),
                if (_processing)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: MeowStyle.orange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        MeowButton(
          label: _cameraEnabled ? 'Pindai ulang' : 'Aktifkan kamera',
          icon: Icons.qr_code_scanner_rounded,
          onPressed: _processing
              ? null
              : () {
                  if (_cameraEnabled) _controller.start();
                  setState(() {
                    _cameraEnabled = true;
                    _error = null;
                  });
                },
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _processing ? null : _manualInput,
          icon: const Icon(Icons.keyboard_alt_outlined),
          label: const Text('Masukkan token manual'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: const TextStyle(
                  color: MeowStyle.danger,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'Kalung tidak terbaca?',
                icon: Icons.pets_outlined,
              ),
              const SizedBox(height: 10),
              const Text(
                'Coba foto kucing atau jawab pertanyaan tentang ciri fisiknya.',
                style: TextStyle(
                  color: MeowStyle.brown,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              MeowButton(
                label: 'Kenali lewat foto',
                icon: Icons.photo_camera_outlined,
                secondary: true,
                onPressed: () => context.push('/identify/photo'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.push('/identify/question'),
                child: const Text('Jawab ciri fisik →'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
