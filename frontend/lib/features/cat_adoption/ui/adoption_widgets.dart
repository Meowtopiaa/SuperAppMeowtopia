import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/adoption_enums.dart';
import 'adoption_theme.dart';

const _monthsId = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Tanggal ringkas berbahasa Indonesia dalam WIB, misalnya "5 Nov 2026".
/// Waktu dari server disimpan UTC (PRD 2), jadi dikonversi ke UTC+7 dulu.
String formatAdoptionDate(DateTime date) {
  final wib = date.isUtc ? date.add(const Duration(hours: 7)) : date;
  return '${wib.day} ${_monthsId[wib.month - 1]} ${wib.year}';
}

// ═══════════════════════════════════════════════════════════════════════════
// TOMBOL
// ═══════════════════════════════════════════════════════════════════════════

/// Tombol utama adopsi.
class AdoptionPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? minWidth;

  const AdoptionPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: minWidth,
      child: ElevatedButton(
        style: AdoptionTheme.primaryButtonStyle,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AdoptionTheme.textHint),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                ],
              ),
      ),
    );
  }
}

/// Tombol sekunder adopsi untuk aksi tambahan.
class AdoptionSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AdoptionSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: AdoptionTheme.secondaryButtonStyle,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TATA LETAK BAGIAN
// ═══════════════════════════════════════════════════════════════════════════

/// Satu bagian halaman: judul, keterangan opsional, lalu isi.
/// Dipakai sebagai pengganti "kartu" untuk konten yang tidak bisa diketuk.
class AdoptionSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final Widget? trailing;

  const AdoptionSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdoptionTheme.sp24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(title, style: AdoptionTheme.subtitleStyle)),
              if (trailing != null) trailing!,
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AdoptionTheme.sp4),
            Text(description!, style: AdoptionTheme.bodyStyle),
          ],
          const SizedBox(height: AdoptionTheme.sp12),
          child,
        ],
      ),
    );
  }
}

/// Baris label dan nilai untuk ringkasan data (detail, pengambilan, dsb.).
class AdoptionInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const AdoptionInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(label, style: AdoptionTheme.bodyStyle),
          ),
          const SizedBox(width: AdoptionTheme.sp12),
          Expanded(
            child: Text(
              value,
              style: AdoptionTheme.bodyStyle.copyWith(
                color: AdoptionTheme.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pembungkus halaman: membatasi lebar konten agar nyaman dibaca di web.
class AdoptionPageBody extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const AdoptionPageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 40),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AdoptionTheme.maxContentWidth),
        child: ListView(padding: padding, children: children),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOTO KUCING
// ═══════════════════════════════════════════════════════════════════════════

/// Foto kucing rasio 4:3. [photoUrl] kosong menampilkan latar polos.
class CatPhotoBox extends StatelessWidget {
  final String? photoUrl;
  final BorderRadius? borderRadius;
  final double? height;

  const CatPhotoBox({
    super.key,
    this.photoUrl,
    this.borderRadius,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? AdoptionTheme.borderPhoto;
    final placeholder = Container(
      decoration: BoxDecoration(color: AdoptionTheme.chipBg, borderRadius: br),
      alignment: Alignment.center,
      child: const Text('Belum ada foto', style: AdoptionTheme.captionStyle),
    );

    final hasUrl = photoUrl != null && photoUrl!.isNotEmpty;
    if (!hasUrl) {
      return AspectRatio(aspectRatio: 4 / 3, child: placeholder);
    }

    return ClipRRect(
      borderRadius: br,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          height: height,
          placeholder: (_, __) => Container(color: AdoptionTheme.chipBg),
          errorWidget: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

/// Slot foto dari kamera aplikasi (galeri tidak dipakai, PRD 4.7).
class CameraPhotoSlot extends StatelessWidget {
  final String? localPath;
  final VoidCallback onTap;
  final String hint;

  const CameraPhotoSlot({
    super.key,
    required this.onTap,
    this.localPath,
    this.hint = 'Ambil foto',
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = localPath != null && localPath!.isNotEmpty;

    return Semantics(
      button: true,
      label: hasPhoto ? 'Foto sudah diambil. Ketuk untuk mengambil ulang' : hint,
      child: Material(
        color: hasPhoto ? AdoptionTheme.successLight : AdoptionTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: AdoptionTheme.borderMd,
          side: BorderSide(
            color: hasPhoto ? AdoptionTheme.success : AdoptionTheme.inputBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AdoptionTheme.borderMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(
                  hasPhoto ? Icons.check_rounded : Icons.photo_camera_outlined,
                  size: 22,
                  color: hasPhoto ? AdoptionTheme.success : AdoptionTheme.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPhoto ? 'Foto sudah diambil' : hint,
                        style: AdoptionTheme.bodyStyle.copyWith(
                          color: AdoptionTheme.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPhoto
                            ? 'Ketuk untuk mengambil ulang'
                            : 'Kamera akan terbuka. Foto dari galeri tidak bisa dipakai.',
                        style: AdoptionTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANNER INFO
// ═══════════════════════════════════════════════════════════════════════════

/// Pesan sebaris di dalam halaman. [variant]: 'info' | 'warning' | 'success' | 'danger'.
/// Tampil sebagai blok datar dengan garis warna di kiri.
class AdoptionBanner extends StatelessWidget {
  final String message;
  final String? title;
  final String variant;
  final IconData? icon;
  final Widget? action;

  const AdoptionBanner({
    super.key,
    required this.message,
    this.title,
    this.variant = 'info',
    this.icon,
    this.action,
  });

  Color get _bg => switch (variant) {
        'warning' => AdoptionTheme.warningLight,
        'success' => AdoptionTheme.successLight,
        'danger' => AdoptionTheme.dangerLight,
        _ => AdoptionTheme.chipBg,
      };

  Color get _fg => switch (variant) {
        'warning' => AdoptionTheme.warning,
        'success' => AdoptionTheme.success,
        'danger' => AdoptionTheme.danger,
        _ => AdoptionTheme.textSub,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: AdoptionTheme.borderSm,
        border: Border(left: BorderSide(color: _fg, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AdoptionTheme.bodyStyle.copyWith(
                color: _fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            message,
            style: AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textMain),
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action!,
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE KOSONG & STATE GAGAL
// ═══════════════════════════════════════════════════════════════════════════

/// State kosong: kalimat yang menjelaskan keadaan dan langkah berikutnya.
class AdoptionEmptyState extends StatelessWidget {
  final String message;
  final String? submessage;
  final IconData icon;
  final Widget? action;

  const AdoptionEmptyState({
    super.key,
    required this.message,
    this.submessage,
    this.icon = Icons.pets_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AdoptionTheme.textHint),
          const SizedBox(height: AdoptionTheme.sp12),
          Text(
            message,
            style: AdoptionTheme.subtitleStyle,
            textAlign: TextAlign.center,
          ),
          if (submessage != null) ...[
            const SizedBox(height: AdoptionTheme.sp4),
            Text(
              submessage!,
              style: AdoptionTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AdoptionTheme.sp16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// State gagal muat (jaringan atau server).
class AdoptionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AdoptionErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdoptionTheme.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 32, color: AdoptionTheme.textHint),
            const SizedBox(height: AdoptionTheme.sp12),
            const Text('Data belum bisa dimuat', style: AdoptionTheme.subtitleStyle),
            const SizedBox(height: AdoptionTheme.sp4),
            Text(
              message,
              style: AdoptionTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AdoptionTheme.sp16),
              AdoptionSecondaryButton(
                label: 'Coba lagi',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LABEL STATUS
// ═══════════════════════════════════════════════════════════════════════════

/// Label status ringkas: teks berwarna di latar lembut, tanpa garis tepi.
class AdoptionStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;

  const AdoptionStatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusLabel(
      label: label,
      color: color,
      background: backgroundColor ?? color.withValues(alpha: 0.1),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusLabel({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AdoptionTheme.borderSm,
      ),
      child: Text(
        label,
        style: AdoptionTheme.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Label status kelayakan adopter (ADP-01..04).
class ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const ApplicationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return _StatusLabel(
      label: status.labelId,
      color: status.color,
      background: status.backgroundColor,
    );
  }
}

/// Label status adopsi aktif (ADP-08).
class ActiveAdoptionStatusBadge extends StatelessWidget {
  final ActiveAdoptionStatus status;

  const ActiveAdoptionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return _StatusLabel(
      label: status.labelId,
      color: status.color,
      background: status.backgroundColor,
    );
  }
}

/// Pemberitahuan bahwa adopsi hanya untuk mahasiswa (ADP-01).
/// Tombol ganti tipe akun hanya muncul di mode debug untuk uji data tiruan.
class StudentRequirementBanner extends StatelessWidget {
  final String currentUserType;
  final VoidCallback? onSwitchToStudent;

  const StudentRequirementBanner({
    super.key,
    required this.currentUserType,
    this.onSwitchToStudent,
  });

  @override
  Widget build(BuildContext context) {
    final isStudent = currentUserType.toLowerCase() == 'mahasiswa';
    if (isStudent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AdoptionTheme.sp16),
      child: AdoptionBanner(
        variant: 'danger',
        title: 'Adopsi hanya untuk mahasiswa',
        message:
            'Akunmu terdaftar sebagai $currentUserType. Pengajuan adopsi hanya bisa dibuat '
            'dengan akun mahasiswa yang emailnya sudah terverifikasi.',
        action: (kDebugMode && onSwitchToStudent != null)
            ? TextButton(
                onPressed: onSwitchToStudent,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  foregroundColor: AdoptionTheme.accent,
                ),
                child: const Text('Uji sebagai mahasiswa (debug)'),
              )
            : null,
      ),
    );
  }
}

/// Tahapan pengajuan: Draf, Dikirim, Keputusan admin.
class ApplicationStatusTimeline extends StatelessWidget {
  final ApplicationStatus currentStatus;
  final bool precheckPassed;

  const ApplicationStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.precheckPassed,
  });

  @override
  Widget build(BuildContext context) {
    final decisionLabel = switch (currentStatus) {
      ApplicationStatus.REVISION_REQUESTED => 'Perlu revisi',
      ApplicationStatus.REJECTED => 'Ditolak',
      ApplicationStatus.APPROVED => 'Disetujui',
      _ => 'Keputusan admin',
    };
    final steps = ['Draf', 'Dikirim', decisionLabel];
    final activeIndex = switch (currentStatus) {
      ApplicationStatus.DRAFT => 0,
      ApplicationStatus.SUBMITTED => 1,
      _ => 2,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            final reached = i <= activeIndex;
            final color = i == activeIndex && activeIndex == 2
                ? currentStatus.color
                : (reached ? AdoptionTheme.accent : AdoptionTheme.divider);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[i],
                      style: AdoptionTheme.captionStyle.copyWith(
                        color: i == activeIndex ? AdoptionTheme.textMain : AdoptionTheme.textHint,
                        fontWeight: i == activeIndex ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        if (currentStatus != ApplicationStatus.DRAFT) ...[
          const SizedBox(height: AdoptionTheme.sp12),
          Text(
            precheckPassed
                ? 'Pemeriksaan otomatis: data lengkap.'
                : 'Pemeriksaan otomatis: ada syarat yang belum terpenuhi.',
            style: AdoptionTheme.captionStyle.copyWith(
              color: precheckPassed ? AdoptionTheme.success : AdoptionTheme.warning,
            ),
          ),
        ],
      ],
    );
  }
}
