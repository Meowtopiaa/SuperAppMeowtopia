import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/constants/app_constants.dart';
import '../data/adoption_enums.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 8 — Laporan Kendala Adopsi (Web & Mobile Responsif)
class AdoptionIssueReportPage extends StatefulWidget {
  final int adoptionId;
  final int catId;
  final String catName;

  const AdoptionIssueReportPage({
    super.key,
    required this.adoptionId,
    required this.catId,
    required this.catName,
  });

  @override
  State<AdoptionIssueReportPage> createState() =>
      _AdoptionIssueReportPageState();
}

class _AdoptionIssueReportPageState extends State<AdoptionIssueReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  AdoptionIssueCategory _category = AdoptionIssueCategory.SICK;
  String? _optionalPhotoPath;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takeOptionalPhoto() async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(
            mode: CameraCaptureMode.cameraOnly,
            maxFiles: 1,
            purpose: 'issue_optional_evidence',
          ),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _optionalPhotoPath = result.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _optionalPhotoPath =
              'mock://camera/issue_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
      }
    }
  }

  Future<void> _onSubmitReport() async {
    final provider = context.read<AdoptionProvider>();

    if (!_formKey.currentState!.validate()) return;

    final report = await provider.reportIssue(
      adoptionId: widget.adoptionId,
      catId: widget.catId,
      category: _category,
      description: _descriptionController.text.trim(),
      photoPath: _optionalPhotoPath,
    );

    if (!mounted) return;

    if (report != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderLg),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AdoptionTheme.success, size: 22),
              SizedBox(width: 8),
              Text('Laporan Diterima', style: AdoptionTheme.subtitleStyle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan mengenai ${widget.catName} (${_category.labelId}) telah berhasil dicatat.',
                style: AdoptionTheme.bodyStyle,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F7),
                  borderRadius: AdoptionTheme.borderSm,
                  border: Border.all(color: AdoptionTheme.cardBorder),
                ),
                child: Text(
                  'Catatan: Laporan ini tidak otomatis menutup adopsi. Tim relawan kampus akan menindaklanjuti untuk bantuan.',
                  style: AdoptionTheme.captionStyle.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdoptionTheme.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Selesai'),
            ),
          ],
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

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Lapor Kendala: ${widget.catName}', style: AdoptionTheme.titleStyle),
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
                        // Kolom Kiri: Sidebar Informasi & Ketentuan Kendala
                        SizedBox(
                          width: 380,
                          child: _buildDesktopSidebar(),
                        ),
                        const SizedBox(width: 28),
                        // Kolom Kanan: Formulir Pelaporan Kendala
                        Expanded(
                          child: _buildFormCard(provider),
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
                  _buildNoticeBanner(),
                  const SizedBox(height: 16),
                  _buildFormCard(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Banner Catatan Netral ─────────────────────────────────────────────────
  Widget _buildNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: AdoptionTheme.warning.withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AdoptionTheme.warning,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Laporan kendala tidak otomatis menutup adopsi.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar Desktop ───────────────────────────────────────────────────────
  Widget _buildDesktopSidebar() {
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
                        Text('ID Kucing #${widget.catId}', style: AdoptionTheme.captionStyle.copyWith(color: AdoptionTheme.textSub)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AdoptionTheme.divider),
              const SizedBox(height: 14),
              _buildNoticeBanner(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kartu Panduan Penanganan Kendala
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
                  const Icon(Icons.support_agent_rounded, size: 18, color: AdoptionTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Dukungan Relawan Kampus',
                    style: AdoptionTheme.subtitleStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '• Sakit: Tim relawan akan meninjau dan memberi panduan perawatan medis.\n'
                '• Hilang: Informasi lokasi terakhir membantu pencarian di sekitar kampus.\n'
                '• Kalung/QR Rusak: Penggantian liontin QR dapat dikoordinasikan secara gratis.\n'
                '• Foto: Bersifat opsional, lampirkan jika ada kondisi fisik yang perlu diperlihatkan.',
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

  // ── Kartu Formulir Pelaporan ──────────────────────────────────────────────
  Widget _buildFormCard(AdoptionProvider provider) {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulir Pelaporan Kendala',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih kategori kendala dan ceritakan situasi terkini kucing Anda.',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AdoptionTheme.divider),
            const SizedBox(height: 18),

            // ── 1. Kategori Kendala ──────────────────────────────────
            const Text('Pilih Kategori Kendala', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: AdoptionTheme.borderMd,
                border: Border.all(color: AdoptionTheme.cardBorder),
              ),
              child: Column(
                children: AdoptionIssueCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return InkWell(
                    borderRadius: AdoptionTheme.borderSm,
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AdoptionTheme.accentLight : Colors.transparent,
                        borderRadius: AdoptionTheme.borderSm,
                        border: Border.all(
                          color: isSelected ? AdoptionTheme.accent : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat.icon,
                            size: 20,
                            color: isSelected ? AdoptionTheme.accent : AdoptionTheme.textHint,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.labelId,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AdoptionTheme.accent : AdoptionTheme.textMain,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AdoptionTheme.accent,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Deskripsi Kendala ─────────────────────────────────
            const Text('Uraian Kendala', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 4),
            const Text(
              'Ceritakan kronologi kejadian, gejala sakit, atau kendala yang dihadapi.',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ceritakan gejala, kronologi kejadian, dan kondisi terkini...',
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Uraian kendala wajib diisi.';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // ── 3. Foto Pendukung (Opsional) ─────────────────────────
            Row(
              children: [
                const Text('Foto Pendukung', style: AdoptionTheme.subtitleStyle),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AdoptionTheme.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Opsional',
                    style: AdoptionTheme.captionStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Lampirkan foto via kamera bila dapat membantu penanganan (tidak wajib).',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 10),
            CameraPhotoSlot(
              localPath: _optionalPhotoPath,
              hint: 'Ambil foto pendukung (kamera)',
              onTap: _takeOptionalPhoto,
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, color: AdoptionTheme.divider),
            const SizedBox(height: 20),

            // ── Tombol Kirim Laporan ──────────────────────────────────
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
                onPressed: provider.isActionLoading ? null : _onSubmitReport,
                child: provider.isActionLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Kirim Laporan Kendala', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
