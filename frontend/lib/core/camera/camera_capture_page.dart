import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../constants/app_constants.dart';
import '../widgets/loading_indicator.dart';

enum CameraCaptureMode {
  cameraOnly, // Acumalaka (Feeding) & E-Nigma (Adoption) - no gallery allowed
  photoVideo, // Optimind (Emergency Incident)
}

class CameraCapturePage extends StatefulWidget {
  final CameraCaptureMode mode;
  final int maxFiles;
  final String purpose;

  const CameraCapturePage({
    super.key,
    this.mode = CameraCaptureMode.cameraOnly,
    this.maxFiles = 3,
    required this.purpose,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isUploading = false;
  final List<String> _capturedMediaIds = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: widget.mode == CameraCaptureMode.photoVideo,
        );
        await _controller!.initialize();
        if (mounted) setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isUploading) return;

    try {
      final XFile photo = await _controller!.takePicture();
      setState(() => _isUploading = true);

      if (mounted) {
        setState(() {
          _isUploading = false;
          _capturedMediaIds.add(photo.path);
        });

        if (_capturedMediaIds.length >= widget.maxFiles) {
          Navigator.pop(context, _capturedMediaIds);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(message: 'Membuka kamera...')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Ambil Foto (${_capturedMediaIds.length}/${widget.maxFiles})',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_capturedMediaIds.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, _capturedMediaIds),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(child: LoadingIndicator(message: 'Mengunggah foto...')),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 48),
                FloatingActionButton.large(
                  onPressed: _takePicture,
                  backgroundColor: AppConstants.primaryColor,
                  child: const Icon(Icons.camera_alt, size: 36, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
                  onPressed: () {
                    // Switch camera front/back
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
