import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/constants/app_constants.dart';
import '../data/adoption_enums.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 7 — Pengajuan Pengembalian Kucing (Web & Mobile Responsif)
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
            content: Text('Foto bukti serah terima berhasil diambil.'),
            backgroundColor: AppConstants.successColor,
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
          content: Text('Alasan pengembalian wajib diisi.'),
          backgroundColor: AppConstants.dangerColor,
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
                'Pengajuan pengembalian berhasil dikirim.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
    }
  }

  Future<void> _onSubmitEvidence() async {
    final provider = context.read<AdoptionProvider>();

    if (_evidencePhotoPath == null || _evidencePhotoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti fisik serah terima wajib dilampirkan.'),
          backgroundColor: AppConstants.dangerColor,
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
                'Bukti berhasil diunggah. Menunggu verifikasi admin.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppConstants.dangerColor,
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

    final isEvidencePending =
        activeAdoption != null && activeAdoption.isReturnEvidencePending;
    final isApproved =
        activeAdoption != null && activeAdoption.isReturnApproved;

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Pengembalian: ${widget.catName}', style: AdoptionTheme.titleStyle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          if (isDesktop) {
            // ── Tampilan Desktop (2 Kolom Seimbang) ─────────────────────
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kolom Kiri: Sidebar Kebijakan & Info Kucing
                        SizedBox(
                          width: 380,
                          child: _buildDesktopSidebar(
                            isReturnEnabled,
                            isEvidencePending,
                            isApproved,
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Kolom Kanan: Formulir Pengembalian & Bukti
                        Expanded(
                          child: _buildFormCard(
                            isReturnEnabled,
                            isEvidencePending,
                            isApproved,
                            provider,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Tampilan Mobile / Tablet (1 Kolom Rapi) ───────────────────
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildPolicyNoticeBanner(isReturnEnabled, isEvidencePending, isApproved),
                  const SizedBox(height: 16),
                  _buildFormCard(
                    isReturnEnabled,
                    isEvidencePending,
                    isApproved,
                    provider,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Banner Kebijakan (Mobile) ─────────────────────────────────────────────
  Widget _buildPolicyNoticeBanner(
    bool isReturnEnabled,
    bool isEvidencePending,
    bool isApproved,
  ) {
    if (isEvidencePending) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: AdoptionTheme.borderMd,
          border: Border.all(color: AdoptionTheme.info.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 20, color: AdoptionTheme.info),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Menunggu verifikasi admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8))),
                  Text('Bukti serah terima telah dikirim. Admin sedang meninjau dokumen fisik.', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isApproved) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: AdoptionTheme.borderMd,
          border: Border.all(color: AdoptionTheme.success.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 20, color: AdoptionTheme.success),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pengajuan disetujui. Silakan serahkan kucing dan unggah bukti foto.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
              ),
            ),
          ],
        ),
      );
    }

    if (!isReturnEnabled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AdoptionTheme.borderMd,
          border: Border.all(color: AdoptionTheme.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: AdoptionTheme.warning),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pengembalian ke kampus belum tersedia.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                  SizedBox(height: 3),
                  Text(
                    'Kebijakannya masih menunggu pengesahan pengelola. Formulir di bawah ini ditampilkan sebagai pratinjau struktur permohonan.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Sidebar Desktop ───────────────────────────────────────────────────────
  Widget _buildDesktopSidebar(
    bool isReturnEnabled,
    bool isEvidencePending,
    bool isApproved,
  ) {
    return Column(
      children: [
        // Kartu Identitas Kucing
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
                    child: const Icon(Icons.pets_rounded, size: 22, color: AdoptionTheme.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.catName, style: AdoptionTheme.subtitleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('ID Adopsi #${widget.adoptionId}', style: AdoptionTheme.captionStyle.copyWith(color: AdoptionTheme.textSub)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AdoptionTheme.divider),
              const SizedBox(height: 14),
              _buildPolicyNoticeBanner(isReturnEnabled, isEvidencePending, isApproved),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kartu Ketentuan Pengembalian Sesuai PRD
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
                  const Icon(Icons.gavel_rounded, size: 18, color: AdoptionTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Ketentuan Pengembalian',
                    style: AdoptionTheme.subtitleStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '• Jalur Biasa: Hanya diajukan setelah melewati 3 bulan kalender masa adopsi.\n'
                '• Jalur Darurat: Sebelum 3 bulan dengan mencantumkan alasan mendesak.\n'
                '• Status Kuota: Kuota adopsi tetap terikat sampai verifikasi bukti fisik disetujui admin.',
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

  // ── Kartu Formulir Pengembalian ───────────────────────────────────────────
  Widget _buildFormCard(
    bool isReturnEnabled,
    bool isEvidencePending,
    bool isApproved,
    AdoptionProvider provider,
  ) {
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
      child: Opacity(
        opacity: isReturnEnabled ? 1.0 : 0.65,
        child: IgnorePointer(
          ignoring: !isReturnEnabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Formulir Permohonan Pengembalian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lengkapi jalur dan alasan pengembalian untuk ditinjau oleh pengelola kampus.',
                style: AdoptionTheme.captionStyle,
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: AdoptionTheme.divider),
              const SizedBox(height: 18),

              // Jalur Pengembalian
              const Text('Jalur Pengembalian', style: AdoptionTheme.subtitleStyle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AdoptionTheme.borderMd,
                  border: Border.all(color: AdoptionTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReturnReasonType>(
                    value: _reasonType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: const [
                      DropdownMenuItem(
                        value: ReturnReasonType.NORMAL,
                        child: Text(
                          'Jalur Biasa (setelah 3 bulan adopsi)',
                          style: AdoptionTheme.bodyStyle,
                        ),
                      ),
                      DropdownMenuItem(
                        value: ReturnReasonType.EMERGENCY,
                        child: Text(
                          'Jalur Darurat (wajib alasan)',
                          style: AdoptionTheme.bodyStyle,
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _reasonType = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Alasan Pengembalian
              const Text('Alasan Pengembalian', style: AdoptionTheme.subtitleStyle),
              const SizedBox(height: 4),
              Text(
                _reasonType == ReturnReasonType.EMERGENCY
                    ? 'Jalur darurat mewajibkan penjelasan alasan secara rinci.'
                    : 'Jelaskan alasan pengembalian kucing ke kampus.',
                style: AdoptionTheme.captionStyle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan alasan pengembalian di sini...',
                  hintStyle: AdoptionTheme.captionStyle,
                  contentPadding: EdgeInsets.all(14),
                  border: OutlineInputBorder(
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
              ),

              const SizedBox(height: 20),

              // Tombol Kirim Pengajuan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdoptionTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AdoptionTheme.sp12),
                    shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
                  ),
                  onPressed: isReturnEnabled && !provider.isActionLoading
                      ? _onRequestReturn
                      : null,
                  child: provider.isActionLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan Pengembalian',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 28),
              const Divider(height: 1, color: AdoptionTheme.divider),
              const SizedBox(height: 20),

              // Bagian Unggah Bukti
              const Text('Unggah Bukti Serah Terima', style: AdoptionTheme.subtitleStyle),
              const SizedBox(height: 4),
              const Text(
                'Unggah foto bukti serah terima setelah pengajuan disetujui pengelola.',
                style: AdoptionTheme.captionStyle,
              ),
              const SizedBox(height: 12),
              CameraPhotoSlot(
                localPath: _evidencePhotoPath,
                hint: 'Buka kamera untuk foto bukti serah terima (tanpa galeri)',
                onTap: isApproved && !isEvidencePending ? () => _takeEvidencePhoto() : () {},
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isApproved && !isEvidencePending
                          ? AdoptionTheme.accent
                          : AdoptionTheme.cardBorder,
                    ),
                    foregroundColor: isApproved && !isEvidencePending
                        ? AdoptionTheme.accent
                        : AdoptionTheme.textHint,
                    padding: const EdgeInsets.symmetric(vertical: AdoptionTheme.sp12),
                    shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
                  ),
                  onPressed: isApproved && !isEvidencePending && !provider.isActionLoading
                      ? _onSubmitEvidence
                      : null,
                  child: const Text('Unggah Bukti Pengembalian'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
