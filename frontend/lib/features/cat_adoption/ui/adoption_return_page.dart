import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../data/adoption_enums.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

//// Layar 7: pengembalian kucing (ADP-11, ADP-12).
class AdoptionReturnPage extends StatefulWidget {
  final int adoptionId;
  final String catName;

  const AdoptionReturnPage({
    super.key,
    required this.adoptionId,
    required this.catName,
  });

  @override
  State<AdoptionReturnPage> createState() => _AdoptionReturnPageState();
}

class _AdoptionReturnPageState extends State<AdoptionReturnPage> {
  final _reasonController = TextEditingController();
  ReturnReasonType _reasonType = ReturnReasonType.EMERGENCY;
  String? _evidencePhotoPath;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _takeEvidencePhoto() async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(
            mode: CameraCaptureMode.cameraOnly,
            maxFiles: 1,
            purpose: 'return_evidence',
          ),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _evidencePhotoPath = result.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _evidencePhotoPath =
              'mock://camera/return_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Future<void> _onRequestReturn() async {
    final provider = context.read<AdoptionProvider>();

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi alasan pengembalian dulu.'),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
      return;
    }

    final updated = await provider.requestReturn(
      adoptionId: widget.adoptionId,
      reasonType: _reasonType,
      reason: _reasonController.text.trim(),
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.actionSuccessMessage ??
                'Permohonan pengembalian terkirim.',
          ),
          backgroundColor: AdoptionTheme.success,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
    }
  }

  Future<void> _onSubmitEvidence() async {
    final provider = context.read<AdoptionProvider>();

    if (_evidencePhotoPath == null || _evidencePhotoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambil foto serah terima dulu.'),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
      return;
    }

    final updated = await provider.submitReturnEvidence(
      adoptionId: widget.adoptionId,
      returnEvidencePath: _evidencePhotoPath!,
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.actionSuccessMessage ??
                'Bukti terkirim. Menunggu pemeriksaan pengurus adopsi.',
          ),
          backgroundColor: AdoptionTheme.success,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AdoptionTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();
    final isReturnEnabled = provider.isReturnEnabled;

    final activeAdoption = provider.myActiveAdoptions.cast().firstWhere(
          (a) => a.id == widget.adoptionId,
          orElse: () => null,
        );

    final bool isEvidencePending =
        activeAdoption != null && activeAdoption.isReturnEvidencePending;
    final bool isApproved =
        activeAdoption != null && activeAdoption.isReturnApproved;
    final bool isRequested = activeAdoption != null &&
        activeAdoption.status == ActiveAdoptionStatus.RETURN_REQUESTED;

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Pengembalian', style: AdoptionTheme.titleStyle),
      ),
      body: AdoptionPageBody(
        children: [
          AdoptionHeader(
            overline: 'Pengembalian ${widget.catName}',
            title: 'Mengembalikan kucing',
            subtitle:
                'Adopsimu tetap aktif sampai pengurus adopsi memeriksa bukti serah terima.',
            icon: Icons.assignment_return_outlined,
          ),
          if (isEvidencePending)
            const AdoptionBanner(
              title: 'Menunggu pemeriksaan',
              message:
                  'Bukti serah terima sudah terkirim. Pengurus adopsi akan memeriksanya '
                  'sebelum adopsi ditutup.',
            )
          else if (isApproved)
            _buildEvidenceStep(provider)
          else if (isRequested)
            const AdoptionBanner(
              title: 'Permohonan terkirim',
              message:
                  'Pengurus adopsi sedang meninjau permohonanmu. Setelah disetujui, '
                  'kamu diminta mengunggah foto serah terima.',
            )
          else if (!isReturnEnabled)
            const AdoptionBanner(
              variant: 'warning',
              title: 'Belum bisa diajukan lewat aplikasi',
              message:
                  'Kebijakan dan titik pengembalian di kampus belum disahkan pengelola. '
                  'Kalau kucing butuh bantuan segera, gunakan Laporkan kendala.',
            )
          else
            _buildRequestStep(provider),
          const SizedBox(height: 16),
          const AdoptionSection(
            title: 'Ketentuan pengembalian',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleLine(
                  'Pengembalian biasa bisa diajukan setelah tiga bulan kalender sejak pengambilan.',
                ),
                _RuleLine(
                  'Sebelum tiga bulan, pengembalian hanya lewat jalur darurat dengan alasan yang jelas.',
                ),
                _RuleLine(
                  'Setelah pengembalian diverifikasi, ada masa tunggu 30 hari sebelum kamu bisa mengadopsi lagi.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStep(AdoptionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdoptionSection(
          title: 'Jenis pengembalian',
          child: Column(
            children: [
              _ReasonOption(
                title: 'Pengembalian biasa',
                description: 'Sudah lewat tiga bulan sejak pengambilan.',
                value: ReturnReasonType.NORMAL,
                groupValue: _reasonType,
                onChanged: (v) => setState(() => _reasonType = v),
              ),
              _ReasonOption(
                title: 'Pengembalian darurat',
                description: 'Belum tiga bulan, ada alasan mendesak.',
                value: ReturnReasonType.EMERGENCY,
                groupValue: _reasonType,
                onChanged: (v) => setState(() => _reasonType = v),
              ),
            ],
          ),
        ),
        AdoptionSection(
          title: 'Alasan',
          description: _reasonType == ReturnReasonType.EMERGENCY
              ? 'Ceritakan apa yang terjadi sehingga kucing perlu dikembalikan sekarang.'
              : 'Ceritakan alasan kamu mengembalikan kucing.',
          child: TextFormField(
            controller: _reasonController,
            maxLines: 4,
            style:
                AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
            decoration: const InputDecoration(
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
              filled: true,
              fillColor: AdoptionTheme.cardBg,
            ),
          ),
        ),
        AdoptionPrimaryButton(
          label: 'Kirim permohonan',
          isLoading: provider.isActionLoading,
          onPressed: provider.isActionLoading ? null : _onRequestReturn,
        ),
      ],
    );
  }

  Widget _buildEvidenceStep(AdoptionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdoptionBanner(
          variant: 'success',
          title: 'Permohonan disetujui',
          message:
              'Serahkan kucing ke pengurus adopsi, lalu foto saat serah terima.',
        ),
        const SizedBox(height: 24),
        AdoptionSection(
          title: 'Foto serah terima',
          child: CameraPhotoSlot(
            localPath: _evidencePhotoPath,
            hint: 'Ambil foto serah terima',
            onTap: _takeEvidencePhoto,
          ),
        ),
        AdoptionPrimaryButton(
          label: 'Kirim bukti',
          isLoading: provider.isActionLoading,
          onPressed: provider.isActionLoading ? null : _onSubmitEvidence,
        ),
      ],
    );
  }
}

class _ReasonOption extends StatelessWidget {
  final String title;
  final String description;
  final ReturnReasonType value;
  final ReturnReasonType groupValue;
  final ValueChanged<ReturnReasonType> onChanged;

  const _ReasonOption({
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: AdoptionTheme.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected ? AdoptionTheme.accent : AdoptionTheme.textHint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AdoptionTheme.bodyStyle.copyWith(
                        color: AdoptionTheme.textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(description, style: AdoptionTheme.captionStyle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String text;

  const _RuleLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AdoptionTheme.bodyStyle),
    );
  }
}
