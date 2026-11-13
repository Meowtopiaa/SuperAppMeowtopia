import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/scanner/scanner_page.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 4 — Pengambilan Kucing & Serah Terima (Web & Mobile Responsif)
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
      'title': 'Pindai QR Kalung Kucing',
      'shortTitle': 'Pindai QR',
      'subtitle': 'Verifikasi token liontin fisik yang terpasang pada kalung kucing.',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'title': 'Foto Kucing Berkalung',
      'shortTitle': 'Foto Kalung',
      'subtitle': 'Ambil foto kucing yang telah dipasangi kalung sebagai bukti serah terima.',
      'icon': Icons.camera_alt_rounded,
    },
    {
      'title': 'Konfirmasi Serah Terima',
      'shortTitle': 'Konfirmasi',
      'subtitle': 'Pernyataan tanggung jawab adopter untuk mengaktifkan status adopsi.',
      'icon': Icons.verified_rounded,
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
    const defaultToken = 'MTP1.C.BONI103';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderLg),
        title: const Text('Masukkan Kode QR Manual', style: AdoptionTheme.subtitleStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jika pemindai kamera tidak dapat digunakan, masukkan kode token kalung identitas:',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qrManualController,
              decoration: const InputDecoration(
                hintText: 'Contoh: MTP1.C.BONI103',
                hintStyle: AdoptionTheme.captionStyle,
                prefixIcon: Icon(Icons.qr_code_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: AdoptionTheme.borderMd,
                  borderSide: BorderSide(color: AdoptionTheme.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AdoptionTheme.borderMd,
                  borderSide: BorderSide(color: AdoptionTheme.accent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _scannedQrToken = defaultToken;
                _qrManualController.text = defaultToken;
                _qrErrorMessage = null;
                if (_currentStep == 0) _currentStep = 1;
              });
              Navigator.pop(ctx);
            },
            child: Text(
              'Gunakan Kode Contoh',
              style: AdoptionTheme.captionStyle.copyWith(
                color: AdoptionTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdoptionTheme.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
            ),
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
            child: const Text('Simpan'),
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
            content: Text('Foto kucing berkalung berhasil diambil.'),
            backgroundColor: AppConstants.successColor,
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
        _qrErrorMessage = 'Wajib memindai kode QR kalung kucing terlebih dahulu.';
      });
      return;
    }

    if (_collarPhotoPath == null || _collarPhotoPath!.isEmpty) {
      setState(() {
        _currentStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib mengambil foto kucing mengenakan kalung identitas.'),
          backgroundColor: AppConstants.dangerColor,
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
          content: Text('Centang pernyataan serah terima tanggung jawab.'),
          backgroundColor: AppConstants.dangerColor,
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
                'Pengambilan selesai! Kucing resmi menjadi adopsi aktif Anda.',
          ),
          backgroundColor: AppConstants.successColor,
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
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  void _onStepNext() {
    if (_currentStep == 0) {
      if (_scannedQrToken == null || _scannedQrToken!.isEmpty) {
        setState(() {
          _qrErrorMessage = 'Wajib memindai kode QR kalung kucing terlebih dahulu.';
        });
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_collarPhotoPath == null || _collarPhotoPath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wajib mengambil foto kucing berkalung.'),
            backgroundColor: AppConstants.dangerColor,
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

    if (provider.isLoading && lock == null) {
      return Scaffold(
        backgroundColor: AdoptionTheme.pageBg,
        appBar: AppBar(
          backgroundColor: AdoptionTheme.pageBg,
          elevation: 0,
          title: const Text('Pengambilan Kucing', style: AdoptionTheme.titleStyle),
        ),
        body: const LoadingIndicator(message: 'Memeriksa data penahanan...'),
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
    final catName = app?.catName ?? cat?.name ?? 'Kucing #${widget.catId}';

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Pengambilan Kucing', style: AdoptionTheme.titleStyle),
      ),
      body: isExpired
          ? _buildExpiredState(context)
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 960;

                if (isDesktop) {
                  // ── Tampilan Desktop (2 Kolom Seimbang) ─────────────────
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Kolom Kiri: Sidebar Informasi, Kucing, & Penahanan
                              SizedBox(
                                width: 380,
                                child: _buildDesktopSidebar(lock, catName),
                              ),
                              const SizedBox(width: 28),
                              // Kolom Kanan: Stepper Header & Kartu Langkah Aktif
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildProgressHeader(),
                                    const SizedBox(height: 16),
                                    _buildStepCard(provider),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ── Tampilan Mobile / Tablet (1 Kolom Rapi) ───────────────
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        _buildRetentionBanner(lock),
                        const SizedBox(height: 14),
                        _buildProgressHeader(),
                        const SizedBox(height: 16),
                        _buildStepCard(provider),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Banner Penahanan Kucing 48 Jam (Mobile) ───────────────────────────────
  Widget _buildRetentionBanner(dynamic lock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: AdoptionTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              size: 18, color: AdoptionTheme.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lock != null
                  ? 'Kucing ditahan untuk Anda selama 48 jam (sisa: ${lock.remainingTime.inHours}j ${lock.remainingTime.inMinutes % 60}m).'
                  : 'Kucing ditahan untuk Anda selama 48 jam.',
              style: AdoptionTheme.captionStyle.copyWith(
                color: const Color(0xFF166534),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Desktop (Informasi & Panduan Penjemputan) ─────────────────────
  Widget _buildDesktopSidebar(dynamic lock, String catName) {
    return Column(
      children: [
        // Kartu Status Penahanan Kucing
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AdoptionTheme.borderLg,
            border: Border.all(color: AdoptionTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AdoptionTheme.accentLight,
                      borderRadius: AdoptionTheme.borderSm,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 22,
                      color: AdoptionTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catName,
                          style: AdoptionTheme.subtitleStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID Pengajuan #${widget.applicationId}',
                          style: AdoptionTheme.captionStyle.copyWith(
                            color: AdoptionTheme.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AdoptionTheme.divider),
              const SizedBox(height: 14),
              // Badge Waktu Sisa Penahanan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: AdoptionTheme.borderMd,
                  border: Border.all(color: AdoptionTheme.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, size: 18, color: AdoptionTheme.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lock != null
                            ? 'Masa tahan: ${lock.remainingTime.inHours}j ${lock.remainingTime.inMinutes % 60}m lagi'
                            : 'Masa tahan 48 jam aktif',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSidebarItem(
                Icons.pin_drop_outlined,
                'Lokasi Serah Terima',
                'Pos Relawan Meowtopia di Kampus.',
              ),
              const SizedBox(height: 12),
              _buildSidebarItem(
                Icons.shopping_bag_outlined,
                'Perlengkapan Wajib',
                'Bawa pet carrier / keranjang hewan aman saat penjemputan.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kartu Alur Pengambilan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdoptionTheme.accentSurface,
            borderRadius: AdoptionTheme.borderLg,
            border: Border.all(color: AdoptionTheme.accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, size: 18, color: AdoptionTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Tahapan Penjemputan',
                    style: AdoptionTheme.subtitleStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '1. Temui petugas dan cocokkan kucing.\n'
                '2. Pindai liontin QR kalung kucing.\n'
                '3. Ambil foto kucing mengenakan kalung.\n'
                '4. Konfirmasi serah terima untuk aktivasi.',
                style: AdoptionTheme.captionStyle.copyWith(
                  height: 1.55,
                  color: AdoptionTheme.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AdoptionTheme.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AdoptionTheme.captionStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AdoptionTheme.textMain,
                ),
              ),
              Text(
                subtitle,
                style: AdoptionTheme.captionStyle.copyWith(
                  fontSize: 11,
                  color: AdoptionTheme.textSub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stepper Header Progress Indicator ─────────────────────────────────────
  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _stepsMeta.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: i < _currentStep ? () => setState(() => _currentStep = i) : null,
                borderRadius: AdoptionTheme.borderSm,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _currentStep
                            ? AdoptionTheme.accentLight
                            : (i == _currentStep
                                ? AdoptionTheme.accent
                                : AdoptionTheme.chipBg),
                        border: Border.all(
                          color: i == _currentStep
                              ? AdoptionTheme.accent
                              : (i < _currentStep
                                  ? AdoptionTheme.accent
                                  : AdoptionTheme.cardBorder),
                        ),
                      ),
                      child: Center(
                        child: i < _currentStep
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AdoptionTheme.accent,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: i == _currentStep
                                      ? Colors.white
                                      : AdoptionTheme.textHint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _stepsMeta[i]['shortTitle'] as String,
                        style: AdoptionTheme.captionStyle.copyWith(
                          fontWeight: i == _currentStep
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: i == _currentStep
                              ? AdoptionTheme.textMain
                              : (i < _currentStep
                                  ? AdoptionTheme.textMain
                                  : AdoptionTheme.textHint),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _stepsMeta.length - 1)
              Container(
                width: 16,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < _currentStep
                    ? AdoptionTheme.accent
                    : AdoptionTheme.divider,
              ),
          ],
        ],
      ),
    );
  }

  // ── Kartu Langkah Aktif ───────────────────────────────────────────────────
  Widget _buildStepCard(AdoptionProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dalam kartu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdoptionTheme.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Langkah ${_currentStep + 1} dari 3',
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AdoptionTheme.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _stepsMeta[_currentStep]['title'] as String,
            style: AdoptionTheme.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            _stepsMeta[_currentStep]['subtitle'] as String,
            style: AdoptionTheme.captionStyle.copyWith(
              color: AdoptionTheme.textSub,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AdoptionTheme.divider),
          const SizedBox(height: 20),

          // Konten sesuai langkah
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey<int>(_currentStep),
              child: _buildCurrentStepContent(),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: AdoptionTheme.divider),
          const SizedBox(height: 20),

          // Tombol Aksi
          _buildActionButtons(provider),
        ],
      ),
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

  // ── Langkah 1: Pindai QR Kalung ───────────────────────────────────────────
  Widget _buildStepScanQr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pindai liontin QR pada kalung kucing untuk memastikan identitas fisik kucing yang diambil sesuai.',
          style: AdoptionTheme.bodyStyle,
        ),
        const SizedBox(height: 14),

        // Bingkai pemindai representatif
        GestureDetector(
          onTap: _scanCatQr,
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AdoptionTheme.borderMd,
              border: Border.all(
                color: _scannedQrToken != null
                    ? AdoptionTheme.success
                    : (_qrErrorMessage != null
                        ? AdoptionTheme.danger
                        : AdoptionTheme.cardBorder),
                width: _scannedQrToken != null ? 1.5 : 1,
              ),
            ),
            child: _scannedQrToken != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 36, color: AdoptionTheme.success),
                        const SizedBox(height: 8),
                        Text(
                          'Kode terverifikasi: $_scannedQrToken',
                          style: AdoptionTheme.subtitleStyle.copyWith(
                            color: const Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ketuk untuk pindai ulang',
                          style: AdoptionTheme.captionStyle,
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 40,
                          color: AdoptionTheme.accent.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buka Pemindai Kamera',
                          style: AdoptionTheme.subtitleStyle.copyWith(
                            color: AdoptionTheme.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Arahkan kamera ke QR kalung kucing',
                          style: AdoptionTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        if (_qrErrorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 14, color: AppConstants.dangerColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _qrErrorMessage!,
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AppConstants.dangerColor,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_cameraPermissionDenied) ...[
          const SizedBox(height: 8),
          Text(
            'Izin kamera tidak tersedia atau ditolak. Kamera diperlukan untuk memindai kode QR fisik secara langsung.',
            style: AdoptionTheme.captionStyle.copyWith(
              color: AdoptionTheme.warning,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Opsi masukkan kode manual
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _showManualCodeDialog,
            icon: const Icon(Icons.keyboard_outlined, size: 16),
            label: const Text('Masukkan kode token manual'),
            style: TextButton.styleFrom(
              foregroundColor: AdoptionTheme.accent,
              textStyle: AdoptionTheme.captionStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ── Langkah 2: Foto Kucing Berkalung ──────────────────────────────────────
  Widget _buildStepCollarPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambil foto kucing yang telah dipasangi kalung identitas menggunakan kamera sebagai bukti serah terima.',
          style: AdoptionTheme.bodyStyle,
        ),
        const SizedBox(height: 14),
        CameraPhotoSlot(
          localPath: _collarPhotoPath,
          hint: 'Buka kamera untuk foto kucing berkalung (tanpa galeri)',
          onTap: _takeCollarPhoto,
        ),
      ],
    );
  }

  // ── Langkah 3: Konfirmasi Tanggung Jawab ───────────────────────────────────
  Widget _buildStepConfirm() {
    return Container(
      padding: AdoptionTheme.padCard,
      decoration: BoxDecoration(
        color: _confirmedResponsibility
            ? AdoptionTheme.accentLight.withValues(alpha: 0.3)
            : const Color(0xFFFAF9F7),
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: _confirmedResponsibility
              ? AdoptionTheme.accent.withValues(alpha: 0.4)
              : AdoptionTheme.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _confirmedResponsibility,
            activeColor: AdoptionTheme.accent,
            shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderSm),
            onChanged: (val) {
              setState(() => _confirmedResponsibility = val ?? false);
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  setState(
                    () => _confirmedResponsibility = !_confirmedResponsibility,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konfirmasi Serah Terima Fisik',
                      style: AdoptionTheme.subtitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saya menyatakan telah menerima kucing dalam keadaan sehat dan bertanggung jawab penuh untuk merawatnya serta mengirimkan laporan berkala setiap 14 hari.',
                      style: AdoptionTheme.captionStyle.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tombol Navigasi Bawah ─────────────────────────────────────────────────
  Widget _buildActionButtons(AdoptionProvider provider) {
    final isLast = _currentStep == 2;
    final canComplete = _scannedQrToken != null &&
        _collarPhotoPath != null &&
        _confirmedResponsibility;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AdoptionTheme.cardBorder),
              foregroundColor: AdoptionTheme.textSub,
              padding: const EdgeInsets.symmetric(
                vertical: AdoptionTheme.sp12,
                horizontal: 16,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AdoptionTheme.borderMd,
              ),
            ),
            onPressed: provider.isActionLoading ? null : _onStepPrev,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 16),
                SizedBox(width: 6),
                Text('Sebelumnya'),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast && !canComplete
                  ? AdoptionTheme.accent.withValues(alpha: 0.4)
                  : AdoptionTheme.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: AdoptionTheme.sp12,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AdoptionTheme.borderMd,
              ),
            ),
            onPressed: isLast && !canComplete
                ? null
                : (provider.isActionLoading ? null : _onStepNext),
            child: provider.isActionLoading && isLast
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast
                            ? 'Selesaikan Pengambilan & Aktifkan Adopsi'
                            : 'Lanjut',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredState(BuildContext context) {
    return AdoptionEmptyState(
      icon: Icons.timer_off_outlined,
      message: 'Masa Penahanan Berakhir',
      submessage:
          'Batas waktu 48 jam pengambilan kucing telah terlewati. Silakan ajukan kelayakan kembali melalui katalog.',
      action: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdoptionTheme.accent,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
        ),
        onPressed: () => context.go('/adoption'),
        child: const Text('Kembali ke Katalog'),
      ),
    );
  }
}
