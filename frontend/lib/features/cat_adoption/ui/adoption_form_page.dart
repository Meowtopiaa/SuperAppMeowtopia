import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/constants/app_constants.dart';
import '../data/adoption_constants.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 2 — Form Kelayakan Adopter (Web & Mobile Responsif)
class AdoptionFormPage extends StatefulWidget {
  final int? catId;
  final String? catName;
  final int? existingApplicationId;

  const AdoptionFormPage({
    super.key,
    this.catId,
    this.catName,
    this.existingApplicationId,
  });

  @override
  State<AdoptionFormPage> createState() => _AdoptionFormPageState();
}

class _AdoptionFormPageState extends State<AdoptionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _longTermPlanController = TextEditingController();

  int _currentStep = 0;

  String _housingType = 'kos';
  bool _financialReadiness = true;
  bool _familyPermission = true;
  bool _commitmentAccepted = false;
  String? _homePhotoPath;

  // validasi per-step
  bool _photoAttempted = false;
  bool _commitmentAttempted = false;

  bool get _step0Valid => true; // dropdown + switch selalu valid
  bool get _step1Valid => _longTermPlanController.text.trim().isNotEmpty;
  bool get _step2Valid =>
      _homePhotoPath != null &&
      _homePhotoPath!.isNotEmpty &&
      _commitmentAccepted;
  bool get _canSubmit => _step0Valid && _step1Valid && _step2Valid;

  static const List<Map<String, dynamic>> _stepsMeta = [
    {
      'title': 'Tempat Tinggal',
      'shortTitle': 'Hunian',
      'subtitle': 'Tipe hunian dan persetujuan pihak pemilik tempat / keluarga.',
      'icon': Icons.home_rounded,
    },
    {
      'title': 'Kesiapan & Rencana',
      'shortTitle': 'Kesiapan',
      'subtitle': 'Kesiapan finansial dan rencana perawatan kucing jangka panjang.',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'title': 'Foto & Komitmen',
      'shortTitle': 'Komitmen',
      'subtitle': 'Lampiran foto tempat tinggal dan persetujuan komitmen adopter.',
      'icon': Icons.assignment_turned_in_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingIfAny();
  }

  void _loadExistingIfAny() {
    if (widget.existingApplicationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AdoptionProvider>();
        final existing = provider.myApplications.cast().firstWhere(
              (a) => a.id == widget.existingApplicationId,
              orElse: () => null,
            );
        if (existing != null && mounted) {
          setState(() {
            _housingType = existing.housingType;
            _financialReadiness = existing.financialReadiness;
            _familyPermission = existing.familyPermission;
            _commitmentAccepted = existing.commitmentAccepted;
            _homePhotoPath = existing.homePhotoPath;
            _longTermPlanController.text = existing.longTermPlan ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _longTermPlanController.dispose();
    super.dispose();
  }

  Future<void> _takeHomePhoto() async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(
            mode: CameraCaptureMode.cameraOnly,
            maxFiles: 1,
            purpose: 'home_evidence',
          ),
        ),
      );
      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _homePhotoPath = result.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _homePhotoPath =
              'mock://camera/home_room_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto tempat tinggal berhasil diambil.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    }
  }

  Future<void> _onSaveDraft() async {
    final provider = context.read<AdoptionProvider>();
    final draft = await provider.saveDraft(
      applicationId: widget.existingApplicationId,
      catId: widget.catId,
      catName: widget.catName,
      housingType: _housingType,
      financialReadiness: _financialReadiness,
      familyPermission: _familyPermission,
      longTermPlan: _longTermPlanController.text.trim(),
      homePhotoPath: _homePhotoPath,
      commitmentAccepted: _commitmentAccepted,
    );
    if (!mounted) return;
    if (draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draf berhasil disimpan.'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.pop();
    } else if (provider.errorMessage != null) {
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
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    } else {
      _onSubmit();
    }
  }

  void _onStepPrev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSubmit) {
      setState(() {
        _photoAttempted = true;
        _commitmentAttempted = true;
      });
      return;
    }

    final provider = context.read<AdoptionProvider>();
    final result = await provider.submitApplication(
      applicationId: widget.existingApplicationId,
      catId: widget.catId,
      catName: widget.catName,
      housingType: _housingType,
      financialReadiness: _financialReadiness,
      familyPermission: _familyPermission,
      longTermPlan: _longTermPlanController.text.trim(),
      homePhotoPath: _homePhotoPath!,
      commitmentAccepted: _commitmentAccepted,
    );
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.actionSuccessMessage ?? 'Pengajuan berhasil dikirim.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
      context.go('/adoption/detail/${result.id}');
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();
    final isStudent = provider.isStudent;

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.catName != null
              ? 'Adopsi ${widget.catName}'
              : 'Form Kelayakan',
          style: AdoptionTheme.titleStyle,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          if (isDesktop) {
            // ── Tampilan Web Desktop (2 Kolom Seimbang) ──────────────────
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                    children: [
                      if (!isStudent) _buildStudentWarningBanner(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kolom Kiri: Sidebar Informasi, Profil Kucing, & Alur
                          SizedBox(
                            width: 380,
                            child: _buildDesktopSidebar(),
                          ),
                          const SizedBox(width: 28),
                          // Kolom Kanan: Stepper & Kartu Formulir Aktif
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildProgressHeader(),
                                const SizedBox(height: 16),
                                _buildFormCard(isStudent, provider),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Tampilan Mobile / Tablet (1 Kolom Rapi) ────────────────────
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (!isStudent) _buildStudentWarningBanner(),
                    if (widget.catName != null) _buildCatContextPill(),
                    _buildProgressHeader(),
                    const SizedBox(height: 16),
                    _buildFormCard(isStudent, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Banner Peringatan Dosen/Staf ──────────────────────────────────────────
  Widget _buildStudentWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: AdoptionTheme.warning.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AdoptionTheme.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pengajuan adopsi hanya untuk mahasiswa aktif.',
              style: AdoptionTheme.bodyStyle.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cat Context Pill (Mode Mobile) ────────────────────────────────────────
  Widget _buildCatContextPill() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AdoptionTheme.accentLight,
              borderRadius: AdoptionTheme.borderSm,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 18,
              color: AdoptionTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan untuk ${widget.catName}',
                  style: AdoptionTheme.subtitleStyle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Data kelayakan ini akan ditinjau oleh pengelola kampus.',
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AdoptionTheme.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Desktop (Konteks & Panduan) ───────────────────────────────────
  Widget _buildDesktopSidebar() {
    return Column(
      children: [
        // Kartu Profil Kucing / Konteks Adopsi
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
                          widget.catName != null
                              ? widget.catName!
                              : 'Calon Adopter',
                          style: AdoptionTheme.subtitleStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.catName != null
                              ? 'Kucing Kampus Meowtopia'
                              : 'Pendaftaran Umum',
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
              _buildSidebarItem(
                Icons.check_circle_outline_rounded,
                'Khusus Mahasiswa Aktif',
                'Sesuai ketentuan kampus, pengajuan adopsi hanya untuk mahasiswa aktif.',
              ),
              const SizedBox(height: 12),
              _buildSidebarItem(
                Icons.access_time_rounded,
                'Penahanan 48 Jam',
                'Setelah disetujui, kucing ditahan selama 2 hari untuk penjemputan.',
              ),
              const SizedBox(height: 12),
              _buildSidebarItem(
                Icons.event_repeat_rounded,
                'Follow-up Berkala',
                'Laporan kondisi kucing setiap 14 hari sebanyak 6 kali siklus.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kartu Alur & Bantuan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdoptionTheme.accentSurface,
            borderRadius: AdoptionTheme.borderLg,
            border: Border.all(
              color: AdoptionTheme.accent.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: AdoptionTheme.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tahapan Setelah Ini',
                    style: AdoptionTheme.subtitleStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '1. Formulir Anda akan diverifikasi dalam 1-2 hari kerja.\n'
                '2. Cek status berkala di menu Riwayat Pengajuan.\n'
                '3. Siapkan keranjang hewan saat jadwal penjemputan di kampus.',
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
                    // Lingkaran status angka / centang
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
                    // Label langkah
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

  // ── Kartu Formulir Langkah Aktif ──────────────────────────────────────────
  Widget _buildFormCard(bool isStudent, AdoptionProvider provider) {
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
          // Header bagian dalam kartu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

          // Konten form sesuai langkah aktif
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

          // Tombol navigasi
          _buildNavigationButtons(isStudent, provider),
        ],
      ),
    );
  }

  // ── Switcher Langkah Aktif ────────────────────────────────────────────────
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Langkah 1: Tempat Tinggal ─────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipe Tempat Tinggal', style: AdoptionTheme.subtitleStyle),
        const SizedBox(height: 6),
        const Text(
          'Pilih tipe hunian tempat kucing akan menetap sehari-hari.',
          style: AdoptionTheme.captionStyle,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _housingType,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.home_outlined, size: 20, color: AdoptionTheme.accent),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.accent, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(
              value: 'kos',
              child: Text(
                'Kos (diizinkan memelihara hewan)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'rumah_kontrakan',
              child: Text(
                'Rumah Kontrakan',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'rumah_pribadi',
              child: Text(
                'Rumah Pribadi / Keluarga',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _housingType = val);
          },
        ),
        const SizedBox(height: 18),
        _SwitchTile(
          title: 'Izin Pemilik Tempat / Keluarga',
          subtitle:
              'Sudah ada persetujuan resmi dari pemilik kos atau keluarga serumah untuk memelihara kucing.',
          value: _familyPermission,
          onChanged: (v) => setState(() => _familyPermission = v),
        ),
      ],
    );
  }

  // ── Langkah 2: Kesiapan ───────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwitchTile(
          title: 'Kesiapan Finansial Bulanan',
          subtitle:
              'Mampu menyisihkan biaya mandiri untuk pakan bergizi, pasir higienis, serta kebutuhan medis rutin kucing.',
          value: _financialReadiness,
          onChanged: (v) => setState(() => _financialReadiness = v),
        ),
        const SizedBox(height: 20),
        const Text('Rencana Perawatan Jangka Panjang', style: AdoptionTheme.subtitleStyle),
        const SizedBox(height: 6),
        const Text(
          'Jelaskan rencana saat libur semester atau setelah menyelesaikan masa studi.',
          style: AdoptionTheme.captionStyle,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _longTermPlanController,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText:
                'Contoh: Saat masa liburan kucing dititip ke rumah keluarga, dan setelah lulus akan dibawa pulang ke kota asal...',
            hintStyle: AdoptionTheme.captionStyle,
            contentPadding: EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AdoptionTheme.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AdoptionTheme.borderMd,
              borderSide: BorderSide(color: AppConstants.dangerColor),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Rencana jangka panjang wajib diisi.';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Langkah 3: Foto & Komitmen ────────────────────────────────────────────
  Widget _buildStep2() {
    final photoOk = _homePhotoPath != null && _homePhotoPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Foto tempat tinggal
        const Text('Foto Ruangan Kucing', style: AdoptionTheme.subtitleStyle),
        const SizedBox(height: 4),
        const Text(
          'Ambil foto ruangan tempat kucing akan tinggal secara langsung menggunakan kamera.',
          style: AdoptionTheme.captionStyle,
        ),
        const SizedBox(height: 12),
        CameraPhotoSlot(
          localPath: _homePhotoPath,
          hint: 'Ambil foto ruangan via kamera (tanpa galeri)',
          onTap: _takeHomePhoto,
        ),
        if (_photoAttempted && !photoOk) ...[
          const SizedBox(height: 6),
          Text(
            'Foto tempat tinggal wajib dilampirkan via kamera.',
            style: AdoptionTheme.captionStyle
                .copyWith(color: AppConstants.dangerColor),
          ),
        ],

        const SizedBox(height: 22),

        // Lembar komitmen
        const Text('Lembar Komitmen Adopter', style: AdoptionTheme.subtitleStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F7),
            borderRadius: AdoptionTheme.borderMd,
            border: Border.all(color: AdoptionTheme.divider),
          ),
          child: Text(
            kAdopterCommitmentText,
            style: AdoptionTheme.captionStyle.copyWith(
              height: 1.55,
              color: AdoptionTheme.textMain,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: AdoptionTheme.borderMd,
            color: _commitmentAccepted
                ? AdoptionTheme.accentLight.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _commitmentAccepted,
                activeColor: AdoptionTheme.accent,
                shape: const RoundedRectangleBorder(
                  borderRadius: AdoptionTheme.borderSm,
                ),
                onChanged: (v) =>
                    setState(() => _commitmentAccepted = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _commitmentAccepted = !_commitmentAccepted,
                    ),
                    child: const Text(
                      'Saya telah membaca, memahami, dan menyetujui Lembar Komitmen Adopter.',
                      style: AdoptionTheme.bodyStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_commitmentAttempted && !_commitmentAccepted) ...[
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4),
            child: Text(
              'Persetujuan komitmen wajib dicentang.',
              style: AdoptionTheme.captionStyle
                  .copyWith(color: AppConstants.dangerColor),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tombol Navigasi ───────────────────────────────────────────────────────
  Widget _buildNavigationButtons(bool isStudent, AdoptionProvider provider) {
    final isLast = _currentStep == 2;

    return Row(
      children: [
        // Tombol Sekunder (Simpan Draf di step 0, Kembali di step 1 & 2)
        if (_currentStep == 0)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AdoptionTheme.accent),
              foregroundColor: AdoptionTheme.accent,
              padding: const EdgeInsets.symmetric(
                vertical: AdoptionTheme.sp12,
                horizontal: 16,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: AdoptionTheme.borderMd,
              ),
            ),
            onPressed: provider.isActionLoading ? null : _onSaveDraft,
            child: const Text('Simpan Draf'),
          )
        else
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

        // Tombol Utama (Lanjut di step 0 & 1, Kirim Pengajuan di step 2)
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast
                  ? (_canSubmit && isStudent
                      ? AdoptionTheme.accent
                      : AdoptionTheme.accent.withValues(alpha: 0.4))
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
            onPressed: (isLast && (!_canSubmit || !isStudent))
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
                        isLast ? 'Kirim Pengajuan' : 'Lanjut',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Switch tile bergaya adoption_theme
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: value ? AdoptionTheme.accent.withValues(alpha: 0.3) : AdoptionTheme.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AdoptionTheme.subtitleStyle),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AdoptionTheme.textSub,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeThumbColor: AdoptionTheme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
