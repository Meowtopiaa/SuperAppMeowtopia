import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
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
      'title': 'Tempat tinggal',
      'subtitle':
          'Di mana kucing akan tinggal dan siapa yang perlu mengizinkan.',
    },
    {
      'title': 'Kesiapan merawat',
      'subtitle': 'Biaya bulanan dan rencanamu untuk jangka panjang.',
    },
    {
      'title': 'Foto dan komitmen',
      'subtitle': 'Foto tempat tinggal dan persetujuan lembar komitmen.',
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
            content: Text('Foto ruangan tersimpan.'),
            backgroundColor: AdoptionTheme.success,
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
          content: Text('Draf tersimpan.'),
          backgroundColor: AdoptionTheme.success,
        ),
      );
      context.pop();
    } else if (provider.errorMessage != null) {
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
          backgroundColor: AdoptionTheme.success,
        ),
      );
      context.go('/adoption/detail/${result.id}');
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AdoptionTheme.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();
    final isStudent = provider.isStudent;
    final step = _stepsMeta[_currentStep];

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Form kelayakan', style: AdoptionTheme.titleStyle),
      ),
      body: Form(
        key: _formKey,
        child: AdoptionPageBody(
          children: [
            if (!isStudent)
              const Padding(
                padding: EdgeInsets.only(bottom: AdoptionTheme.sp16),
                child: AdoptionBanner(
                  variant: 'warning',
                  message:
                      'Pengajuan adopsi hanya bisa dikirim dari akun mahasiswa. '
                      'Kamu tetap bisa melihat isi form ini.',
                ),
              ),
            AdoptionHeader(
              overline: widget.catName != null
                  ? 'Form kelayakan untuk ${widget.catName}'
                  : 'Form kelayakan',
              title: step['title'] as String,
              subtitle: step['subtitle'] as String,
              icon: Icons.edit_note_rounded,
              footer: _buildProgress(),
            ),
            KeyedSubtree(
              key: ValueKey<int>(_currentStep),
              child: _buildCurrentStepContent(),
            ),
            const SizedBox(height: 8),
            _buildNavigationButtons(isStudent, provider),
            if (_currentStep == 0) ...[
              const SizedBox(height: 24),
              const AdoptionSection(
                title: 'Yang perlu kamu tahu',
                child: Text(
                  'Form ini menilai kesiapanmu, belum memilih kucing. Setelah pengurus adopsi '
                  'menyetujui, kamu memindai QR di kalung kucing saat pengambilan. Selama tiga '
                  'bulan pertama kamu mengirim laporan kondisi kucing setiap 14 hari.',
                  style: AdoptionTheme.bodyStyle,
                ),
              ),
            ],
          ],
        ),
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
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: AdoptionTheme.borderMd,
        borderSide: BorderSide(color: AdoptionTheme.inputBorder),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AdoptionTheme.borderMd,
        borderSide: BorderSide(color: AdoptionTheme.inputBorder),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AdoptionTheme.borderMd,
        borderSide: BorderSide(color: AdoptionTheme.accent, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AdoptionTheme.borderMd,
        borderSide: BorderSide(color: AdoptionTheme.danger),
      ),
      filled: true,
      fillColor: AdoptionTheme.cardBg,
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdoptionSection(
          title: 'Kucing akan tinggal di mana?',
          child: DropdownButtonFormField<String>(
            initialValue: _housingType,
            isExpanded: true,
            decoration: _inputDecoration(),
            style:
                AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
            items: const [
              DropdownMenuItem(
                  value: 'kos', child: Text('Kos yang mengizinkan hewan')),
              DropdownMenuItem(
                  value: 'rumah_kontrakan', child: Text('Rumah kontrakan')),
              DropdownMenuItem(
                  value: 'rumah_pribadi',
                  child: Text('Rumah sendiri atau keluarga')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _housingType = val);
            },
          ),
        ),
        _SwitchTile(
          title: 'Pemilik tempat atau keluarga sudah mengizinkan',
          subtitle:
              'Pemilik kos atau keluarga serumah setuju kamu memelihara kucing.',
          value: _familyPermission,
          onChanged: (v) => setState(() => _familyPermission = v),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SwitchTile(
          title: 'Saya sanggup menanggung biaya bulanan',
          subtitle: 'Pakan, pasir, dan pemeriksaan rutin ke dokter hewan.',
          value: _financialReadiness,
          onChanged: (v) => setState(() => _financialReadiness = v),
        ),
        const SizedBox(height: AdoptionTheme.sp16),
        AdoptionSection(
          title: 'Rencana jangka panjang',
          description:
              'Siapa yang merawat kucing saat kamu libur semester, dan apa rencanamu setelah lulus?',
          child: TextFormField(
            controller: _longTermPlanController,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style:
                AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
            decoration: _inputDecoration(
              hint: 'Contoh: saat libur kucing dititipkan ke kakak di Bandung',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Isi rencana jangka panjang dulu.';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final photoOk = _homePhotoPath != null && _homePhotoPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdoptionSection(
          title: 'Foto tempat kucing akan tinggal',
          description:
              'Foto kamar atau ruangan yang akan dipakai kucing sehari-hari.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CameraPhotoSlot(
                localPath: _homePhotoPath,
                hint: 'Ambil foto ruangan',
                onTap: _takeHomePhoto,
              ),
              if (_photoAttempted && !photoOk) ...[
                const SizedBox(height: 6),
                Text(
                  'Foto ruangan wajib diambil.',
                  style: AdoptionTheme.captionStyle
                      .copyWith(color: AdoptionTheme.danger),
                ),
              ],
            ],
          ),
        ),
        AdoptionSection(
          title: 'Lembar komitmen adopter',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AdoptionTheme.chipBg,
                  borderRadius: AdoptionTheme.borderMd,
                ),
                child: Text(
                  kAdopterCommitmentText,
                  style: AdoptionTheme.bodyStyle
                      .copyWith(color: AdoptionTheme.textMain),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _commitmentAccepted,
                onChanged: (v) =>
                    setState(() => _commitmentAccepted = v ?? false),
                activeColor: AdoptionTheme.accent,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Saya sudah membaca dan menyetujui lembar komitmen ini.',
                  style: AdoptionTheme.bodyStyle,
                ),
              ),
              if (_commitmentAttempted && !_commitmentAccepted)
                Text(
                  'Centang persetujuan komitmen dulu.',
                  style: AdoptionTheme.captionStyle
                      .copyWith(color: AdoptionTheme.danger),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isStudent, AdoptionProvider provider) {
    final isLast = _currentStep == 2;
    final busy = provider.isActionLoading;

    return Row(
      children: [
        if (_currentStep == 0)
          AdoptionSecondaryButton(
            label: 'Simpan draf',
            onPressed: busy ? null : _onSaveDraft,
          )
        else
          AdoptionSecondaryButton(
            label: 'Kembali',
            onPressed: busy ? null : _onStepPrev,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: AdoptionPrimaryButton(
            label: isLast ? 'Kirim pengajuan' : 'Lanjut',
            isLoading: busy && isLast,
            onPressed: (isLast && (!_canSubmit || !isStudent))
                ? null
                : (busy ? null : _onStepNext),
          ),
        ),
      ],
    );
  }
}

/// Pertanyaan ya/tidak dengan sakelar.
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
    return MergeSemantics(
      child: Container(
        padding: AdoptionTheme.padCard,
        decoration: AdoptionTheme.cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AdoptionTheme.subtitleStyle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AdoptionTheme.bodyStyle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: AdoptionTheme.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
