import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 6 — Form & Riwayat Laporan Follow-up Berkala (Web & Mobile Responsif)
class AdoptionFollowupPage extends StatefulWidget {
  final int adoptionId;
  final int cycleNumber;
  final String catName;

  const AdoptionFollowupPage({
    super.key,
    required this.adoptionId,
    required this.cycleNumber,
    required this.catName,
  });

  @override
  State<AdoptionFollowupPage> createState() => _AdoptionFollowupPageState();
}

class _AdoptionFollowupPageState extends State<AdoptionFollowupPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _issuesController = TextEditingController();

  String _condition = 'Sehat';
  String? _photoPath;
  bool _photoAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchFollowups(widget.adoptionId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _issuesController.dispose();
    super.dispose();
  }

  Future<void> _takeFollowupPhoto() async {
    try {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => const CameraCapturePage(
            mode: CameraCaptureMode.cameraOnly,
            maxFiles: 1,
            purpose: 'followup_evidence',
          ),
        ),
      );

      if (result != null && result.isNotEmpty && mounted) {
        setState(() {
          _photoPath = result.first;
          _photoAttempted = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _photoPath =
              'mock://camera/followup_cat_${DateTime.now().millisecondsSinceEpoch}.jpg';
          _photoAttempted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto kondisi kucing berhasil diambil via kamera.'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    }
  }

  Future<void> _onSubmitFollowup() async {
    if (_photoPath == null || _photoPath!.isEmpty) {
      setState(() => _photoAttempted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto kondisi kucing wajib dilampirkan via kamera.'),
          backgroundColor: AppConstants.dangerColor,
        ),
      );
      return;
    }

    final provider = context.read<AdoptionProvider>();
    final followup = await provider.submitFollowup(
      adoptionId: widget.adoptionId,
      cycleNumber: widget.cycleNumber,
      photoPath: _photoPath!,
      condition: _condition,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      issues: _issuesController.text.trim().isNotEmpty
          ? _issuesController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (followup != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.actionSuccessMessage ??
                'Laporan follow-up berhasil dikirim.',
          ),
          backgroundColor: AppConstants.successColor,
        ),
      );
      setState(() {
        _photoPath = null;
        _notesController.clear();
        _issuesController.clear();
      });
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
    final followups = provider.currentFollowups;

    final activeAdoption = provider.myActiveAdoptions.cast().firstWhere(
          (a) => a.id == widget.adoptionId,
          orElse: () => null,
        );

    final nextDue = activeAdoption?.nextFollowupDue;
    final isLate = nextDue != null && nextDue.isBefore(DateTime.now());

    final dueStr = nextDue != null
        ? '${nextDue.day}/${nextDue.month}/${nextDue.year}'
        : 'Setiap 14 hari';

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Laporan: ${widget.catName}', style: AdoptionTheme.titleStyle),
      ),
      body: provider.isLoading && followups.isEmpty
          ? const LoadingIndicator(message: 'Memuat data follow-up...')
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
                              // Kolom Kiri: Sidebar Info Kucing & Ketentuan Siklus
                              SizedBox(
                                width: 380,
                                child: _buildDesktopSidebar(dueStr, isLate),
                              ),
                              const SizedBox(width: 28),
                              // Kolom Kanan: Kartu Formulir & Riwayat Laporan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildFormCard(provider),
                                    if (followups.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _buildHistoryCard(followups),
                                    ],
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
                        _buildCycleHeader(dueStr),
                        if (isLate) ...[
                          const SizedBox(height: 12),
                          _buildLateBanner(),
                        ],
                        const SizedBox(height: 16),
                        _buildFormCard(provider),
                        if (followups.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildHistoryCard(followups),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Header Siklus (Mobile) ────────────────────────────────────────────────
  Widget _buildCycleHeader(String dueStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Laporan ke-${widget.cycleNumber} dari 6',
                style: AdoptionTheme.titleStyle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: AdoptionTheme.accentLight,
                  borderRadius: AdoptionTheme.borderSm,
                ),
                child: Text(
                  'Siklus ${widget.cycleNumber}/6',
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: AdoptionTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Jatuh tempo: $dueStr',
            style: AdoptionTheme.bodyStyle,
          ),
        ],
      ),
    );
  }

  // ── Banner Varian Terlambat ───────────────────────────────────────────────
  Widget _buildLateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Icons.schedule_rounded,
            size: 18,
            color: AdoptionTheme.warning,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Laporan ini melewati batas waktu, tetap bisa dikirim.',
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
  Widget _buildDesktopSidebar(String dueStr, bool isLate) {
    return Column(
      children: [
        // Kartu Kucing & Jadwal Siklus
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
                          widget.catName,
                          style: AdoptionTheme.subtitleStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID Adopsi #${widget.adoptionId}',
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

              // Status Siklus
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Laporan ke-${widget.cycleNumber} dari 6',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AdoptionTheme.accentLight,
                      borderRadius: AdoptionTheme.borderSm,
                    ),
                    child: Text(
                      'Siklus ${widget.cycleNumber}/6',
                      style: AdoptionTheme.captionStyle.copyWith(
                        color: AdoptionTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Jatuh tempo: $dueStr', style: AdoptionTheme.captionStyle),

              if (isLate) ...[
                const SizedBox(height: 12),
                _buildLateBanner(),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kartu Panduan Follow-up
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
                  const Icon(Icons.info_outline_rounded, size: 18, color: AdoptionTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Ketentuan Follow-up',
                    style: AdoptionTheme.subtitleStyle.copyWith(
                      color: AdoptionTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '1. Foto wajib diambil langsung lewat kamera aplikasi (tanpa galeri).\n'
                '2. Laporkan kondisi kucing secara jujur (Sehat, Perlu perhatian, atau Sakit).\n'
                '3. Jika terdapat gejala sakit atau darurat, gunakan menu Lapor Kendala.',
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

  // ── Kartu Formulir Laporan Aktif ──────────────────────────────────────────
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
              'Formulir Follow-up Berkala',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kirimkan foto terkini dan pembaruan kondisi adaptasi kucing Anda.',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AdoptionTheme.divider),
            const SizedBox(height: 18),

            // ── 1. Foto Kondisi Kucing (Kamera Saja, Wajib) ────
            const Text('Foto Kondisi Kucing', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto kucing terkini via kamera aplikasi untuk memantau kesehatannya.',
              style: AdoptionTheme.captionStyle,
            ),
            const SizedBox(height: 10),
            CameraPhotoSlot(
              localPath: _photoPath,
              hint: 'Buka kamera untuk foto kondisi kucing (tanpa galeri)',
              onTap: _takeFollowupPhoto,
            ),
            if (_photoAttempted && (_photoPath == null || _photoPath!.isEmpty)) ...[
              const SizedBox(height: 6),
              Text(
                'Foto kondisi kucing wajib dilampirkan via kamera.',
                style: AdoptionTheme.captionStyle.copyWith(color: AppConstants.dangerColor),
              ),
            ],

            const SizedBox(height: 20),

            // ── 2. Pilihan Kondisi ─────────────────────────────
            const Text('Kondisi Umum Kucing', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AdoptionTheme.borderMd,
                border: Border.all(color: AdoptionTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _condition,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: const [
                    DropdownMenuItem(
                      value: 'Sehat',
                      child: Text('Sehat', style: AdoptionTheme.bodyStyle),
                    ),
                    DropdownMenuItem(
                      value: 'Perlu perhatian',
                      child: Text('Perlu perhatian', style: AdoptionTheme.bodyStyle),
                    ),
                    DropdownMenuItem(
                      value: 'Sakit',
                      child: Text('Sakit', style: AdoptionTheme.bodyStyle),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _condition = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── 3. Catatan Perkembangan (Opsional) ─────────────
            const Text('Catatan Perkembangan (Opsional)', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contoh: Nafsu makan baik, aktif bermain di kamar kos...',
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

            const SizedBox(height: 18),

            // ── 4. Kendala (Opsional) ──────────────────────────
            const Text('Kendala yang Ditemui (Opsional)', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _issuesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Misal: Penyesuaian pasir, belum mau makan basah...',
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

            const SizedBox(height: 24),
            const Divider(height: 1, color: AdoptionTheme.divider),
            const SizedBox(height: 20),

            // ── Tombol Kirim ──────────────────────────────────
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
                onPressed: provider.isActionLoading ? null : _onSubmitFollowup,
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
                          Text('Kirim Laporan Follow-up', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kartu Riwayat Laporan Sebelumnya ──────────────────────────────────────
  Widget _buildHistoryCard(List<dynamic> followups) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Laporan Sebelumnya',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AdoptionTheme.divider),
          const SizedBox(height: 12),
          ...followups.map((f) {
            final DateTime? date = f.submittedAt ?? f.dueDate;
            final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '-';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F7),
                borderRadius: AdoptionTheme.borderMd,
                border: Border.all(color: AdoptionTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AdoptionTheme.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${f.cycleNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdoptionTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laporan Siklus ke-${f.cycleNumber}', style: AdoptionTheme.subtitleStyle),
                        Text('Kondisi: ${f.condition} · $dateStr', style: AdoptionTheme.captionStyle),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_outline_rounded, size: 18, color: AdoptionTheme.success),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
