import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../logic/feeding_spot_provider.dart';

class ScanSpotPage extends StatefulWidget {
  const ScanSpotPage({super.key, this.expectedSpotId});
  final String? expectedSpotId;
  @override
  State<ScanSpotPage> createState() => _ScanSpotPageState();
}

class _ScanSpotPageState extends State<ScanSpotPage>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );
  bool _cameraEnabled = false;
  bool _busy = false;
  bool _torch = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraEnabled) return;
    if (state == AppLifecycleState.inactive) _controller.stop();
    if (state == AppLifecycleState.resumed && !_busy) _controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openToken(String token) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<FeedingSpotProvider>().openSession(
        token,
        expectedSpotId: widget.expectedSpotId,
      );
      if (_cameraEnabled) await _controller.stop();
      if (mounted) context.pushReplacement('/feeding/record');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Bad state: ', '');
          _busy = false;
        });
      }
    }
  }

  Future<void> _manualInput() async {
    final input = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Masukkan token QR spot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gunakan token lengkap pada QR resmi. Nomor spot saja tidak dapat membuka sesi.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Token QR spot',
                hintText: 'SPOT:…',
              ),
              onSubmitted: (value) => Navigator.pop(dialog, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, input.text),
            child: const Text('Periksa QR'),
          ),
        ],
      ),
    );
    // Dispose after the dialog's exit animation has detached its text field.
    Future<void>.delayed(const Duration(milliseconds: 300), input.dispose);
    if (token != null && mounted) await _openToken(token);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();
    final selected = widget.expectedSpotId == null
        ? null
        : provider.spotById(widget.expectedSpotId!);
    return MeowPage(
      title: 'Pindai QR Spot',
      child: ListView(
        padding: MeowPage.scrollPadding(context, top: 0, bottom: 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 610,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _cameraEnabled
                        ? MobileScanner(
                            controller: _controller,
                            onDetect: (capture) {
                              if (capture.barcodes.isNotEmpty) {
                                final value = capture.barcodes.first.rawValue;
                                if (value != null) _openToken(value);
                              }
                            },
                            errorBuilder: (context, error) => Container(
                              color: MeowStyle.slate,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(24),
                              child: const Text(
                                'Kamera tidak tersedia atau izinnya ditolak. Periksa izin kamera, lalu coba lagi atau masukkan token QR.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            'assets/images/figma/spot-scan-background.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: Color(0x66303948)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Tutup pemindai',
                              style: IconButton.styleFrom(
                                backgroundColor: MeowStyle.slate,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/feeding'),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: MeowStyle.slate,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(120, 44),
                              ),
                              onPressed: !_cameraEnabled
                                  ? null
                                  : () async {
                                      try {
                                        await _controller.toggleTorch();
                                        if (mounted) {
                                          setState(() => _torch = !_torch);
                                        }
                                      } catch (_) {
                                        if (mounted) {
                                          setState(
                                            () => _error = 'Flash tidak tersedia di perangkat ini.',
                                          );
                                        }
                                      }
                                    },
                              icon: Icon(
                                _torch
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: MeowStyle.peach,
                                size: 18,
                              ),
                              label: Text(
                                _torch ? 'FLASH: ON' : 'FLASH: OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Panduan scan',
                              style: IconButton.styleFrom(
                                backgroundColor: MeowStyle.slate,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (dialog) => AlertDialog(
                                  title: const Text('Pindai QR spot resmi'),
                                  content: const Text(
                                    'Pastikan spot aktif dan QR terlihat jelas. QR kucing tidak berlaku untuk kegiatan pemberian makan. Jangan memindai foto QR milik orang lain.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialog),
                                      child: const Text('Mengerti'),
                                    ),
                                  ],
                                ),
                              ),
                              icon: const Icon(Icons.info_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        MeowPill(
                          _busy
                              ? 'MEMERIKSA QR…'
                              : _cameraEnabled
                              ? 'SIAP MEMINDAI'
                              : 'PRATINJAU PEMINDAI',
                          color: MeowStyle.orange,
                          foreground: Colors.white,
                          icon: Icons.circle,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: CustomPaint(
                              painter: _ScanFramePainter(),
                              child: Center(
                                child: Container(
                                  height: 2,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        MeowStyle.orange,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: MeowStyle.slate,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            selected == null
                                ? 'Arahkan kamera ke QR Code\ndi feeding spot resmi'
                                : 'Pindai QR untuk\n${selected.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const GlassCard(
                          color: MeowStyle.slate,
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              IconBubble(
                                Icons.qr_code_2_rounded,
                                color: Color(0xFF634633),
                                foreground: MeowStyle.peach,
                                size: 34,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'QR fisik terpasang pada shelter pakan atau dispenser resmi.',
                                  style: TextStyle(
                                    color: Color(0xFFE2E7FF),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: MeowStyle.slate,
                                  minimumSize: const Size(0, 48),
                                  side: BorderSide.none,
                                ),
                                onPressed: _busy ? null : _manualInput,
                                icon: const Icon(
                                  Icons.pin_outlined,
                                  color: MeowStyle.mint,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Input token manual',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filled(
                              tooltip: 'Aktifkan kamera pemindai',
                              style: IconButton.styleFrom(
                                backgroundColor: MeowStyle.orange,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () =>
                                  setState(() => _cameraEnabled = true),
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            FeedingError(_error!),
          ],
          const SizedBox(height: 18),
          if (!_cameraEnabled)
            MeowButton(
              label: 'Aktifkan kamera',
              icon: Icons.camera_alt_outlined,
              onPressed: () => setState(() => _cameraEnabled = true),
            ),
          if (provider.isDemo) ...[
            const SizedBox(height: 12),
            MeowButton(
              label: 'Coba QR contoh',
              icon: Icons.science_outlined,
              secondary: true,
              busy: _busy,
              onPressed: () =>
                  _openToken(selected?.qrToken ?? 'SPOT:FS-TULT-01'),
            ),
            const SizedBox(height: 10),
            const Text(
              'QR contoh membuka sesi lokal tanpa mengirim data ke server.',
              style: TextStyle(fontSize: 11, color: MeowStyle.brown),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class FeedingError extends StatelessWidget {
  const FeedingError(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: MeowStyle.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: MeowStyle.danger,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MeowStyle.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    const length = 28.0;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final sx = corner.dx < size.width / 2 ? 1.0 : -1.0;
      final sy = corner.dy < size.height / 2 ? 1.0 : -1.0;
      canvas.drawLine(corner, corner.translate(sx * length, 0), paint);
      canvas.drawLine(corner, corner.translate(0, sy * length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
