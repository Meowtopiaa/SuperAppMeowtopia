import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/camera/camera_capture_page.dart';
import '../data/adoption_enums.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 8: laporan kendala adopsi (ADP-13).
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
          backgroundColor: AdoptionTheme.cardBg,
          shape: const RoundedRectangleBorder(
              borderRadius: AdoptionTheme.borderLg),
          title:
              const Text('Laporan tersimpan', style: AdoptionTheme.titleStyle),
          content: Text(
            'Laporan ${_category.labelId.toLowerCase()} untuk ${widget.catName} sudah tercatat. '
            'Pengurus adopsi akan meninjaunya. Adopsimu tetap aktif.',
            style: AdoptionTheme.bodyStyle,
          ),
          actions: [
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AdoptionTheme.accent),
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
          backgroundColor: AdoptionTheme.danger,
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
        title: const Text('Laporkan kendala', style: AdoptionTheme.titleStyle),
      ),
      body: Form(
        key: _formKey,
        child: AdoptionPageBody(
          children: [
            AdoptionHeader(
              overline: 'Laporan kendala ${widget.catName}',
              title: 'Apa yang terjadi?',
              subtitle:
                  'Laporan ini dibaca pengurus adopsi dan tidak menutup adopsimu.',
              icon: Icons.report_gmailerrorred_rounded,
            ),
            AdoptionSection(
              title: 'Jenis kendala',
              child: Column(
                children: AdoptionIssueCategory.values.map((cat) {
                  final selected = _category == cat;
                  return Semantics(
                    selected: selected,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _category = cat),
                      borderRadius: AdoptionTheme.borderMd,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 22,
                              color: selected
                                  ? AdoptionTheme.accent
                                  : AdoptionTheme.textHint,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat.labelId,
                                style: AdoptionTheme.bodyStyle.copyWith(
                                  color: AdoptionTheme.textMain,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            AdoptionSection(
              title: 'Ceritakan kejadiannya',
              description:
                  'Sejak kapan, gejala yang terlihat, dan kondisi kucing sekarang.',
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: AdoptionTheme.bodyStyle
                    .copyWith(color: AdoptionTheme.textMain),
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
                    borderSide:
                        BorderSide(color: AdoptionTheme.accent, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AdoptionTheme.cardBg,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ceritakan kejadiannya dulu.';
                  }
                  return null;
                },
              ),
            ),
            AdoptionSection(
              title: 'Foto',
              description:
                  'Opsional. Lampirkan kalau membantu pengurus memahami kondisinya.',
              child: CameraPhotoSlot(
                localPath: _optionalPhotoPath,
                hint: 'Ambil foto',
                onTap: _takeOptionalPhoto,
              ),
            ),
            AdoptionPrimaryButton(
              label: 'Kirim laporan',
              isLoading: provider.isActionLoading,
              onPressed: provider.isActionLoading ? null : _onSubmitReport,
            ),
          ],
        ),
      ),
    );
  }
}
