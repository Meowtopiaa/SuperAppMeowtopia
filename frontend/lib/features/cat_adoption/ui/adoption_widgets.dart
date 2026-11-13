import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../data/adoption_enums.dart';
import 'adoption_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TOMBOL
// ═══════════════════════════════════════════════════════════════════════════

/// Tombol utama adopsi — terakota penuh, lebar bebas atau bisa dibatasi.
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17),
                    const SizedBox(width: 6),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Tombol sekunder adopsi — outline terakota, cocok untuk aksi tambahan.
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
            Icon(icon, size: 15),
            const SizedBox(width: 5),
          ],
          Text(label),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOTO KUCING (placeholder & fallback)
// ═══════════════════════════════════════════════════════════════════════════

/// Widget foto kucing rasio 4:3 dengan placeholder netral dan fallback ikon.
/// Gunakan [photoUrl] kosong atau null untuk menampilkan placeholder.
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
    final h = height;

    Widget placeholder = Container(
      decoration: BoxDecoration(
        color: AdoptionTheme.accentSurface,
        borderRadius: br,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets_rounded,
              size: 36,
              color: AdoptionTheme.accent.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 6),
            Text(
              'Foto belum tersedia',
              style: AdoptionTheme.captionStyle.copyWith(
                color: AdoptionTheme.textHint,
              ),
            ),
          ],
        ),
      ),
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
          height: h,
          placeholder: (_, __) => Container(
            color: AdoptionTheme.accentSurface,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AdoptionTheme.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AdoptionTheme.accentSurface,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: AdoptionTheme.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tempat foto hasil kamera (input kamera — bukan galeri).
/// Menampilkan pratinjau path lokal atau placeholder "Ambil Foto" bila kosong.
class CameraPhotoSlot extends StatelessWidget {
  final String? localPath;
  final VoidCallback onTap;
  final String hint;

  const CameraPhotoSlot({
    super.key,
    required this.onTap,
    this.localPath,
    this.hint = 'Ambil foto via kamera',
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = localPath != null && localPath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: hasPhoto ? AdoptionTheme.accentLight : Colors.white,
          borderRadius: AdoptionTheme.borderMd,
          border: Border.all(
            color: hasPhoto ? AdoptionTheme.accent : AdoptionTheme.cardBorder,
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        child: hasPhoto
            ? Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AdoptionTheme.borderMd,
                      child: Container(
                        color: AdoptionTheme.accentSurface,
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 32,
                            color: AppConstants.successColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: AdoptionTheme.borderSm,
                        ),
                        child: Text(
                          '${localPath!.split('/').last}  · Ketuk untuk ganti',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AdoptionTheme.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 22,
                      color: AdoptionTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hint,
                    style: AdoptionTheme.captionStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AdoptionTheme.textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kamera langsung · Galeri tidak tersedia',
                    style: AdoptionTheme.captionStyle.copyWith(
                      fontSize: 11,
                      color: AdoptionTheme.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANNER INFO
// ═══════════════════════════════════════════════════════════════════════════

/// Banner informasi/peringatan/sukses dengan ikon dan teks.
/// [variant]: 'info' | 'warning' | 'success' | 'danger'
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
        _ => AdoptionTheme.infoLight,
      };

  Color get _border => switch (variant) {
        'warning' => AdoptionTheme.warning.withValues(alpha: 0.4),
        'success' => AdoptionTheme.success.withValues(alpha: 0.4),
        'danger' => AdoptionTheme.danger.withValues(alpha: 0.4),
        _ => AdoptionTheme.info.withValues(alpha: 0.4),
      };

  Color get _fg => switch (variant) {
        'warning' => AdoptionTheme.warning,
        'success' => AdoptionTheme.success,
        'danger' => AdoptionTheme.danger,
        _ => AdoptionTheme.info,
      };

  IconData get _icon => icon ??
      switch (variant) {
        'warning' => Icons.warning_amber_rounded,
        'success' => Icons.check_circle_rounded,
        'danger' => Icons.error_rounded,
        _ => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AdoptionTheme.padCard,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _fg, size: 20),
          const SizedBox(width: AdoptionTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AdoptionTheme.subtitleStyle.copyWith(color: _fg),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(message, style: AdoptionTheme.bodyStyle),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATE KOSONG & STATE GAGAL
// ═══════════════════════════════════════════════════════════════════════════

/// State kosong — tampil ketika tidak ada data sama sekali.
class AdoptionEmptyState extends StatelessWidget {
  final String message;
  final String? submessage;
  final IconData icon;
  final Widget? action;

  const AdoptionEmptyState({
    super.key,
    required this.message,
    this.submessage,
    this.icon = Icons.pets_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdoptionTheme.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdoptionTheme.accentSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AdoptionTheme.cardBorder),
              ),
              child: Icon(icon, size: 36, color: AdoptionTheme.textHint),
            ),
            const SizedBox(height: AdoptionTheme.sp16),
            Text(
              message,
              style: AdoptionTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              const SizedBox(height: AdoptionTheme.sp8),
              Text(
                submessage!,
                style: AdoptionTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AdoptionTheme.sp24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// State gagal — tampil ketika terjadi error jaringan atau server.
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AdoptionTheme.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppConstants.dangerColor,
              ),
            ),
            const SizedBox(height: AdoptionTheme.sp16),
            const Text(
              'Gagal Memuat Data',
              style: AdoptionTheme.subtitleStyle,
            ),
            const SizedBox(height: AdoptionTheme.sp8),
            Text(
              message,
              style: AdoptionTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AdoptionTheme.sp24),
              AdoptionPrimaryButton(
                label: 'Coba Lagi',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                minWidth: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGE STATUS (teks + ikon) — generik, selain ApplicationStatusBadge
// ═══════════════════════════════════════════════════════════════════════════

/// Badge status ringkas dengan teks dan ikon; cocok untuk status adopsi,
/// follow-up, pengembalian, dsb.
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
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdoptionTheme.sp8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AdoptionTheme.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AdoptionTheme.captionStyle.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BADGE STATUS YANG SUDAH ADA (tidak diubah, hanya ditambah di bawah)
// ═══════════════════════════════════════════════════════════════════════════

/// Badge status kelayakan adopter (ADP-01..04)
class ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const ApplicationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.labelId,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge status adopsi aktif (ADP-08)
class ActiveAdoptionStatusBadge extends StatelessWidget {
  final ActiveAdoptionStatus status;

  const ActiveAdoptionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.labelId,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner Peringatan Mahasiswa Only (ADP-01)
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.dangerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.gpp_bad_rounded,
            color: AppConstants.dangerColor,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NOT_STUDENT — Hak Akses Dibatasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.dangerColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saat ini akun Anda bertipe "$currentUserType". Sesuai ketentuan PRD (ADP-01), hanya mahasiswa dengan email kampus aktif yang dapat mengajukan adopsi kucing.',
                  style: const TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (onSwitchToStudent != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onSwitchToStudent,
                    child: const Text(
                      '⚡ Beralih ke Mahasiswa (Mode Uji Coba)',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual Timeline Status Pengajuan (DRAFT -> SUBMITTED -> DECISION)
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
    final steps = [
      {'title': 'Draf', 'status': ApplicationStatus.DRAFT},
      {'title': 'Diajukan', 'status': ApplicationStatus.SUBMITTED},
      {
        'title': currentStatus == ApplicationStatus.REVISION_REQUESTED
            ? 'Perlu Revisi'
            : (currentStatus == ApplicationStatus.REJECTED
                ? 'Ditolak'
                : 'Persetujuan Admin'),
        'status': currentStatus,
      },
    ];

    int activeIndex = 0;
    if (currentStatus == ApplicationStatus.DRAFT) {
      activeIndex = 0;
    } else if (currentStatus == ApplicationStatus.SUBMITTED) {
      activeIndex = 1;
    } else {
      activeIndex = 2;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alur Pengajuan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: precheckPassed
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      precheckPassed
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 12,
                      color: precheckPassed
                          ? AppConstants.successColor
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      precheckPassed
                          ? 'Precheck: Lolos'
                          : 'Precheck: Belum Lolos',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: precheckPassed
                            ? AppConstants.successColor
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIndex = index ~/ 2;
                final isDone = lineIndex < activeIndex;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isDone ? AppConstants.primaryColor : Colors.grey.shade200,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCurrent = stepIndex == activeIndex;
              final isPassed = stepIndex < activeIndex;
              final step = steps[stepIndex];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? AppConstants.primaryColor
                          : (isCurrent
                              ? currentStatus.color
                              : Colors.grey.shade200),
                    ),
                    child: Center(
                      child: Icon(
                        isPassed
                            ? Icons.check
                            : (isCurrent
                                ? (step['status'] as ApplicationStatus).icon
                                : Icons.circle),
                        size: 14,
                        color: (isPassed || isCurrent)
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? currentStatus.color
                          : AppConstants.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

