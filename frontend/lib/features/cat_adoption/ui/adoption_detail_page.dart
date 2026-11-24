import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/adoption_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 3: status dan rincian pengajuan kelayakan.
class AdoptionDetailPage extends StatefulWidget {
  final int applicationId;

  const AdoptionDetailPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<AdoptionDetailPage> createState() => _AdoptionDetailPageState();
}

class _AdoptionDetailPageState extends State<AdoptionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();

    final application = provider.myApplications.cast().firstWhere(
          (a) => a.id == widget.applicationId,
          orElse: () => null,
        );

    final appBar = AppBar(
      backgroundColor: AdoptionTheme.pageBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text('Status pengajuan', style: AdoptionTheme.titleStyle),
    );

    if (application == null) {
      return Scaffold(
        backgroundColor: AdoptionTheme.pageBg,
        appBar: appBar,
        body: AdoptionErrorState(
          message: 'Pengajuan ini tidak ditemukan.',
          onRetry: () => provider.fetchMyApplications(),
        ),
      );
    }

    final AdoptionApplicationModel app = application;
    final catName = app.catName ??
        (app.cat != null ? app.cat!.name : 'Belum memilih kucing');
    final hasNotes =
        app.adminNotes != null && app.adminNotes!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: appBar,
      body: AdoptionPageBody(
        children: [
          AdoptionHeader(
            overline: 'Pengajuan kelayakan',
            title: catName,
            subtitle: 'Diajukan oleh ${app.applicantName}',
            icon: Icons.assignment_outlined,
            footer: ApplicationStatusBadge(status: app.status),
          ),
          AdoptionSection(
            title: 'Tahapan',
            child: ApplicationStatusTimeline(
              currentStatus: app.status,
              precheckPassed: app.precheckPassed,
            ),
          ),
          if (app.isRevisionRequested) ...[
            AdoptionBanner(
              variant: 'warning',
              title: 'Perlu diperbaiki',
              message:
                  'Pengurus adopsi meminta kamu memperbaiki beberapa jawaban.',
              action: AdoptionPrimaryButton(
                label: 'Perbaiki dan kirim ulang',
                onPressed: () => context.push(
                  '/adoption/apply?edit_id=${app.id}&cat_id=${app.catId ?? ''}&name=${Uri.encodeComponent(app.catName ?? '')}',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (app.isApproved) ...[
            AdoptionBanner(
              variant: 'success',
              title: 'Kelayakan disetujui',
              message:
                  'Kamu belum resmi mengadopsi. Adopsi aktif setelah kamu memindai '
                  'QR di kalung kucing dan memotretnya saat pengambilan.',
              action: app.catId != null
                  ? AdoptionPrimaryButton(
                      label: 'Mulai pengambilan',
                      icon: Icons.qr_code_scanner_rounded,
                      onPressed: () => context.push(
                        '/adoption/pickup?app_id=${app.id}&cat_id=${app.catId}',
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          if (hasNotes)
            AdoptionSection(
              title: 'Catatan pengurus adopsi',
              child: Text(
                app.adminNotes!,
                style: AdoptionTheme.bodyStyle
                    .copyWith(color: AdoptionTheme.textMain),
              ),
            ),
          AdoptionSection(
            title: 'Jawaban form kelayakan',
            child: Column(
              children: [
                AdoptionInfoRow(
                  label: 'Tempat tinggal',
                  value: _housingTypeLabel(app.housingType),
                ),
                AdoptionInfoRow(
                  label: 'Izin pemilik tempat',
                  value: app.familyPermission ? 'Sudah ada' : 'Belum ada',
                ),
                AdoptionInfoRow(
                  label: 'Biaya bulanan',
                  value: app.financialReadiness ? 'Sanggup' : 'Belum sanggup',
                ),
                AdoptionInfoRow(
                  label: 'Lembar komitmen',
                  value: app.commitmentAccepted
                      ? 'Sudah disetujui'
                      : 'Belum disetujui',
                ),
                if (app.longTermPlan != null && app.longTermPlan!.isNotEmpty)
                  AdoptionInfoRow(
                      label: 'Rencana jangka panjang',
                      value: app.longTermPlan!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _housingTypeLabel(String type) {
    switch (type) {
      case 'kos':
        return 'Kos yang mengizinkan hewan';
      case 'rumah_kontrakan':
        return 'Rumah kontrakan';
      case 'rumah_pribadi':
        return 'Rumah sendiri atau keluarga';
      default:
        return type;
    }
  }
}
