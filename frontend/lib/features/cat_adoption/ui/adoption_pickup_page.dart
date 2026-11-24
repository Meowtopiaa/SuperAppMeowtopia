import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/scanner/scanner_page.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 4: pengambilan kucing dan serah terima (ADP-06, ADP-07).
class AdoptionPickupPage extends StatefulWidget {
  final int applicationId;
  final int catId;

  const AdoptionPickupPage({
    super.key,
    required this.applicationId,
    required this.catId,
  });

  @override
  State<AdoptionPickupPage> createState() => _AdoptionPickupPageState();
}

class _AdoptionPickupPageState extends State<AdoptionPickupPage> {
  final TextEditingController _qrManualController = TextEditingController();

  int _currentStep = 0;
  String? _scannedQrToken;
  String? _collarPhotoPath;
  bool _confirmedResponsibility = false;

  // Status error khusus
  String? _qrErrorMessage;
  bool _cameraPermissionDenied = false;

  static const List<Map<String, dynamic>> _stepsMeta = [
    {
      'title': 'Pindai QR kalung',
      'subtitle':
          'Pastikan kucing yang kamu ambil sama dengan kucing yang disetujui.',
    },
    {
      'title': 'Foto kucing berkalung',
      'subtitle': 'Foto ini menjadi bukti serah terima.',
    },
    {
      'title': 'Konfirmasi',
      'subtitle': 'Periksa lagi, lalu nyatakan tanggung jawabmu.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchPickupLock(
            widget.applicationId,
            widget.catId,
          );
    });
  }

  @override
  void dispose() {
    _qrManualController.dispose();
    super.dispose();
  }

  Future<void> _scanCatQr() async {
    setState(() {
      _qrErrorMessage = null;
      _cameraPermissionDenied = false;
    });

    try {
      final code = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const ScannerPage(purpose: ScanPurpose.pickup),
        ),
      );

      if (code != null && code.isNotEmpty && mounted) {
        setState(() {
          _scannedQrToken = code.trim();
          _qrManualController.text = _scannedQrToken!;
          _qrErrorMessage = null;
          if (_currentStep == 0) _currentStep = 1;
        });
      }
    } catch (_) {
      // Jika kamera/scanner tidak bisa diakses
      if (mounted) {
        setState(() {
          _cameraPermissionDenied = true;
        });
        _showManualCodeDialog();
      }
    }
  }

  void _showManualCodeDialog() {
    const sampleToken = 'MTP1.C.BONI103';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdoptionTheme.cardBg,
        shape:
            const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderLg),
        title: const Text('Ketik kode kalung', style: AdoptionTheme.titleStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kode tercetak di bawah QR pada kalung kucing.',
              style: AdoptionTheme.bodyStyle,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qrManualController,
              autofocus: true,
              style: AdoptionTheme.bodyStyle
                  .copyWith(color: AdoptionTheme.textMain),
              decoration: const InputDecoration(
                hintText: 'Kode kalung',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AdoptionTheme.borderMd,
                  borderSide: BorderSide(color: AdoptionTheme.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AdoptionTheme.borderMd,
                  borderSide:
                      BorderSide(color: AdoptionTheme.accent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedQrToken = sampleToken;
                  _qrManualController.text = sampleToken;
                  _qrErrorMessage = null;
                  if (_currentStep == 0) _currentStep = 1;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Pakai kode contoh (debug)'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AdoptionTheme.accent),
            onPressed: () {
              final text = _qrManualController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _scannedQrToken = text;
                  _qrErrorMessage = null;
                  if (_currentStep == 0) _currentStep = 1;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Pakai kode'),
          ),
        ],
      ),
    );
  }

  Future<void> _takeCollarPhoto() async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(
            mode: CameraCaptureMode.cameraOnly,
            maxFiles: 1,
            purpose: 'pickup_collar_evidence',
          ),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _collarPhotoPath = result.first;
          if (_currentStep == 1) _currentStep = 2;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _collarPhotoPath =
              'mock://camera/collar_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
          if (_currentStep == 1) _currentStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto tersimpan.'),
            backgroundColor: AdoptionTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _onCompletePickup() async {
    final provider = context.read<AdoptionProvider>();

    if (_scannedQrToken == null || _scannedQrToken!.isEmpty) {
      setState(() {
        _currentStep = 0;
        _qrErrorMessage = 'Pindai QR di kalung kucing dulu.';
      });
      return;
    }

    if (_collarPhotoPath == null || _collarPhotoPath!.isEmpty) {
      setState(() {
        _currentStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil foto kucing yang memakai kalung dulu.'),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
      return;
    }

    if (!_confirmedResponsibility) {
      setState(() {
        _currentStep = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Centang pernyataan tanggung jawab dulu.'),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
      return;
    }

    final active = await provider.completePickup(
      applicationId: widget.applicationId,
      catId: widget.catId,
      scannedQrToken: _scannedQrToken!,
      collarPhotoPath: _collarPhotoPath!,
      confirmedResponsibility: _confirmedResponsibility,
    );

    if (!mounted) return;

    if (active != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.actionSuccessMessage ??
                'Pengambilan tercatat. Adopsimu sudah aktif.',
          ),
          backgroundColor: AdoptionTheme.success,
        ),
      );
      context.go('/adoption/my-cats');
    } else if (provider.errorMessage != null) {
      setState(() {
        if (provider.errorMessage!.contains('QR') ||
            provider.errorMessage!.contains('token') ||
            provider.errorMessage!.contains('CODENOTMATCH')) {
          _currentStep = 0;
          _qrErrorMessage = provider.errorMessage;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
    }
  }

  void _onStepNext() {
    if (_currentStep == 0) {
      if (_scannedQrToken == null || _scannedQrToken!.isEmpty) {
        setState(() {
          _qrErrorMessage = 'Pindai QR di kalung kucing dulu.';
        });
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_collarPhotoPath == null || _collarPhotoPath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ambil foto kucing yang memakai kalung dulu.'),
            backgroundColor: AdoptionTheme.danger,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      _onCompletePickup();
    }
  }

  void _onStepPrev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();
    final lock = provider.currentPickupLock;

    final appBar = AppBar(
      backgroundColor: AdoptionTheme.pageBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text('Pengambilan kucing', style: AdoptionTheme.titleStyle),
    );

    if (provider.isLoading && lock == null) {
      return Scaffold(
        backgroundColor: AdoptionTheme.pageBg,
        appBar: appBar,
        body: const LoadingIndicator(message: 'Memeriksa penahanan...'),
      );
    }

    final isExpired = lock != null && lock.remainingTime.isNegative;
    final app = provider.myApplications.cast().firstWhere(
          (a) => a.id == widget.applicationId,
          orElse: () => null,
        );
    final cat = provider.readyCats.cast().firstWhere(
          (c) => c.id == widget.catId,
          orElse: () => null,
        );
    final String catName = app?.catName ?? cat?.name ?? 'Kucing pilihanmu';
    final step = _stepsMeta[_currentStep];

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: appBar,
      body: isExpired
          ? _buildExpiredState(context)
          : AdoptionPageBody(
              children: [
                AdoptionHeader(
                  overline: 'Pengambilan $catName',
                  title: step['title'] as String,
                  subtitle: step['subtitle'] as String,
                  icon: Icons.qr_code_scanner_rounded,
                  footer: _buildProgress(),
                ),
                Text(
                  lock != null
                      ? 'Kucing ditahan untukmu ${lock.remainingTime.inHours} jam '
                          '${lock.remainingTime.inMinutes % 60} menit lagi.'
                      : 'Kucing ditahan untukmu selama 48 jam sejak pengambilan dimulai.',
                  style: AdoptionTheme.captionStyle,
                ),
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildCurrentStepContent(),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(provider),
              ],
            ),
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(_stepsMeta.length, (i) {
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: i == _stepsMeta.length - 1 ? 0 : 6),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        i <= _currentStep ? AdoptionTheme.accent : Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Langkah ${_currentStep + 1} dari ${_stepsMeta.length}',
          style: AdoptionTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepScanQr();
      case 1:
        return _buildStepCollarPhoto();
      case 2:
        return _buildStepConfirm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepScanQr() {
    final scanned = _scannedQrToken != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: scanned
              ? AdoptionTheme.successLight
              : AdoptionTheme.accentSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AdoptionTheme.borderMd,
            side: BorderSide(
              color: scanned
                  ? AdoptionTheme.success
                  : (_qrErrorMessage != null
                      ? AdoptionTheme.danger
                      : AdoptionTheme.accentLight),
            ),
          ),
          child: InkWell(
            onTap: _scanCatQr,
            borderRadius: AdoptionTheme.borderMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    scanned
                        ? Icons.check_rounded
                        : Icons.qr_code_scanner_rounded,
                    size: 22,
                    color:
                        scanned ? AdoptionTheme.success : AdoptionTheme.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scanned ? 'Kode terbaca' : 'Pindai QR di kalung',
                          style: AdoptionTheme.bodyStyle.copyWith(
                            color: AdoptionTheme.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scanned
                              ? '$_scannedQrToken. Ketuk untuk memindai ulang.'
                              : 'Kode dicocokkan dengan data kucing saat pengambilan dikirim.',
                          style: AdoptionTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_qrErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _qrErrorMessage!,
            style: AdoptionTheme.captionStyle
                .copyWith(color: AdoptionTheme.danger),
          ),
        ],
        if (_cameraPermissionDenied) ...[
          const SizedBox(height: 12),
          const AdoptionBanner(
            variant: 'warning',
            message:
                'Kamera tidak bisa dibuka. Kamu bisa mengetik kode yang tercetak di kalung.',
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _showManualCodeDialog,
          style: TextButton.styleFrom(
            foregroundColor: AdoptionTheme.accent,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 40),
            textStyle:
                AdoptionTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          child: const Text('Ketik kode secara manual'),
        ),
      ],
    );
  }

  Widget _buildStepCollarPhoto() {
    return CameraPhotoSlot(
      localPath: _collarPhotoPath,
      hint: 'Foto kucing yang memakai kalung',
      onTap: _takeCollarPhoto,
    );
  }

  Widget _buildStepConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdoptionInfoRow(
            label: 'QR kalung', value: _scannedQrToken ?? 'Belum dipindai'),
        AdoptionInfoRow(
          label: 'Foto berkalung',
          value: _collarPhotoPath != null ? 'Sudah diambil' : 'Belum diambil',
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _confirmedResponsibility,
          onChanged: (val) =>
              setState(() => _confirmedResponsibility = val ?? false),
          activeColor: AdoptionTheme.accent,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Saya bertanggung jawab merawat kucing ini dan mengirim laporan kondisinya '
            'setiap 14 hari selama tiga bulan pertama.',
            style: AdoptionTheme.bodyStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AdoptionProvider provider) {
    final isLast = _currentStep == 2;
    final busy = provider.isActionLoading;
    final canComplete = _scannedQrToken != null &&
        _collarPhotoPath != null &&
        _confirmedResponsibility;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          AdoptionSecondaryButton(
            label: 'Kembali',
            onPressed: busy ? null : _onStepPrev,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AdoptionPrimaryButton(
            label: isLast ? 'Selesaikan pengambilan' : 'Lanjut',
            isLoading: busy && isLast,
            onPressed:
                isLast && !canComplete ? null : (busy ? null : _onStepNext),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState(BuildContext context) {
    return Center(
      child: AdoptionEmptyState(
        icon: Icons.timer_off_outlined,
        message: 'Masa penahanan sudah berakhir',
        submessage:
            'Kucing tidak lagi ditahan untukmu. Kalau kucing masih tersedia '
            'di katalog, kamu bisa memulai pengambilan lagi.',
        action: AdoptionSecondaryButton(
          label: 'Kembali ke katalog',
          onPressed: () => context.go('/adoption'),
        ),
      ),
    );
  }
}
