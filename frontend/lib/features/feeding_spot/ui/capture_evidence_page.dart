import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_session.dart';

class CaptureEvidencePage extends StatefulWidget {
  const CaptureEvidencePage({super.key});
  @override
  State<CaptureEvidencePage> createState() => _CaptureEvidencePageState();
}

class _CaptureEvidencePageState extends State<CaptureEvidencePage>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _error;
  bool _capturing = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    final previous = _camera;
    _camera = null;
    if (previous != null) await previous.dispose();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('Kamera tidak ditemukan pada perangkat ini.');
      }
      if (!mounted || generation != _generation) return;
      final device = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        device,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _camera = controller;
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      setState(() => _error = null);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              'Kamera belum dapat dibuka. Izinkan akses kamera di pengaturan perangkat atau browser, lalu coba lagi.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _generation++;
      _camera?.dispose();
      _camera = null;
    }
    if (state == AppLifecycleState.resumed && _camera == null) _initialize();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing || !(_camera?.value.isInitialized ?? false)) return;
    setState(() => _capturing = true);
    try {
      final file = await _camera!.takePicture();
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw StateError(
          'Foto melebihi batas 10 MB. Ambil ulang dengan resolusi lebih rendah.',
        );
      }
      if (mounted) {
        Navigator.pop(
          context,
          FeedingEvidence(bytes: bytes, capturedAt: DateTime.now()),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Foto belum berhasil diambil. Coba ambil ulang.';
          _capturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => MeowPage(
    title: 'Ambil Bukti Foto',
    bottom: MeowButton(
      label: 'Ambil foto',
      icon: Icons.camera_alt_rounded,
      busy: _capturing,
      onPressed: _camera?.value.isInitialized == true ? _capture : null,
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Pastikan mangkuk dan pakan terlihat jelas. Foto diambil langsung dari kamera, tanpa galeri.',
            style: TextStyle(color: MeowStyle.brown, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: MeowStyle.slate,
                alignment: Alignment.center,
                width: double.infinity,
                child: _camera?.value.isInitialized == true
                    ? CameraPreview(_camera!)
                    : _error == null
                    ? const CircularProgressIndicator(color: MeowStyle.orange)
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ),
          if (_error != null)
            TextButton.icon(
              onPressed: _initialize,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
        ],
      ),
    ),
  );
}
