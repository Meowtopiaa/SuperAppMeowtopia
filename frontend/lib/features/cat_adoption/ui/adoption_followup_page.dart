import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

//// Layar 6: laporan kondisi berkala (ADP-09, ADP-10).
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
            content: Text('Foto tersimpan.'),
            backgroundColor: AdoptionTheme.success,
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
          content: Text('Ambil foto kucing dulu.'),
          backgroundColor: AdoptionTheme.danger,
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
                'Laporan terkirim.',
          ),
          backgroundColor: AdoptionTheme.success,
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
          backgroundColor: AdoptionTheme.danger,
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

    final DateTime? nextDue = activeAdoption?.nextFollowupDue;
    final int total = (activeAdoption?.totalFollowups ?? 0) > 0
        ? activeAdoption!.totalFollowups as int
        : 6;
    final isLate = nextDue != null && nextDue.isBefore(DateTime.now());

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Laporan kondisi', style: AdoptionTheme.titleStyle),
      ),
      body: provider.isLoading && followups.isEmpty
          ? const LoadingIndicator(message: 'Memuat laporan...')
          : Form(
              key: _formKey,
              child: AdoptionPageBody(
                children: [
                  Text(widget.catName, style: AdoptionTheme.bodyStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Laporan ke-${widget.cycleNumber} dari $total',
                    style: AdoptionTheme.headlineStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextDue != null
                        ? 'Paling lambat ${formatAdoptionDate(nextDue)}.'
                        : 'Dikirim setiap 14 hari selama tiga bulan pertama.',
                    style: AdoptionTheme.bodyStyle,
                  ),
                  if (isLate) ...[
                    const SizedBox(height: 12),
                    const AdoptionBanner(
                      variant: 'warning',
                      message: 'Laporan ini sudah lewat batas waktu, tapi tetap bisa dikirim.',
                    ),
                  ],
                  const SizedBox(height: 28),
                  AdoptionSection(
                    title: 'Foto kucing hari ini',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CameraPhotoSlot(
                          localPath: _photoPath,
                          hint: 'Ambil foto kucing',
                          onTap: _takeFollowupPhoto,
                        ),
                        if (_photoAttempted && (_photoPath == null || _photoPath!.isEmpty)) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Foto kucing wajib diambil.',
                            style: AdoptionTheme.captionStyle.copyWith(
                              color: AdoptionTheme.danger,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AdoptionSection(
                    title: 'Kondisi kucing secara umum',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Sehat', 'Perlu perhatian', 'Sakit'].map((option) {
                        final selected = _condition == option;
                        return ChoiceChip(
                          label: Text(option),
                          selected: selected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _condition = option),
                          labelStyle: AdoptionTheme.bodyStyle.copyWith(
                            color: selected ? Colors.white : AdoptionTheme.textMain,
                          ),
                          backgroundColor: AdoptionTheme.cardBg,
                          selectedColor: AdoptionTheme.accent,
                          side: BorderSide(
                            color: selected ? AdoptionTheme.accent : AdoptionTheme.inputBorder,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AdoptionTheme.borderSm,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_condition == 'Sakit')
                    const Padding(
                      padding: EdgeInsets.only(bottom: AdoptionTheme.sp24),
                      child: AdoptionBanner(
                        variant: 'warning',
                        message: 'Kalau kucing butuh bantuan segera, gunakan juga '
                            'Laporkan kendala di halaman Kucing saya.',
                      ),
                    ),
                  AdoptionSection(
                    title: 'Perkembangan',
                    description: 'Opsional.',
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      style: AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
                      decoration: _inputDecoration('Contoh: makan lahap, sudah mau tidur di kasurnya'),
                    ),
                  ),
                  AdoptionSection(
                    title: 'Kendala',
                    description: 'Opsional.',
                    child: TextFormField(
                      controller: _issuesController,
                      maxLines: 2,
                      style: AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
                      decoration: _inputDecoration('Contoh: belum cocok dengan pasir baru'),
                    ),
                  ),
                  AdoptionPrimaryButton(
                    label: 'Kirim laporan',
                    isLoading: provider.isActionLoading,
                    onPressed: provider.isActionLoading ? null : _onSubmitFollowup,
                  ),
                  if (followups.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    AdoptionSection(
                      title: 'Laporan sebelumnya',
                      child: Column(
                        children: followups.map<Widget>((f) {
                          final DateTime date = f.submittedAt ?? f.dueDate;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AdoptionTheme.divider),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Laporan ke-${f.cycleNumber}',
                                        style: AdoptionTheme.bodyStyle.copyWith(
                                          color: AdoptionTheme.textMain,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Kondisi: ${f.condition}',
                                        style: AdoptionTheme.captionStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                    formatAdoptionDate(date),
                                    style: AdoptionTheme.captionStyle,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textHint),
      contentPadding: const EdgeInsets.all(14),
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
      filled: true,
      fillColor: AdoptionTheme.cardBg,
    );
  }
}
